# frozen_string_literal: true

require "json"

class PublicApiRateLimiter
  WINDOW_SECONDS = 60
  LIMITS = {
    %r{\A/api/token\z} => 20,
    %r{\A/api/signup\z} => 10,
    %r{\A/api/organizations/create\z} => 5,
    %r{\A/api/organizations/verify_admin\z} => 10,
    %r{\A/api/organizations/search\z} => 30
  }.freeze

  def initialize(app)
    @app = app
    @buckets = Hash.new { |hash, key| hash[key] = [] }
    @mutex = Mutex.new
  end

  def call(env)
    request = Rack::Request.new(env)
    limit = limit_for(request.path)
    return @app.call(env) unless limit

    key = "#{request.ip}:#{request.path}"
    now = Time.now.to_i
    allowed = @mutex.synchronize do
      bucket = @buckets[key]
      bucket.reject! { |timestamp| timestamp <= now - WINDOW_SECONDS }
      if bucket.length >= limit
        false
      else
        bucket << now
        true
      end
    end

    return @app.call(env) if allowed

    [
      429,
      { "Content-Type" => "application/json" },
      [{ detail: "Rate limit exceeded" }.to_json]
    ]
  end

  private

  def limit_for(path)
    LIMITS.find { |pattern, _limit| pattern.match?(path) }&.last
  end
end

Rails.application.config.middleware.insert_before 0, PublicApiRateLimiter
