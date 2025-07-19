import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["name", "damageMastery", "damageBonus", "aimMastery", "aimBonus", "special", "price", "weaponType", "quantityMax", "quantityCurrent"];

  // Configuration des armes prédéfinies (doit correspondre à Ship::PREDEFINED_WEAPONS)
  static predefinedWeapons = {
    "Canon blaster": {
      price: 500,
      damage_mastery: 5,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: null
    },
    "Canon lourd": {
      price: 1500,
      damage_mastery: 6,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: -1,
      special: null
    },
    "Canon plasmique": {
      price: 5000,
      damage_mastery: 6,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: null
    },
    "Canon Magma": {
      price: 10000,
      damage_mastery: 7,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Traversant, -3PB/tir"
    },
    "Canon à ions": {
      price: 1500,
      damage_mastery: 5,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Peut ioniser les commandes du vaisseau adverse"
    },
    "Lance-Missiles à concussion": {
      price: 8000,
      damage_mastery: 6,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Arme à munitions limitées",
      weapon_type: 'missile'
    },
    "Lance-Torpilles à protons": {
      price: 10000,
      damage_mastery: 8,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Arme à munitions limitées",
      weapon_type: 'torpille'
    },
    "Tourelle pulso-blaster": {
      price: 1000,
      damage_mastery: 4,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: null,
      weapon_type: 'tourelle'
    },
    "Tourelle lourde": {
      price: 2000,
      damage_mastery: 5,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: -1,
      special: null,
      weapon_type: 'tourelle'
    },
    "Tourelle plasmique": {
      price: 4000,
      damage_mastery: 5,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: null,
      weapon_type: 'tourelle'
    },
    "Tourelle à ions": {
      price: 1500,
      damage_mastery: 4,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Ionisant",
      weapon_type: 'tourelle'
    },
    // Équipements spéciaux
    "Rayon tracteur": {
      price: 500,
      damage_mastery: 0,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Peut attirer des objets ou petits vaisseaux",
      weapon_type: 'special'
    },
    "Scanner de cargaison": {
      price: 800,
      damage_mastery: 0,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Révèle la cargaison d'un vaisseau ciblé",
      weapon_type: 'special'
    },
    "Scanner d'activité": {
      price: 1000,
      damage_mastery: 0,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Détecte les êtres vivants et activités à bord",
      weapon_type: 'special'
    },
    "Module de camouflage": {
      price: 1500,
      damage_mastery: 0,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Invisibilité temporaire aux senseurs",
      weapon_type: 'special'
    },
    "Extracteur de minerai": {
      price: 1200,
      damage_mastery: 0,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Extraction de minerais depuis l'espace ou planètes",
      weapon_type: 'special'
    },
    "Scanner de planète": {
      price: 500,
      damage_mastery: 0,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Analyse complète des planètes",
      weapon_type: 'special'
    },
    "Onduleur de bouclier": {
      price: 1000,
      damage_mastery: 0,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Redistribution des boucliers directionnels",
      weapon_type: 'special'
    },
    "Balise de localisation": {
      price: 200,
      damage_mastery: 0,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Marquage de vaisseaux pour suivi",
      weapon_type: 'special',
      quantity_max: 10
    },
    "Contre-mesures": {
      price: 200,
      damage_mastery: 0,
      damage_bonus: 0,
      aim_mastery: 0,
      aim_bonus: 0,
      special: "Réduction précision missiles/torpilles ennemis",
      weapon_type: 'special',
      quantity_max: 10
    }
  };

  fillFields(event) {
    const weaponName = event.target.value;
    
    if (!weaponName || !this.constructor.predefinedWeapons[weaponName]) {
      this.clearFields();
      return;
    }

    const weapon = this.constructor.predefinedWeapons[weaponName];

    // Remplir les champs de base
    this.nameTarget.value = weaponName;
    this.damageMasteryTarget.value = weapon.damage_mastery || 0;
    this.damageBonusTarget.value = weapon.damage_bonus || 0;
    this.aimMasteryTarget.value = weapon.aim_mastery || 0;
    this.aimBonusTarget.value = weapon.aim_bonus || 0;
    this.specialTarget.value = weapon.special || '';
    this.priceTarget.value = weapon.price || 0;

    // Définir le type d'arme approprié
    if (weapon.weapon_type) {
      this.weaponTypeTarget.value = weapon.weapon_type;
    }

    // Gérer les quantités si l'équipement en a
    if (this.hasQuantityMaxTarget && this.hasQuantityCurrentTarget) {
      if (weapon.quantity_max) {
        this.quantityMaxTarget.value = weapon.quantity_max;
        this.quantityCurrentTarget.value = 1; // Par défaut 1 pour les nouveaux équipements
      } else if (weapon.weapon_type === 'missile' || weapon.weapon_type === 'torpille') {
        this.quantityMaxTarget.value = 3;
        this.quantityCurrentTarget.value = 3;
      } else {
        this.quantityMaxTarget.value = '';
        this.quantityCurrentTarget.value = 0;
      }
    }

    console.log(`Équipement prédéfini sélectionné: ${weaponName}`, weapon);
  }

  clearFields() {
    this.nameTarget.value = '';
    this.damageMasteryTarget.value = 0;
    this.damageBonusTarget.value = 0;
    this.aimMasteryTarget.value = 0;
    this.aimBonusTarget.value = 0;
    this.specialTarget.value = '';
    this.priceTarget.value = 0;
    this.weaponTypeTarget.value = 'purchased';
    
    if (this.hasQuantityMaxTarget && this.hasQuantityCurrentTarget) {
      this.quantityMaxTarget.value = '';
      this.quantityCurrentTarget.value = 0;
    }
  }
} 