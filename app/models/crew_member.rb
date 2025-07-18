class CrewMember < ApplicationRecord
  belongs_to :ship
  belongs_to :assignable, polymorphic: true

  validates :position, presence: true
  validates :assignable_id, uniqueness: { scope: [:ship_id, :assignable_type], 
                                          message: "est déjà assigné à un poste sur ce vaisseau" }

  # Configuration des postes selon la scale du vaisseau
  POSITIONS_BY_SCALE = {
    0 => ["Pilote", "Copilote"],
    1 => ["Pilote", "Copilote"],
    2 => ["Pilote", "Copilote", "Ingénieur radar", "Gabier", "Maître machine"],
    3 => ["Pilote", "Copilote", "Ingénieur radar", "Gabier", "Maître machine"],
    4 => ["Pilote", "Copilote", "Ingénieur radar", "Gabier", "Maître machine", 
          "Ingénieur radio", "Maître d'équipage", "Capitaine", "Second du capitaine"],
    5 => ["Pilote", "Copilote", "Ingénieur radar", "Gabier", "Maître machine", 
          "Ingénieur radio", "Maître d'équipage", "Capitaine", "Second du capitaine"]
  }.freeze

  # Description des rôles
  POSITION_DESCRIPTIONS = {
    "Pilote" => "Pilote le vaisseau",
    "Copilote" => "Assiste le pilote",
    "Ingénieur radar" => "Gère les senseurs avec son jet de Systèmes",
    "Gabier" => "Gère les boucliers avec son jet d'Ingénierie",
    "Maître machine" => "Gère les réparations avec son jet de Réparation",
    "Ingénieur radio" => "Gère les communications",
    "Maître d'équipage" => "Gère les équipages et les chasseurs",
    "Capitaine" => "Apporte des bonus avec son jet de Commandement",
    "Second du capitaine" => "Remplace le capitaine quand nécessaire"
  }.freeze

  validate :position_valid_for_ship_scale
  validate :only_one_per_position_except_cannoneer

  def assignable_name
    assignable&.name || assignable&.username
  end

  def assignable_type_display
    case assignable_type
    when 'User'
      'PJ'
    when 'Pet'
      'Pet'
    else
      assignable_type
    end
  end

  private

  def position_valid_for_ship_scale
    scale_number = Ship.scales[ship.scale]
    valid_positions = POSITIONS_BY_SCALE[scale_number] || []
    
    # Ajouter les postes de canonnier selon le nombre de tourelles
    if ship.installed_turrets.any?
      ship.installed_turrets.each_with_index do |turret, index|
        valid_positions << "Canonnier #{index + 1}"
      end
    end
    
    unless valid_positions.include?(position)
      errors.add(:position, "n'est pas valide pour un vaisseau de cette taille")
    end
  end

  def only_one_per_position_except_cannoneer
    return if position.starts_with?("Canonnier")
    
    existing = ship.crew_members.where(position: position).where.not(id: id)
    if existing.exists?
      errors.add(:position, "est déjà occupé")
    end
  end
end
