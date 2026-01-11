# frozen_string_literal: true

module Api
  class AuthController < ApplicationController
    def token
      payload = JSON.parse(request.raw_post.presence || "{}")
      email = payload["email"].to_s
      password = payload["password"].to_s

      user = Fixtures::MockApi.new.find_user(email)
      stored_password = user && user["password"].to_s
      provided_password = password.to_s
      unless stored_password &&
             stored_password.bytesize == provided_password.bytesize &&
             ActiveSupport::SecurityUtils.secure_compare(stored_password, provided_password)
        render json: { detail: "Invalid credentials" }, status: :unauthorized
        return
      end

      render json: {
        access_token: "mock_token_#{user["id"]}",
        token_type: "bearer",
        user: {
          name: user["name"],
          email: user["email"],
          role: user["role"],
          id: user["id"]
        }
      }
    end
  end
end
