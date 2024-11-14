# app/controllers/user_skills_controller.rb
class UserSkillsController < ApplicationController
  before_action :set_user
  before_action :authenticate_user!
  before_action :authorize_user_or_mj, only: [:update, :create]

  def index
    @skills = Skill.all
    @user_skills = @user.user_skills.includes(:skill)
  end

  def create
    @user_skill = @user.user_skills.new(user_skill_params)
    if @user_skill.save
      redirect_to user_user_skills_path(@user), notice: "Compétence ajoutée avec succès."
    else
      render :index, alert: "Erreur lors de l'ajout de la compétence."
    end
  end

  def update
    @user_skill = @user.user_skills.find(params[:id])
    if @user_skill.update(user_skill_params)
      redirect_to user_user_skills_path(@user), notice: "Niveau de maîtrise mis à jour."
    else
      render :index
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def user_skill_params
    params.require(:user_skill).permit(:skill_id, :mastery, :bonus)
  end

  def authorize_user_or_mj
    unless current_user == @user || current_user.group.name == "MJ"
      redirect_to root_path, alert: "Vous n'avez pas la permission de modifier cette compétence."
    end
  end
end