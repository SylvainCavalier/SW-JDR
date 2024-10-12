class UsersController < ApplicationController
  before_action :authenticate_user!

  def toggle_shield
    current_user.update(shield_state: !current_user.shield_state)
    respond_to do |format|
      format.json { render json: { shield_state: current_user.shield_state } }
    end
  end
end
