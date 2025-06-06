class ShipsController < ApplicationController
  before_action :set_ship, only: [:show, :edit, :update, :destroy, :set_active, :dock, :undock, :inventory]
  before_action :authenticate_user!

  def index
    @ships = current_user.group.ships
  end

  def show
    @skills = @ship.ships_skills.includes(:skill)
    @objects = @ship.ship_objects
    @child_ships = @ship.child_ships
  end

  def new
    @ship = Ship.new
  end

  def create
    @ship = Ship.new(ship_params)
    @ship.group = current_user.group
    if @ship.save
      update_ship_skills(@ship)
      update_ship_weapons(@ship)
      redirect_to @ship, notice: "Vaisseau créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @ship.update(ship_params)
      update_ship_skills(@ship)
      @ship.ship_weapons.destroy_all
      update_ship_weapons(@ship)
      redirect_to @ship, notice: "Vaisseau mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @ship.destroy
    redirect_to ships_path, notice: "Vaisseau supprimé."
  end

  def set_active
    current_user.group.ships.update_all(active: false)
    @ship.update(active: true)
    redirect_to ships_path, notice: "Vaisseau principal changé."
  end

  def dock
    parent = Ship.find(params[:parent_id])
    @ship.update(parent_ship: parent)
    redirect_to @ship, notice: "Vaisseau amarré dans la soute de #{parent.name}."
  end

  def undock
    @ship.update(parent_ship: nil)
    redirect_to @ship, notice: "Vaisseau désamarré."
  end

  def inventory
    @objects = @ship.ship_objects
  end

  private

  def set_ship
    @ship = Ship.find(params[:id])
  end

  def ship_params
    params.require(:ship).permit(
      :name, :price, :brand, :model, :description, :size, :max_passengers, 
      :min_crew, :hp_max, :hp_current, :main_weapon, :secondary_weapon, :turret, 
      :hyperdrive_rating, :backup_hyperdrive, :image, :parent_ship_id
    )
  end

  def update_ship_skills(ship)
    # Compétences liées au vaisseau
    ships_skills_params = params[:ships_skills] || []
    ships_skills_params.each do |skill_hash|
      next if skill_hash["skill_id"].blank?
      skill = Skill.find_by(id: skill_hash["skill_id"])
      next unless skill
      ships_skill = ship.ships_skills.find_or_initialize_by(skill: skill)
      ships_skill.update(
        mastery: skill_hash["mastery"].to_i,
        bonus: skill_hash["bonus"].to_i
      )
    end
  end

  def update_ship_weapons(ship)
    # Arme principale
    if params[:main_weapon].present?
      ship.ship_weapons.create(
        name: params[:main_weapon],
        weapon_type: 'main',
        damage_mastery: 5, # valeur par défaut
        damage_bonus: 0,
        aim_mastery: 5,
        aim_bonus: 0
      )
    end
    # Arme secondaire
    if params[:secondary_weapon].present?
      ship.ship_weapons.create(
        name: params[:secondary_weapon],
        weapon_type: 'secondary',
        damage_mastery: 4, # valeur par défaut
        damage_bonus: 0,
        aim_mastery: 4,
        aim_bonus: 0
      )
    end
    # Tourelles
    if params[:tourelles] == '1' && params[:tourelles_count].to_i > 0
      (1..params[:tourelles_count].to_i).each do |i|
        ship.ship_weapons.create(
          name: "Tourelle ##{i}",
          weapon_type: 'tourelle',
          damage_mastery: 4,
          damage_bonus: 0,
          aim_mastery: 4,
          aim_bonus: 0
        )
      end
      ship.update(tourelles: params[:tourelles_count].to_i)
    else
      ship.update(tourelles: 0)
    end
    # Torpilles
    if params[:torpilles] == '1' && params[:torpilles_count].to_i > 0
      ship.ship_weapons.create(
        name: 'Lance-Torpilles à protons',
        weapon_type: 'torpille',
        quantity_max: params[:torpilles_count].to_i,
        quantity_current: params[:torpilles_count].to_i,
        damage_mastery: 8,
        damage_bonus: 0,
        aim_mastery: 6,
        aim_bonus: 0
      )
      ship.update(torpilles: true)
    else
      ship.update(torpilles: false)
    end
    # Missiles
    if params[:missiles] == '1' && params[:missiles_count].to_i > 0
      ship.ship_weapons.create(
        name: 'Lance-Missiles à concussion',
        weapon_type: 'missile',
        quantity_max: params[:missiles_count].to_i,
        quantity_current: params[:missiles_count].to_i,
        damage_mastery: 6,
        damage_bonus: 0,
        aim_mastery: 5,
        aim_bonus: 0
      )
      ship.update(missiles: true)
    else
      ship.update(missiles: false)
    end
  end
end
