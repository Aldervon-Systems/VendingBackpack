# frozen_string_literal: true

module Api
  class AuthController < ApplicationController
    before_action :require_auth!, only: %i[me update_whitelist add_machine]
    before_action :require_manager!, only: %i[update_whitelist add_machine]
    before_action only: %i[update_whitelist add_machine] do
      require_org_match!(params[:organization_id])
    end

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
          access_token: issue_access_token(user),
          token_type: "bearer",
          user: {
            name: user["name"],
            email: user["email"],
            role: user["role"],
            id: user["id"],
            organization_id: user["organization_id"]
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
        org_id = params[:organization_id].to_s.presence || JSON.parse(request.raw_post.presence || "{}")["organization_id"].to_s

        if Fixtures::MockApi.new.find_user(email)
          render json: { detail: "User already exists" }, status: :bad_request
          return
        end

        # Multi-Tenant Whitelist Check
        if org_id.present?
          unless Fixtures::MockApi.new.is_whitelisted?(org_id, email)
            render json: { detail: "Email not authorized for this organization" }, status: :forbidden
            return
          end
        end

        user = {
          "id" => "user_#{Time.now.to_i}",
          "name" => name,
          "email" => email,
          "password" => password,
          "role" => role,
          "organization_id" => org_id
        }

        Fixtures::MutableStore.add_user(user)

        if role.to_s.downcase == "employee" && !Employee.exists?(id: user["id"])
          Employee.create!(
            id: user["id"],
            name: name.presence || email.split("@").first.to_s.humanize,
            color: 0xFF4A5568,
            is_active: true
          )
        end

        render json: {
          access_token: issue_access_token(user),
          token_type: "bearer",
          user: {
            name: user["name"],
            email: user["email"],
            role: user["role"],
            id: user["id"],
            organization_id: user["organization_id"]
          }
        }, status: :created
      rescue => e
        Rails.logger.error "Signup Error: #{e.message}"
        render json: { detail: "Internal Server Error: #{e.message}" }, status: :internal_server_error
      end
    end

    def search_organizations
      query = params[:q].to_s
      orgs = Fixtures::MockApi.new.search_organizations(query)
      render json: orgs.map { |o| { id: o["id"], name: o["name"] } }
    end

    def me
      user = current_user
      render json: {
        user: {
          name: user["name"],
          email: user["email"],
          role: user["role"],
          id: user["id"],
          organization_id: user["organization_id"]
        }
      }
    end

    def create_organization
      begin
        # Role Validation (Manager only)
        # We use a robust extraction to ensure JSON bodies are parsed correctly
        raw_payload = JSON.parse(request.raw_post.presence || "{}")
        email = params[:manager_email].to_s.presence || raw_payload["manager_email"].to_s
        password = params[:manager_password].to_s.presence || raw_payload["manager_password"].to_s
        
        user = Fixtures::MockApi.new.find_user(email)
        unless user && user["role"] == "manager" && user["password"] == password
          render json: { detail: "Unauthorized: Manager credentials required" }, status: :unauthorized
          return
        end

        org_name = params[:name].to_s.presence || raw_payload["name"].to_s
        admin_password = params[:admin_password].to_s.presence || raw_payload["admin_password"].to_s
        whitelist = (params[:whitelist] || raw_payload["whitelist"]) || []

        totp_seed = ROTP::Base32.random
        org_id = "org_#{SecureRandom.hex(4)}"

        org_data = {
          "id" => org_id,
          "name" => org_name,
          "admin_password" => admin_password,
          "totp_seed" => totp_seed,
          "manager_id" => user["id"]
        }

        Fixtures::MutableStore.add_organization(org_data)
        Fixtures::MutableStore.update_whitelist(org_id, whitelist)

        # Link manager to org
        user["organization_id"] = org_id
        Fixtures::MutableStore.update_user(user)

        render json: {
          organization_id: org_id,
          totp_seed: totp_seed,
          totp_uri: ROTP::TOTP.new(totp_seed, issuer: "VendingBackpack").provisioning_uri(user["email"])
        }
      rescue => e
        render json: { detail: e.message }, status: :internal_server_error
      end
    end

    def verify_admin
      begin
        org_id = params[:organization_id].to_s
        admin_password = params[:admin_password].to_s
        totp_code = params[:totp_code].to_s

        org = Fixtures::MockApi.new.find_organization(org_id)
        unless org
          render json: { detail: "Organization not found" }, status: :not_found
          return
        end

        # Dual-Key Challenge
        password_ok = org["admin_password"] == admin_password
        totp = ROTP::TOTP.new(org["totp_seed"])
        totp_ok = totp.verify(totp_code, drift_behind: 30)

        if password_ok && totp_ok
          render json: { verified: true }
        else
          reasons = []
          reasons << "Invalid admin password" unless password_ok
          reasons << "Invalid TOTP code" unless totp_ok
          render json: { verified: false, detail: reasons.join(", ") }, status: :unauthorized
        end
      rescue => e
        render json: { detail: e.message }, status: :internal_server_error
      end
    end
    def update_whitelist
      begin
        org_id = params[:organization_id].to_s
        emails = params[:emails] || []
        
        Fixtures::MutableStore.update_whitelist(org_id, emails)
        render json: { success: true, emails: emails }
      rescue => e
        render json: { detail: e.message }, status: :internal_server_error
      end
    end

    def add_machine
      begin
        org_id = params[:organization_id].to_s
        vin = params[:vin].to_s
        name = params[:name].to_s
        lat = params[:lat].to_f
        lng = params[:lng].to_f
        
        machine = Machine.create!(
          id: Time.now.to_i.to_s,
          name: name,
          vin: vin.presence,
          organization_id: org_id.presence,
          status: "online",
          battery: 100,
          lat: lat,
          lng: lng,
          location: "Registered at Base"
        )

        render json: {
          id: machine.id,
          name: machine.name,
          vin: machine.vin,
          organization_id: machine.organization_id,
          status: machine.status,
          battery: machine.battery,
          lat: machine.lat,
          lng: machine.lng,
          location: machine.location
        }
      rescue => e
        render json: { detail: e.message }, status: :internal_server_error
      end
    end

    private

    def issue_access_token(user)
      payload = {
        "sub" => user["id"].to_s,
        "role" => user["role"].to_s,
        "organization_id" => user["organization_id"].to_s,
        "exp" => Time.now.to_i + 12 * 60 * 60
      }
      Rails.application.message_verifier(:access_token).generate(payload)
    end
  end
end
