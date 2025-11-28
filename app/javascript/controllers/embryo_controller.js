import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "creatureType", "preview", "previewHp", "previewDamage", "previewResist",
    "previewPrecision", "previewSpeed", "previewDodge", "submitBtn",
    "eprouvettes", "matiere", "embryoList", "embryoCount", "emptyMessage",
    "resultModal", "modalHeader", "modalTitle", "diceResult", "resultMessage"
  ];

  connect() {
    console.log("✅ Embryo controller connected");
    this.creatureTypes = window.creatureTypes || {};
  }

  updatePreview() {
    const selectedType = this.creatureTypeTarget.value;
    
    if (!selectedType || !this.creatureTypes[selectedType]) {
      this.previewTarget.style.display = "none";
      return;
    }

    const stats = this.creatureTypes[selectedType];
    
    this.previewHpTarget.textContent = stats.hp_max || 0;
    this.previewDamageTarget.textContent = `${stats.damage || 0}D+${stats.damage_bonus || 0}`;
    this.previewResistTarget.textContent = `${stats.res_corp || 0}D`;
    this.previewPrecisionTarget.textContent = `${stats.precision || 0}D`;
    this.previewSpeedTarget.textContent = `${stats.vitesse || 0}D`;
    this.previewDodgeTarget.textContent = `${stats.esquive || 0}D`;
    
    this.previewTarget.style.display = "block";
  }

  async createEmbryo(event) {
    event.preventDefault();
    
    const form = event.target;
    const formData = new FormData(form);
    
    // Validation côté client
    const name = formData.get("embryo[name]");
    const creatureType = formData.get("embryo[creature_type]");
    
    if (!name || !creatureType) {
      this.showResult(false, 0, "Veuillez remplir tous les champs obligatoires.");
      return;
    }

    // Vérifier les ressources
    const eprouvettes = parseInt(this.eprouvettesTarget.textContent) || 0;
    const matiere = parseInt(this.matiereTarget.textContent) || 0;

    if (eprouvettes < 1 || matiere < 1) {
      this.showResult(false, 0, "Ressources insuffisantes pour cultiver un embryon.");
      return;
    }

    // Désactiver le bouton pendant la requête
    this.submitBtnTarget.disabled = true;
    this.submitBtnTarget.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Culture en cours...';

    try {
      const response = await fetch("/science/create_embryo", {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        },
        body: formData
      });

      const data = await response.json();

      if (data.success) {
        // Mise à jour des ressources
        this.eprouvettesTarget.textContent = data.new_eprouvettes;
        this.matiereTarget.textContent = data.new_matiere;
        
        // Ajouter l'embryon à la liste
        this.addEmbryoToList(data.embryo);
        
        // Réinitialiser le formulaire
        form.reset();
        this.previewTarget.style.display = "none";
        
        // Afficher le résultat
        this.showResult(true, data.dice_roll, data.message);
      } else {
        // Mise à jour des ressources si elles ont été consommées
        if (data.new_eprouvettes !== undefined) {
          this.eprouvettesTarget.textContent = data.new_eprouvettes;
        }
        if (data.new_matiere !== undefined) {
          this.matiereTarget.textContent = data.new_matiere;
        }
        
        this.showResult(false, data.dice_roll || 0, data.error);
      }
    } catch (error) {
      console.error("Erreur:", error);
      this.showResult(false, 0, "Une erreur est survenue lors de la création.");
    } finally {
      this.submitBtnTarget.disabled = false;
      this.submitBtnTarget.innerHTML = "🧫 Cultiver l'embryon";
    }
  }

  addEmbryoToList(embryo) {
    // Cacher le message vide si présent
    if (this.hasEmptyMessageTarget) {
      this.emptyMessageTarget.style.display = "none";
    }

    // Créer la nouvelle ligne
    const row = document.createElement("tr");
    row.innerHTML = `
      <td><strong>${embryo.name}</strong></td>
      <td><span class="badge bg-success">${this.humanize(embryo.creature_type)}</span></td>
      <td>${embryo.race || "-"}</td>
      <td>${this.capitalize(embryo.gender) || "-"}</td>
      <td>${this.creatureTypes[embryo.creature_type]?.hp_max || "-"}</td>
      <td>${this.creatureTypes[embryo.creature_type]?.weapon || "-"}</td>
    `;
    row.classList.add("table-success");
    
    // Ajouter en haut de la liste
    if (this.hasEmbryoListTarget) {
      this.embryoListTarget.insertBefore(row, this.embryoListTarget.firstChild);
    }

    // Mettre à jour le compteur
    if (this.hasEmbryoCountTarget) {
      const currentCount = parseInt(this.embryoCountTarget.textContent) || 0;
      this.embryoCountTarget.textContent = currentCount + 1;
    }

    // Animation de mise en évidence
    setTimeout(() => {
      row.classList.remove("table-success");
    }, 2000);
  }

  showResult(success, diceRoll, message) {
    // Mettre à jour le modal
    this.diceResultTarget.textContent = diceRoll;
    this.resultMessageTarget.textContent = message;
    
    if (success) {
      this.modalHeaderTarget.className = "modal-header bg-success";
      this.modalTitleTarget.textContent = "🎉 Succès !";
      this.diceResultTarget.className = "display-1 text-success";
    } else {
      this.modalHeaderTarget.className = "modal-header bg-danger";
      this.modalTitleTarget.textContent = "❌ Échec";
      this.diceResultTarget.className = "display-1 text-danger";
    }

    // Afficher le modal
    const modal = new bootstrap.Modal(this.resultModalTarget);
    modal.show();
  }

  humanize(str) {
    if (!str) return "";
    return str.replace(/_/g, " ").replace(/^\w/, c => c.toUpperCase());
  }

  capitalize(str) {
    if (!str) return "";
    return str.charAt(0).toUpperCase() + str.slice(1);
  }
}

