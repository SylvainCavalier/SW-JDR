# Configuration des améliorations de vaisseaux
SHIP_UPGRADES = {
  thruster: {
    name: "Propulseur",
    description: "Améliore la vitesse du vaisseau",
    skill_name: "Vitesse",
    image: "ships/Propulseurs.png",
    levels: {
      0 => { name: "Propulseur sub-luminique", price: 0, bonus: "0", image_url: "ships/Propulseurs.png" },
      1 => { name: "Propulseur à protons", price: 1500, bonus: "+1", image_url: "ships/Propulseurs.png" },
      2 => { name: "Propulseur luminique", price: 3500, bonus: "+2", image_url: "ships/Propulseurs.png" },
      3 => { name: "Propulseur extra-luminique", price: 5500, bonus: "+1D", image_url: "ships/Propulseurs.png" }
    }
  },
  hull: {
    name: "Berceau de la Coque",
    description: "Améliore la coque du vaisseau",
    skill_name: "Coque",
    image: "ships/Coque.png",
    levels: {
      0 => { name: "Coque de série", price: 0, bonus: "0", image_url: "ships/Coque.png" },
      1 => { name: "Berceau de la Coque quadridium", price: 3000, bonus: "+1", image_url: "ships/Coque.png" },
      2 => { name: "Berceau de la Coque en lirédium", price: 6000, bonus: "+2", image_url: "ships/Coque.png" },
      3 => { name: "Berceau de la Coque en duracier", price: 10000, bonus: "+1D", image_url: "ships/Coque.png" }
    }
  },
  circuits: {
    name: "Optimisation des flux",
    description: "Améliore la maniabilité du vaisseau",
    skill_name: "Maniabilité",
    image: "ships/Flux.png",
    levels: {
      0 => { name: "Circuits de transmission", price: 0, bonus: "0", image_url: "ships/Flux.png" },
      1 => { name: "Optimisation des flux I", price: 2500, bonus: "+1", image_url: "ships/Flux.png" },
      2 => { name: "Optimisation des flux II", price: 4000, bonus: "+2", image_url: "ships/Flux.png" },
      3 => { name: "Optimisation des flux III", price: 8000, bonus: "+1D", image_url: "ships/Flux.png" }
    }
  },
  shield_system: {
    name: "Stabilisateur d'écrans",
    description: "Améliore les écrans du vaisseau",
    skill_name: "Ecrans",
    image: "ships/Ecrans.png",
    levels: {
      0 => { name: "Ecrans standards", price: 0, bonus: "0", image_url: "ships/Ecrans.png" },
      1 => { name: "Stabilisateur d'écrans I", price: 1500, bonus: "+1", image_url: "ships/Ecrans.png" },
      2 => { name: "Stabilisateur d'écrans II", price: 2000, bonus: "+2", image_url: "ships/Ecrans.png" },
      3 => { name: "Stabilisateur d'écrans II", price: 4000, bonus: "+1D", image_url: "ships/Ecrans.png" }
    }
  }
  }.freeze 