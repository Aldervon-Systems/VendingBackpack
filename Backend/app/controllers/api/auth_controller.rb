# frozen_string_literal: true

module Api
  class AuthController < ApplicationController
    def token
      begin
        email = params[:email].to_s.presence || JSON.parse(request.raw_post.presence || "{}")["email"].to_s
        password = params[:password].to_s.presence || JSON.parse(request.raw_post.presence || "{}")["password"].to_s

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
      rescue => e
        Rails.logger.error "Authentication Error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { detail: "Internal Server Error: #{e.message}" }, status: :internal_server_error
      end
    end
    def signup
      begin
        email = params[:email].to_s.presence || JSON.parse(request.raw_post.presence || "{}")["email"].to_s
        password = params[:password].to_s.presence || JSON.parse(request.raw_post.presence || "{}")["password"].to_s
        name = params[:name].to_s.presence || JSON.parse(request.raw_post.presence || "{}")["name"].to_s
        role = params[:role].to_s.presence || JSON.parse(request.raw_post.presence || "{}")["role"].to_s.presence || "employee"

        if Fixtures::MockApi.new.find_user(email)
          render json: { detail: "User already exists" }, status: :bad_request
          return
        end

        user = {
          "id" => "user_#{Time.now.to_i}",
          "name" => name,
          "email" => email,
          "password" => password,
          "role" => role
        }

        Fixtures::MutableStore.add_user(user)

        render json: {
          access_token: "mock_token_#{user["id"]}",
          token_type: "bearer",
          user: {
            name: user["name"],
            email: user["email"],
            role: user["role"],
            id: user["id"]
          }
        }, status: :created
      rescue => e
        Rails.logger.error "Signup Error: #{e.message}"
        render json: { detail: "Internal Server Error: #{e.message}" }, status: :internal_server_error
      end
    end
  end
end
