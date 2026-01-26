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
    def signup
      payload = JSON.parse(request.raw_post.presence || "{}")
      email = payload["email"].to_s
      password = payload["password"].to_s
      name = payload["name"].to_s
      role = payload["role"].to_s.presence || "employee"

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
    end
  end
end
