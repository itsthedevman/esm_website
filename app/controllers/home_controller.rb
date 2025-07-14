# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    flash[:info] = "Hello!"
    flash[:success] = "Hello!"
    flash[:warn] = "Hello!"
    flash[:error] = "Hello!"
    command_count = ESM::CommandDetail.all.size
    render locals: {command_count:}
  end
end
