class ShipCombatPosition < ApplicationRecord
  belongs_to :space_combat_state
  belongs_to :participant_a, class_name: "SpaceCombatParticipant"
  belongs_to :participant_b, class_name: "SpaceCombatParticipant"

  enum position: {
    out_of_range: 0,
    a_pursues_b: 1,
    b_pursues_a: 2,
    face_to_face: 3,
    parallel: 4
  }

  POSITION_LABELS = {
    "out_of_range" => "Hors de portée",
    "a_pursues_b" => "A poursuit B",
    "b_pursues_a" => "B poursuit A",
    "face_to_face" => "Face à face",
    "parallel" => "Vol parallèle"
  }.freeze

  # Matrice d'armes autorisées par position relative
  WEAPON_MATRIX = {
    poursuivant: { canon: true, tourelle: true, missile: true, torpille: true, special: true },
    poursuivi: { canon: false, tourelle: true, missile: false, torpille: false, special: true },
    face_a_face: { canon: true, tourelle: true, missile: true, torpille: true, special: true },
    vol_parallele: { canon: false, tourelle: true, missile: false, torpille: false, special: true },
    hors_de_portee: { canon: false, tourelle: false, missile: false, torpille: false, special: false }
  }.freeze

  validate :participants_on_different_sides
  validate :a_id_less_than_b_id

  def self.find_pair(combat_id, id1, id2)
    a_id, b_id = [id1, id2].sort
    find_by(space_combat_state_id: combat_id, participant_a_id: a_id, participant_b_id: b_id)
  end

  def self.find_or_create_pair(combat_id, id1, id2)
    a_id, b_id = [id1, id2].sort
    find_or_create_by!(
      space_combat_state_id: combat_id,
      participant_a_id: a_id,
      participant_b_id: b_id
    )
  end

  def relative_position_for(participant)
    case position
    when "out_of_range"
      :hors_de_portee
    when "a_pursues_b"
      participant.id == participant_a_id ? :poursuivant : :poursuivi
    when "b_pursues_a"
      participant.id == participant_b_id ? :poursuivant : :poursuivi
    when "face_to_face"
      :face_a_face
    when "parallel"
      :vol_parallele
    end
  end

  def position_label
    POSITION_LABELS[position] || position
  end

  def position_label_for(participant)
    rel = relative_position_for(participant)
    case rel
    when :poursuivant then "Poursuivant"
    when :poursuivi then "Poursuivi"
    when :face_a_face then "Face à face"
    when :vol_parallele then "Vol parallèle"
    when :hors_de_portee then "Hors de portée"
    end
  end

  private

  def participants_on_different_sides
    return unless participant_a && participant_b
    if participant_a.side == participant_b.side
      errors.add(:base, "Les participants doivent être de camps différents")
    end
  end

  def a_id_less_than_b_id
    return unless participant_a_id && participant_b_id
    if participant_a_id >= participant_b_id
      errors.add(:base, "participant_a_id doit être inférieur à participant_b_id")
    end
  end
end
