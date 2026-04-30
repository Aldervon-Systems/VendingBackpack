class ApplicationController < ActionController::API
  private

  def require_auth!
    return if current_user

    render json: { detail: "Unauthorized" }, status: :unauthorized
  end

  def require_manager!
    return if current_user && current_user["role"].to_s.downcase == "manager"

    render json: { detail: "Forbidden" }, status: :forbidden
  end

  def require_platform_admin!
    return if current_user && current_user["role"].to_s.downcase == "platform_admin"

    render json: { detail: "Forbidden" }, status: :forbidden
  end

  def require_current_organization!
    return if current_organization

    render json: { detail: "Organization not found" }, status: :not_found
  end

  def require_org_match!(org_id = params[:organization_id])
    return if current_user && current_user["organization_id"].to_s == org_id.to_s

    render json: { detail: "Forbidden" }, status: :forbidden
  end

  def require_self_or_manager!(target_user_id = params[:id])
    return if current_user && (
      current_user["role"].to_s.downcase == "manager" ||
      current_user["id"].to_s == target_user_id.to_s
    )

    render json: { detail: "Forbidden" }, status: :forbidden
  end

  def ensure_employee_parity!
    return unless current_user
    return unless current_user["role"].to_s.downcase == "employee"
    return if current_organization&.employees&.exists?(id: current_user["id"].to_s)

    render json: { detail: "Forbidden" }, status: :forbidden
  end

  def not_found!
    render json: { detail: "Not found" }, status: :not_found
  end

  def current_organization
    return @current_organization if defined?(@current_organization)

    org_id = current_user&.dig("organization_id").to_s
    @current_organization = org_id.present? ? Organization.find_by(id: org_id) : nil
  end

  def current_user
    return @current_user if defined?(@current_user)

    token = bearer_token
    payload = decode_access_token(token)
    user = payload ? User.includes(:organization).find_by(id: payload["sub"].to_s) : nil
    @current_user = user&.auth_payload
  end

  def bearer_token
    authorization = request.headers["Authorization"].to_s
    return nil unless authorization.start_with?("Bearer ")

    authorization.delete_prefix("Bearer ").strip
  end

  def decode_access_token(token)
    return nil if token.blank?

    payload = token_verifier.verify(token)
    return nil unless payload.is_a?(Hash)
    return nil if payload["sub"].to_s.empty?
    return nil if payload["exp"].to_i <= Time.now.to_i

    payload
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ArgumentError
    nil
  end

  def token_verifier
    Rails.application.message_verifier(:access_token)
  end
end
