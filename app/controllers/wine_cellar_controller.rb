class WineCellarController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_mercenary

  def index
    @drinks_data = YAML.load_file(Rails.root.join('config/catalogs/drinks.yml'))['drinks']
    @discovered_drinks = current_user.discovered_drinks || []
    @user_drinks = current_user.user_inventory_objects
                                .joins(:inventory_object)
                                .where(inventory_objects: { category: 'drinks' })
                                .includes(:inventory_object)
  end

  def add_bottle
    catalog_id = params[:drink_id]
    quantity = params[:quantity].to_i

    return render json: { error: "Paramètres manquants" }, status: :unprocessable_entity if catalog_id.blank?
    return render json: { error: "Quantité invalide" }, status: :unprocessable_entity if quantity <= 0

    # Cherche directement par catalog_id dans la base de données
    inventory_object = InventoryObject.find_by(catalog_id: catalog_id, category: 'drinks')
    return render json: { error: "Alcool introuvable" }, status: :not_found unless inventory_object

    user_inventory_object = current_user.user_inventory_objects.find_or_initialize_by(inventory_object: inventory_object)
    user_inventory_object.quantity ||= 0
    user_inventory_object.quantity += quantity
    user_inventory_object.save!

    render json: { success: true, new_quantity: user_inventory_object.quantity }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def remove_bottle
    catalog_id = params[:drink_id]
    quantity = params[:quantity].to_i

    return render json: { error: "Paramètres manquants" }, status: :unprocessable_entity if catalog_id.blank?
    return render json: { error: "Quantité invalide" }, status: :unprocessable_entity if quantity <= 0

    # Cherche directement par catalog_id dans la base de données
    inventory_object = InventoryObject.find_by(catalog_id: catalog_id, category: 'drinks')
    return render json: { error: "Alcool introuvable" }, status: :not_found unless inventory_object

    user_inventory_object = current_user.user_inventory_objects.find_by(inventory_object: inventory_object)
    return render json: { error: "Vous ne possédez pas cet alcool" }, status: :not_found unless user_inventory_object

    if user_inventory_object.quantity <= quantity
      user_inventory_object.destroy
      render json: { success: true, new_quantity: 0, deleted: true }
    else
      user_inventory_object.quantity -= quantity
      user_inventory_object.save!
      render json: { success: true, new_quantity: user_inventory_object.quantity }
    end
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def verify_mercenary
    unless current_user.classe_perso&.name == "Mercenaire"
      redirect_to root_path, alert: "Accès réservé aux Mercenaires."
    end
  end
end

