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

  # Positions relatives telles que présentées aux joueurs
  RELATIVE_LABELS = {
    poursuivant: "Poursuivant",
    poursuivi: "Poursuivi",
    face_a_face: "Face à face",
    vol_parallele: "Vol parallèle",
    hors_de_portee: "Hors de portée"
  }.freeze

  # La matrice d'armes fait partie des règles : elle vit dans SpaceCombatRules.
  def self.weapon_matrix
    SpaceCombatRules::WEAPON_MATRIX
  end

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

  def other_than(participant)
    participant.id == participant_a_id ? participant_b : participant_a
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

  # Position absolue correspondant à la position relative souhaitée par `mover`
  def absolute_position_for(mover, desired_relative)
    case desired_relative.to_s
    when "poursuivant"
      mover.id == participant_a_id ? :a_pursues_b : :b_pursues_a
    when "poursuivi"
      mover.id == participant_a_id ? :b_pursues_a : :a_pursues_b
    when "face_a_face"
      :face_to_face
    when "vol_parallele"
      :parallel
    else
      :out_of_range
    end
  end

  def position_label
    POSITION_LABELS[position] || position
  end

  def position_label_for(participant)
    RELATIVE_LABELS[relative_position_for(participant)]
  end

  # Angle mort : le petit vaisseau `participant` est indétectable par les armes
  # conventionnelles du gros vaisseau adverse (règle 4-9).
  def blind_spot_for?(participant)
    blind_spot_for_id.present? && blind_spot_for_id == participant.id
  end

  def blind_spot_participant
    return nil if blind_spot_for_id.blank?

    [participant_a, participant_b].find { |p| p.id == blind_spot_for_id }
  end

  private

  def participants_on_different_sides
    return unless participant_a && participant_b

    errors.add(:base, "Les participants doivent être de camps différents") if participant_a.side == participant_b.side
  end

  def a_id_less_than_b_id
    return unless participant_a_id && participant_b_id

    return if participant_a_id < participant_b_id

    errors.add(:base, "participant_a_id doit être inférieur à participant_b_id")
  end
end
