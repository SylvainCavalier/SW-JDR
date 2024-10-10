class HolonewsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user, only: [:new, :create]

  def index
    if current_user.group == 'MJ' || current_user.group == 'PNJ'
      @holonews = Holonew.all
    else
      @holonews = Holonew.where("target_group = ? OR target_user = ? OR target_group = ?", current_user.group.to_s, current_user.id, 'all')
    end
  end

  def new
    @holonew = Holonew.new
    @users = User.all
    @groups = Group.all
  end

  def create
    @holonew = Holonew.new(holonew_params)
    @holonew.user = current_user

    if params[:send_to_all] == '1'
      @holonew.target_user = nil
      @holonew.target_group = 'all'
    elsif params[:target_user].present?
      @holonew.target_user = params[:target_user]
    elsif params[:target_group].present?
      @holonew.target_group = params[:target_group]
    end

    if @holonew.save
      redirect_to holonews_path, notice: "Holonew envoyée"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def holonew_params
    params.require(:holonew).permit(:title, :content).merge(user_id: current_user.id)
  end

  def authorize_user
    unless current_user.group.name.in?(['MJ', 'PNJ'])
      redirect_to holonews_path, alert: "Accès interdit"
    end
  end
end
