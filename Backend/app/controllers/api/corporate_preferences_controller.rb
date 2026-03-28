# frozen_string_literal: true

module Api
  class CorporatePreferencesController < Api::BaseController
    before_action :require_manager!

    def show
      render json: preference_service.load(user_id: current_user.fetch("id"))
    end

    def update
      render json: preference_service.save(
        user_id: current_user.fetch("id"),
        payload: preference_payload,
      )
    end

    private

    def preference_service
      @preference_service ||= UserPreferences::CorporateViewService.new
    end

    def preference_payload
      params.to_unsafe_h.except("controller", "action")
    end
  end
end
