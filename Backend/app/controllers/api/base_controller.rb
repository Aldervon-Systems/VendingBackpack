# frozen_string_literal: true

module Api
  class BaseController < ApplicationController
    before_action :require_auth!
    before_action :require_current_organization!
  end
end
