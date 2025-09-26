module Pazaak
  class StatsController < ApplicationController
    before_action :authenticate_user!

    def show
      @stats = current_user.pazaak_stat || current_user.build_pazaak_stat
    end
  end
end


