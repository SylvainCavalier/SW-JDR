class HolonewsController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.group == 'MJ' || current_user.group == 'PNJ'
      @holonews = Holonew.includes(:sender).order(created_at: :desc).page(params[:page]).per(10)
    else
      @holonews = Holonew.includes(:sender)
                          .where("target_group = ? OR target_user = ? OR target_group = ?", 
                                 current_user.group.to_s, current_user.id, 'all')
                          .order(created_at: :desc)
                          .page(params[:page]).per(10)
    end
    
    unless params[:page]
      current_user.mark_holonews_as_read(@holonews)
    end

    respond_to do |format|
      format.html
    end
  end

  def new
    @holonew = Holonew.new
    @users = User.all
    @groups = Group.all
  end

  def create
    @holonew = Holonew.new(holonew_params)
    @holonew.sender = current_user
  
    if params[:send_to_all] == '1'
      @holonew.target_user = nil
      @holonew.target_group = 'all'
    elsif params[:target_user].present?
      @holonew.target_user = params[:target_user].to_i
    elsif params[:target_group].present?
      @holonew.target_group = params[:target_group]
    end
  
    if @holonew.save
      respond_to do |format|
        format.html { redirect_to new_holonew_path, notice: "Holonew envoyée" }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private

  def holonew_params
    params.require(:holonew).permit(:title, :content).merge(user_id: current_user.id)
  end
end
