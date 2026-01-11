# frozen_string_literal: true

module Api
  class MachinesController < ApplicationController
    def index
      render json: machines
    end

    def show
      machine = machines.find { |m| m["id"].to_i == params[:id].to_i }
      if machine
        render json: machine
      else
        render json: { detail: "Machine not found" }, status: :not_found
      end
    end

    private

    def machines
      Fixtures::MutableStore.machines
    end
  end
end
