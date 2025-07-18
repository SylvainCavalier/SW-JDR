module ShipsHelper
  DAMAGE_DESCRIPTIONS = [
    "Stabilisateur de flux quantique grillé",
    "Condensateur à protons surchargé",
    "Réacteur à plasma instable",
    "Générateur de bouclier déphasé",
    "Cellule énergétique d'hyper-matière",
    "Accumulateur tachyonique déchargé",
    "Bobine supraconductrice endommagée",
    "Synthé-câbles endommagés",
    "Relais subspatial déconnecté",
    "Connecteur neuro-optique oxydé",
    "Fibre de transfert subatomique rompue",
    "Jonction magnétique dessoudée",
    "Nœud cybernétique défaillant",
    "Plaques de blindage neutronisées",
    "Microfissure dans le châssis anti-grav",
    "Joint d'étanchéité quantique rompu",
    "Sas anti-dépressurisation défaillant",
    "Structure moléculaire désalignée",
    "Circuit logique quantique corrompu",
    "Mémoire holographique fragmentée",
    "Module d'intelligence artificielle désynchronisé",
    "Interface neuronale non responsive",
    "Sous-routine d'urgence en boucle infinie",
    "Injecteurs d'hypercarburant bouchés",
    "Accélérateur gravimétrique bloqué",
    "Compresseur à impulsion défaillant",
    "Bobine hyperluminique grillée",
    "Régulateur inertiel mal calibré",
    "Canon ionique désaligné",
    "Lanceur de torpilles photonique enrayé",
    "Batterie laser en surchauffe",
    "Chambre à plasma obstruée",
    "Condensateur de phase laser épuisé",
    "Générateur de champ d'intégrité affaibli",
    "Émetteur déflecteur hors ligne",
    "Condensateur d'absorption cinétique saturé",
    "Matrice de blindage énergétique fissurée"
  ].freeze

  def ship_damage_list(ship)
    hp_missing = ship.hp_max - ship.hp_current
    return [] if hp_missing <= 0

    # Générer une liste d'avaries basée sur l'ID du vaisseau pour la cohérence
    # Le nombre d'avaries dépend du nombre de HP perdus
    damage_count = [hp_missing, DAMAGE_DESCRIPTIONS.length].min
    
    # Utiliser l'ID du vaisseau comme seed pour avoir des avaries cohérentes
    rng = Random.new(ship.id)
    
    # Sélectionner des avaries aléatoires mais reproductibles
    selected_damages = DAMAGE_DESCRIPTIONS.sample(damage_count, random: rng)
    
    selected_damages
  end
end 