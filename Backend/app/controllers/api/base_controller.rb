# frozen_string_literal: true

module Api
  class BaseController < ApplicationController
    before_action :require_auth!
  end
end
