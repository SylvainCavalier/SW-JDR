class MjController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_mj

  def infliger_degats
    @users = User.where(group_id: Group.find_by(name: "PJ").id)
  end

  def apply_damage
    user = User.find(damage_params[:user_id])
    damage = damage_params[:damage].to_i

    if user.shield_state && user.shield_current > 0
      new_shield_value = [user.shield_current - damage, 0].max
      user.update(shield_current: new_shield_value)
      message = "Bouclier a pris #{damage} dégâts."
    else
      new_hp_value = [user.hp_current - damage, 0].max
      user.update(hp_current: new_hp_value)
      message = "Le joueur a pris #{damage} dégâts."
    end

    respond_to do |format|
      format.json { render json: { success: true, hp_current: user.hp_current, shield_current: user.shield_current, message: message } }
    end
  end

  def fixer_pv_max
    @users = User.where(group_id: Group.find_by(name: "PJ").id)
  end

  def update_pv_max
    user_ids = (update_params[:pv_max]&.keys || []) +
               (update_params[:shield_max]&.keys || []) +
               (update_params[:echani_shield_max]&.keys || [])
    users = User.where(id: user_ids.uniq)
    users_by_id = users.index_by(&:id)
  
    update_params[:pv_max]&.each do |user_id, hp_max_value|
      user = users_by_id[user_id.to_i]
      if user&.update(hp_max: hp_max_value.to_i)
        user.broadcast_hp_update
        Rails.logger.debug "Updated HP Max for user ##{user.id} to #{user.hp_max}"
      end
    end
  
    update_params[:shield_max]&.each do |user_id, shield_max_value|
      user = users_by_id[user_id.to_i]
      if user&.update(shield_max: shield_max_value.to_i)
        user.broadcast_energy_shield_update
        Rails.logger.debug "Updated Shield Max for user ##{user.id} to #{user.shield_max}"
      end
    end
  
    update_params[:echani_shield_max]&.each do |user_id, echani_shield_max_value|
      user = users_by_id[user_id.to_i]
      if user&.update(echani_shield_max: echani_shield_max_value.to_i)
        user.broadcast_echani_shield_update
        Rails.logger.debug "Updated Echani Shield Max for user ##{user.id} to #{user.echani_shield_max}"
      end
    end
  
    redirect_to fixer_pv_max_path, notice: "PV Max et Boucliers mis à jour dynamiquement"
  end

  def donner_xp
    @players = User.where(group: Group.find_by(name: "PJ"))
  end

  def attribution_xp
    xp_to_add = xp_params[:xp].to_i
    give_to_all = xp_params[:give_to_all] == "true"
    user_id = xp_params[:user_id]
    xp_updates = []
  
    if give_to_all
      User.where(group: Group.find_by(name: "PJ")).each do |user|
        user.apply_xp_bonus(xp_to_add)
        xp_updates << { id: user.id, xp: user.xp }
      end
    elsif user_id.present?
      user = User.find(user_id)
      user.apply_xp_bonus(xp_to_add)
      xp_updates << { id: user.id, xp: user.xp }
    end

    xp_updates.each do |update|
      user = User.find(update[:id])
      user.broadcast_replace_to(
        "xp_updates_#{user.id}",
        target: "user_#{user.id}_xp_frame",
        partial: "pages/xp_update",
        locals: { user: user }
      )
    end
  
    respond_to do |format|
      format.turbo_stream { head :ok }
      format.html { redirect_to donner_xp_path, notice: "XP mis à jour !" }
    end
  end

  def fixer_statut
    @users = User.where(group: Group.find_by(name: "PJ"))
    @statuses = Status.all
  end

  def update_statut
    params[:status].each do |user_id, status_id|
      user = User.find(user_id)
      new_status = Status.find(status_id)
  
      # Gestion des patchs automatiques
      if user.patch.present?
        equipped_patch = user.equipped_patch
  
        if equipped_patch.name == "Stimpatch" && new_status.name == "Sonné"
          use_patch_automatically(user, "Sonné")
          next
        elsif equipped_patch.name == "Poisipatch" && new_status.name == "Empoisonné"
          use_patch_automatically(user, "Empoisonné")
          next
        end
      end
  
      # Appliquer le statut normalement
      user.statuses = [new_status]
      user.broadcast_status_update
    end
  
    redirect_to fixer_statut_path, notice: "Statuts mis à jour avec succès."
  end

  def donner_objet
    @users = User.joins(:group).where(groups: { name: "PJ" })
    @objects = InventoryObject.order(:name)
  end

  def update_objet
    params[:object].each do |user_id, object_id|
      user = User.find(user_id)
      object = InventoryObject.find(object_id)

      user_inventory_object = user.user_inventory_objects.find_or_initialize_by(inventory_object_id: object.id)
      user_inventory_object.quantity ||= 0
      user_inventory_object.quantity += 1
      user_inventory_object.save!

      Rails.logger.info "✅ Objet #{object.name} donné à #{user.username}."
    end

    redirect_to donner_objet_path, notice: "Objets donnés avec succès."
  rescue ActiveRecord::RecordNotFound => e
    redirect_to donner_objet_path, alert: "Erreur : #{e.message}"
  end
  
  private
  
  def xp_params
    params.require(:xp).permit(:xp, :user_id, :give_to_all)
  end

  def authorize_mj
    unless current_user.group.name == "MJ"
      redirect_to root_path, alert: "Accès refusé."
    end
  end

  def damage_params
    params.permit(:user_id, :damage, :authenticity_token)
  end

  def update_params
    params.except(:authenticity_token, :commit).permit(
      pv_max: {},
      shield_max: {},
      echani_shield_max: {}
    ).to_h
  end

  def use_patch_automatically(user, status_name)
    equipped_patch = user.equipped_patch
    inventory_object = user.user_inventory_objects.find_by(inventory_object_id: equipped_patch.id)
  
    ActiveRecord::Base.transaction do
      # Réduire la quantité du patch et déséquiper
      inventory_object.decrement!(:quantity) if inventory_object.present?
      user.update!(patch: nil)
  
      # Remettre le statut à "En forme"
      user.set_status("En forme")
    end
  
    # Notification Turbo Streams
    user.broadcast_replace_to(
      "notifications_#{user.id}",
      target: "notification_frame",
      partial: "pages/notification",
      locals: { message: "PATCH UTILISÉ : #{equipped_patch.name} activé automatiquement !" }
    )
  
    Rails.logger.info "✔️ Patch automatique activé : #{equipped_patch.name} pour #{user.username}, statut '#{status_name}' annulé."
  end
end
