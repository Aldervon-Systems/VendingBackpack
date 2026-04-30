# frozen_string_literal: true

require "time"

module Api
  class CorporateController < Api::BaseController
    before_action :require_manager!

    def show
      org_id = current_user&.dig("organization_id").to_s

      if org_id.blank?
        render json: { detail: "No organization linked to session" }, status: :unprocessable_entity
        return
      end

      snapshot = SeedCorporateSnapshots.fetch(org_id)

      unless snapshot.is_a?(Hash)
        render json: { detail: "Corporate snapshot not found" }, status: :not_found
        return
      end

      organization = Organization.find_by(id: org_id)
      meta = snapshot.fetch("meta", {})

      render json: snapshot.merge(
        "meta" => {
          "organizationName" => organization&.name || meta["organizationName"] || "Organization",
          "generatedAt" => Time.now.utc.iso8601,
          "reportingPeriod" => meta["reportingPeriod"].to_s,
          "machineCount" => meta["machineCount"].to_i,
        },
      )
    end
  end
end
