class PagesController < ApplicationController
  before_action :authenticate_user!

  def home
    @patch_equipped = current_user.equipped_patch.present?
  end

  def mj
  end
end
