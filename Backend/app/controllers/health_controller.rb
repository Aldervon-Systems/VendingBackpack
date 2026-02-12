# frozen_string_literal: true

class HealthController < ApplicationController
  def show
    render json: { status: "ok", version: "2.5" }
  end
end
