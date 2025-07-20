# frozen_string_literal: true

class CommunitiesController < ApplicationController
  def index
    @community = ESM::Community.all.first
    render locals: {}
  end
end
