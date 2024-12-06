class ScienceController < ApplicationController
  before_action :verify_bio_savant

  def index
  end

  def science
    # Vous pouvez initialiser des variables nécessaires ici
  end

  def list
    @ingredients = InventoryObject.where(category: 'ingredient').where(rarity: ['Commun', 'Unco'])
  end

  def buy_inventory_object
    inventory_object = InventoryObject.find(params[:inventory_object_id])
    user_inventory_object = current_user.user_inventory_objects.find_or_initialize_by(inventory_object: inventory_object)

    if current_user.credits >= inventory_object.price
      current_user.credits -= inventory_object.price
      user_inventory_object.quantity ||= 0
      user_inventory_object.quantity += 1

      ActiveRecord::Base.transaction do
        current_user.save!
        user_inventory_object.save!
      end

      render json: { new_quantity: user_inventory_object.quantity }, status: :ok
    else
      render json: { error: "Crédits insuffisants" }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Utilisateur ou objet introuvable" }, status: :not_found
  end

  private

  def verify_bio_savant
    unless current_user.classe_perso.name == "Bio-savant"
      redirect_to root_path, alert: "Accès réservé aux Bio-savants."
    end
  end
end