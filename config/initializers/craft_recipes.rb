CRAFT_RECIPES = {
  "Medipack" => {
    ingredients: { "Dose de bacta" => 1, "Composant" => 2, "Senseur" => 1, "Répartiteur fuselé" => 1 },
    difficulty: 10
  },
  "Medipack +" => {
    ingredients: { "Dose de bacta" => 2, "Composant" => 2, "Senseur" => 1, "Répartiteur fuselé" => 1 },
    difficulty: 15
  },
  "Medipack Deluxe" => {
    ingredients: { "Dose de bacta" => 1, "Dose de kolto" => 1, "Composant" => 2, "Senseur" => 1, "Répartiteur fuselé" => 1 },
    difficulty: 20
  },

  # Patchs
  "Poisipatch" => {
    difficulty: 10,
    ingredients: { "Passiflore" => 1, "Composant" => 1 }
  },
  "Traumapatch" => {
    difficulty: 10,
    ingredients: { "Medipack" => 1, "Composant" => 1 }
  },
  "Stimpatch" => {
    difficulty: 15,
    ingredients: { "Cardamine" => 1, "Composant" => 1 }
  },
  "Fibripatch" => {
    difficulty: 15,
    ingredients: { "Dose de bacta" => 2, "Composant" => 1 }
  },
  "Vigpatch" => {
    difficulty: 15,
    ingredients: { "Répartiteur fuselé" => 1, "Cardamine" => 1, "Composant" => 1 }
  },
  "Focuspatch" => {
    difficulty: 15,
    ingredients: { "Yeux de rapace" => 1, "Composant" => 1 }
  },
  "Répercupatch" => {
    difficulty: 20,
    ingredients: { "Sang de félin" => 1, "Répercuteur" => 1, "Composant" => 1 }
  },
  "Vitapatch" => {
    difficulty: 20,
    ingredients: { "Dose de kolto" => 1, "Composant" => 1 }
  },

  # Autres objets de soins
  "Antidote" => {
    difficulty: 20,
    ingredients: { "Neurotoxine" => 1, "Fiole" => 1, "Matière organique" => 1 }
  },
  "Remède antibiotique" => {
    difficulty: 15,
    ingredients: { "Dose de bacta" => 1, "Fiole" => 1, "Matière organique" => 1 }
  },
  "Rétroviral" => {
    difficulty: 20,
    ingredients: { "Cardamine" => 1, "Fiole" => 1, "Matière organique" => 1 }
  },
  "Lotion réparatrice" => {
    difficulty: 20,
    ingredients: { "Dose de kolto" => 1, "Fiole" => 1, "Matière organique" => 1 }
  },
  "Draineur de radiations" => {
    difficulty: 25,
    ingredients: { "Dose de bacta" => 1, "Kava" => 1, "Injecteur de photon" => 1 }
  },
  "Trompe-la-mort" => {
    difficulty: 30,
    ingredients: { 
      "Neurotoxine" => 1,
      "Dose de kolto" => 1,
      "Dose de bacta" => 1,
      "Fiole" => 1,
      "Matière organique" => 2
    }
  },

  # Ingrédients craftables
  "Diffuseur aérosol" => {
    difficulty: 10,
    ingredients: { "Composant" => 3, "Circuit de retransmission" => 1 }
  },

  # Injections
  "Injection d'adrénaline" => {
    difficulty: 15,
    ingredients: { "Sang de félin" => 1, "Fiole" => 1, "Composant" => 1 }
  },
  "Injection d'hormone de Shalk" => {
    difficulty: 15,
    ingredients: { "Hormone de rongeur" => 1, "Fiole" => 1, "Composant" => 1 }
  },
  "Injection de phosphore" => {
    difficulty: 15,
    ingredients: { "Cerveau de mammifère aquatique" => 1, "Fiole" => 1, "Composant" => 1 }
  },
  "Injection de focusféron" => {
    difficulty: 15,
    ingredients: { "Yeux de rapace" => 1, "Fiole" => 1, "Composant" => 1 }
  },
  "Injection de trinitine" => {
    difficulty: 20,
    ingredients: { "Sang de Dragon Krayt" => 1, "Fiole" => 1, "Composant" => 1 }
  },
  "Injection de stimulant" => {
    difficulty: 20,
    ingredients: { "Sang de Rancor" => 1, "Fiole" => 1, "Composant" => 1 }
  },

  "Gaz Lacrymogène" => {
    difficulty: 10,
    ingredients: { "Kava" => 1, "Diffuseur aérosol" => 1 }
  },
  "Gaz Souffre" => {
    difficulty: 15,
    ingredients: { "Cardamine" => 1, "Diffuseur aérosol" => 1 }
  },
  "Gaz Empoisonné" => {
    difficulty: 20,
    ingredients: { "Passiflore" => 2, "Diffuseur aérosol" => 1 }
  },
  "Gaz Neurolax" => {
    difficulty: 30,
    ingredients: { "Neurotoxine" => 1, "Diffuseur aérosol" => 1 }
  },

  "Laxatif" => {
    difficulty: 10,
    ingredients: { "Cardamine" => 1, "Fiole" => 1 }
  },
  "Tranquilisant" => {
    difficulty: 10,
    ingredients: { "Kava" => 1, "Fiole" => 1 }
  },
  "Somnifère" => {
    difficulty: 15,
    ingredients: { "Passiflore" => 1, "Fiole" => 1 }
  },
  "Poison" => {
    difficulty: 15,
    ingredients: { "Passiflore" => 1, "Cardamine" => 1, "Fiole" => 1 }
  },
  "Poison neurotoxique" => {
    difficulty: 20,
    ingredients: { "Neurotoxine" => 1, "Kava" => 2, "Fiole" => 1 }
  },
  "Poison foudroyant" => {
    difficulty: 25,
    ingredients: { "Neurotoxine" => 2, "Passiflore" => 2, "Fiole" => 1 }
  },
  "Stimulateur mnémonique" => {
    difficulty: 15,
    ingredients: { "Neurotoxine" => 1, "Kava" => 1, "Passiflore" => 1, "Cardamine" => 1, "Fiole" => 1 }
  }
}