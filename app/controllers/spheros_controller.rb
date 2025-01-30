class SpherosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_sphero, only: [:activate, :deactivate, :destroy, :transfer]

  def activate
    current_user.spheros.update_all(active: false)
    @sphero.update(active: true)

    flash[:notice] = "Sphéro-Droïde activé avec succès."
    head :no_content
  end

  def deactivate
    @sphero.update(active: false)

    flash[:notice] = "Sphéro-Droïde désactivé avec succès."
    head :no_content
  end

  def destroy
    @sphero.destroy

    flash[:notice] = "Sphéro-Droïde supprimé avec succès."
    head :no_content
  end

  def transfer
    new_owner = User.find(params[:player_id])
    @sphero.update(user: new_owner, active: false)

    flash[:notice] = "Sphéro-Droïde transféré à #{new_owner.username}."
    head :no_content
  end

  def repair
    unless current_user.user_skills.find_by(skill: Skill.find_by(name: "Réparation"))&.mastery.to_i >= 3
      flash[:alert] = "Vous avez besoin d'au moins 3D en Réparation pour réparer ce sphéro-droïde."
      return head :unprocessable_entity
    end
  
    @sphero = current_user.spheros.find(params[:id])
    missing_hp = @sphero.hp_max - @sphero.hp_current
    required_components = (missing_hp / 5.0).ceil
  
    components = current_user.user_inventory_objects.find_by(inventory_object: InventoryObject.find_by(name: "Composant"))
  
    if components.nil? || components.quantity < required_components
      flash[:alert] = "Vous n'avez pas assez de composants pour cette réparation."
      return head :unprocessable_entity
    end
  
    components.update(quantity: components.quantity - required_components)
    @sphero.update(hp_current: @sphero.hp_max)
  
    flash[:notice] = "Votre sphéro-droïde a été réparé !"
    head :no_content
  end
  
  def repair_kit
    @sphero = current_user.spheros.find(params[:id])
    kit = current_user.user_inventory_objects.find_by(inventory_object: InventoryObject.find_by(name: "Kit de réparation"))
  
    if kit.nil? || kit.quantity <= 0
      flash[:alert] = "Vous n'avez pas de Kit de réparation."
      return head :unprocessable_entity
    end
  
    kit.update(quantity: kit.quantity - 1)
    @sphero.update(hp_current: @sphero.hp_max)
  
    flash[:notice] = "Votre sphéro-droïde a été entièrement réparé grâce au Kit de réparation !"
    head :no_content
  end

  def recharge
    @sphero = current_user.spheros.find(params[:id])
    recharge_cost = (@sphero.shield_max - @sphero.shield_current) * 10
  
    if current_user.credits < recharge_cost
      flash[:alert] = "Pas assez de crédits pour recharger le bouclier !"
      head :unprocessable_entity
    else
      current_user.update(credits: current_user.credits - recharge_cost)
      @sphero.update(shield_current: @sphero.shield_max)
  
      flash[:notice] = "Bouclier rechargé avec succès !"
      head :no_content
    end
  end

  def add_medipack
    sphero = current_user.spheros.find(params[:id])
    medipack = current_user.user_inventory_objects.find_by(inventory_object: InventoryObject.find_by(name: "Medipack"))
  
    if medipack && medipack.quantity > 0
      sphero.medipacks += 1
      medipack.quantity -= 1
  
      if sphero.save && medipack.save
        message = "Medipack ajouté au sphéro-droïde."
        render json: { success: true, new_medipack_count: sphero.medipacks, message: message }
      else
        error = sphero.errors.full_messages.join(", ")
        render json: { success: false, error: error }, status: :unprocessable_entity
      end
    else
      error = "Vous n'avez pas de medipacks en stock."
      render json: { success: false, error: error }, status: :unprocessable_entity
    end
  end

  def use_medipack
    sphero = current_user.spheros.find(params[:id])
    target_user = User.find(params[:player_id])
  
    if sphero.medipacks <= 0
      flash[:alert] = "Ce sphéro-droïde n'a plus de medipacks."
      return head :unprocessable_entity
    end
  
    # Jet de soins avec la compétence Médecine du sphéro
  medicine_skill = sphero.sphero_skills.find_by(skill: Skill.find_by(name: "Médecine"))
  medicine_mastery = medicine_skill&.mastery.to_i
  medicine_bonus = medicine_skill&.bonus.to_i
  healing_amount = ((1..medicine_mastery).map { rand(1..6) }.sum + medicine_bonus) / 2.0
  healing_amount = healing_amount.ceil # ✅ Arrondi à l'entier supérieur

  # Application des soins (sans dépasser le max HP)
  new_hp = [target_user.hp_current + healing_amount, target_user.hp_max].min
  target_user.update!(hp_current: new_hp)

  # Consommation du medipack
  sphero.update!(medipacks: sphero.medipacks - 1)

  # ✅ Diffusion Turbo Stream pour mise à jour dynamique des HP
  target_user.broadcast_hp_update
  
    flash[:notice] = "#{target_user.username} a été soigné de #{healing_amount} PV par le sphéro-droïde."
    head :no_content
  end

  def protect
    @sphero = current_user.spheros.find(params[:id])
    skill = @sphero.sphero_skills.find_by(skill: Skill.find_by(name: "Habileté"))
  
    if skill.nil?
      message = "Ce sphéro-droïde ne possède pas la compétence Habileté."
      return render json: { success: false, message: message }, status: :unprocessable_entity
    end
  
    protection_value = (1..skill.mastery).map { rand(1..6) }.sum + skill.bonus
    message = "Jet de protection : #{protection_value}"
  
    render json: { success: true, message: message }
  end
  
  def attack
    @sphero = current_user.spheros.find(params[:id])
    skill = @sphero.sphero_skills.find_by(skill: Skill.find_by(name: "Tir"))
  
    if skill.nil?
      message = "Ce sphéro-droïde ne possède pas la compétence Tir."
      return render json: { success: false, message: message }, status: :unprocessable_entity
    end
  
    attack_value = (1..skill.mastery).map { rand(1..6) }.sum + skill.bonus
    message = "Jet d'attaque : #{attack_value}"
  
    render json: { success: true, message: message }
  end

  private

  def set_sphero
    @sphero = current_user.spheros.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Sphéro-Droïde introuvable."
    head :unprocessable_entity
  end
end