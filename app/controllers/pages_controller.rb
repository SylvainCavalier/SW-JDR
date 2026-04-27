class PagesController < ApplicationController
  before_action :authenticate_user!

  def home
    @patch_equipped = current_user.equipped_patch.present?
    @active_injection_object = current_user.active_injection_object
    @unread_holonews_count = current_user.holonew_reads.where(read: false).count
    @headquarter = Headquarter.first
  end

  def team
    @team_group = Group.find_by(name: "PJ")
    @players = User.includes(:race, :classe_perso, :pet, :statuses, :avatar_attachment)
                   .joins(:group).where(groups: { name: "PJ" })
                   .order(:username)
  end

  def update_team_image
    unless current_user.group&.name == "MJ"
      redirect_to team_path, alert: "Action réservée au MJ." and return
    end

    team_group = Group.find_by(name: "PJ")
    if team_group&.update(image: params[:image])
      redirect_to team_path, notice: "Image d'équipe mise à jour."
    else
      redirect_to team_path, alert: "Erreur lors de l'upload."
    end
  end

  def mj
  end

  def rules
    file_path = Rails.root.join("app", "views", "pages", "rules.md")
    @rules_content = File.read(file_path).then { |content| Kramdown::Document.new(content).to_html }
  end
end
