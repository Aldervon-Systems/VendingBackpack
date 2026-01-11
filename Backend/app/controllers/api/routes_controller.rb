# frozen_string_literal: true

module Api
  class RoutesController < ApplicationController
    def routes
      render json: {
        locations: Fixtures::MockApi.new.locations,
        paths: []
      }
    end

    def employees
      render json: Fixtures::MockApi.new.employees
    end
  end
end
