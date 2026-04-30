# frozen_string_literal: true

module Api
  class AuthController < ApplicationController
    before_action :require_auth!, only: %i[me create_organization verify_admin update_whitelist add_machine]
    before_action :require_platform_admin!, only: %i[create_organization]
    before_action :require_manager!, only: %i[update_whitelist add_machine]
    before_action only: %i[verify_admin update_whitelist add_machine] do
      require_org_match!(params[:organization_id])
    end

    def token
      email = payload_value("email").to_s.downcase
      password = payload_value("password").to_s
      user = User.includes(:organization).find_by(email: email)

      unless user&.authenticate(password)
        render json: { detail: "Invalid credentials" }, status: :unauthorized
        return
      end

      render_auth_response(user)
    end

    def signup
      email = payload_value("email").to_s.downcase
      password = payload_value("password").to_s
      name = payload_value("name").to_s
      role = "employee"
      org_id = payload_value("organization_id").to_s

      if User.exists?(email: email)
        render json: { detail: "User already exists" }, status: :bad_request
        return
      end

      if org_id.present?
        organization = Organization.find_by(id: org_id)
        unless organization
          render json: { detail: "Organization not found" }, status: :not_found
          return
        end

        unless organization.organization_whitelist_entries.exists?(email: email)
          render json: { detail: "Email not authorized for this organization" }, status: :forbidden
          return
        end
      end

      user = User.create!(
        id: generated_user_id(role),
        name: name,
        email: email,
        password: password,
        password_confirmation: password,
        role: role,
        organization_id: org_id.presence
      )

      if user.role == "employee" && !Employee.exists?(id: user.id)
        Employee.create!(
          id: user.id,
          name: user.name.presence || user.email.split("@").first.to_s.humanize,
          color: 0xFF4A5568,
          organization_id: org_id.presence,
          is_active: true
        )
      end

      render_auth_response(user, status: :created)
    rescue ActiveRecord::RecordInvalid => e
      render json: { detail: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end

    def search_organizations
      query = params[:q].to_s
      organizations = if query.blank?
        Organization.none
      else
        Organization.where("LOWER(name) = ?", query.downcase.strip).order(:name).limit(1)
      end

      render json: organizations.map { |organization| { id: organization.id, name: organization.name } }
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
      org_name = payload_value("name").to_s
      admin_password = payload_value("admin_password").to_s
      whitelist = normalized_whitelist(payload_value("whitelist"))
      manager_email = payload_value("manager_email").to_s.downcase
      manager = manager_email.present? ? User.find_by(email: manager_email) : nil

      totp_seed = ROTP::Base32.random
      org_id = "org_#{SecureRandom.hex(4)}"

      Organization.transaction do
        organization = Organization.create!(
          id: org_id,
          name: org_name,
          admin_password: admin_password,
          admin_password_confirmation: admin_password,
          totp_seed: totp_seed,
          manager: manager&.role == "manager" ? manager : nil
        )

        whitelist.each do |email|
          organization.organization_whitelist_entries.create!(email: email)
        end

        manager&.update!(organization: organization) if manager&.role == "manager"
      end

      render json: {
        organization_id: org_id,
        totp_uri: ROTP::TOTP.new(totp_seed, issuer: "VendingBackpack").provisioning_uri(manager&.email || current_user["email"])
      }
    rescue ActiveRecord::RecordInvalid => e
      render json: { detail: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end

    def verify_admin
      org_id = params[:organization_id].to_s
      admin_password = params[:admin_password].to_s
      totp_code = params[:totp_code].to_s

      organization = Organization.find_by(id: org_id)
      unless organization
        render json: { detail: "Organization not found" }, status: :not_found
        return
      end

      password_ok = organization.authenticate_admin_password(admin_password)
      totp_ok = ROTP::TOTP.new(organization.totp_seed).verify(totp_code, drift_behind: 30)

      if password_ok && totp_ok
        render json: { verified: true }
      else
        Rails.logger.warn("[admin_verification] failed organization_id=#{org_id} user_id=#{current_user&.dig('id')}")
        render json: { verified: false, detail: "Invalid verification code or credentials" }, status: :unauthorized
      end
    end

    def update_whitelist
      organization = Organization.find_by(id: params[:organization_id].to_s)
      unless organization
        render json: { detail: "Organization not found" }, status: :not_found
        return
      end

      emails = normalized_whitelist(params[:emails])
      Organization.transaction do
        organization.organization_whitelist_entries.where.not(email: emails).delete_all
        existing_emails = organization.organization_whitelist_entries.pluck(:email)
        (emails - existing_emails).each do |email|
          organization.organization_whitelist_entries.create!(email: email)
        end
      end

      render json: { success: true, emails: organization.organization_whitelist_entries.order(:email).pluck(:email) }
    rescue ActiveRecord::RecordInvalid => e
      render json: { detail: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end

    def add_machine
      org_id = params[:organization_id].to_s
      vin = params[:vin].to_s
      name = params[:name].to_s
      lat = params[:lat].to_f
      lng = params[:lng].to_f

      unless Organization.exists?(id: org_id)
        render json: { detail: "Organization not found" }, status: :not_found
        return
      end

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
    rescue ActiveRecord::RecordInvalid => e
      render json: { detail: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
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

    def render_auth_response(user, status: :ok)
      render json: {
        access_token: issue_access_token(user),
        token_type: "bearer",
        user: {
          name: user.name,
          email: user.email,
          role: user.role,
          id: user.id,
          organization_id: user.organization_id
        }
      }, status: status
    end

    def raw_payload
      @raw_payload ||= JSON.parse(request.raw_post.presence || "{}")
    rescue JSON::ParserError
      {}
    end

    def payload_value(key)
      params[key].presence || raw_payload[key].presence
    end

    def generated_user_id(role)
      prefix = role.to_s.downcase == "manager" ? "mgr" : "user"
      "#{prefix}_#{SecureRandom.hex(4)}"
    end

    def normalized_whitelist(values)
      Array(values).filter_map do |value|
        email = value.to_s.strip.downcase
        email.presence
      end.uniq
    end
  end
end
