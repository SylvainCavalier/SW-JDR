import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "eprouvettes", "matiere", "selectedEmbryo", "selectedGenes", "geneCount",
    "costEprouvettes", "costMatiere", "probFailure", "probPartial", "probSuccess", "probPerfect",
    "applyBtn", "resultModal", "modalHeader", "modalTitle", "resultMessage", "resultAnimation",
    "creatureStats", "statInfo", "statHp", "statDamage", "statWeapon", "statSkills", "traitsBadges"
  ];

  connect() {
    console.log("✅ Traits controller connected");
    this.selectedEmbryo = null;
    this.selectedGenes = [];
  }

  selectEmbryo(event) {
    const card = event.currentTarget;
    const embryoId = card.dataset.embryoId;

    // Désélectionner l'ancien
    document.querySelectorAll('.embryo-card.selected').forEach(el => {
      el.classList.remove('selected');
      const checkIcon = this.element.querySelector(`[data-traits-target="embryoCheck${el.dataset.embryoId}"]`);
      if (checkIcon) checkIcon.classList.add('d-none');
    });

    // Sélectionner le nouveau
    card.classList.add('selected');
    const checkIcon = this.element.querySelector(`[data-traits-target="embryoCheck${embryoId}"]`);
    if (checkIcon) checkIcon.classList.remove('d-none');

    this.selectedEmbryo = {
      id: embryoId,
      name: card.dataset.embryoName,
      type: card.dataset.embryoType,
      hp: card.dataset.embryoHp,
      damage: card.dataset.embryoDamage,
      weapon: card.dataset.embryoWeapon
    };

    // Mettre à jour l'affichage
    this.selectedEmbryoTarget.innerHTML = `
      <strong>${this.selectedEmbryo.name}</strong>
      <span class="badge bg-success ms-2">${this.humanize(this.selectedEmbryo.type)}</span>
      <br><small>PV: ${this.selectedEmbryo.hp} | Dégâts: ${this.selectedEmbryo.damage}D | Arme: ${this.selectedEmbryo.weapon || '-'}</small>
    `;

    this.updateApplyButton();
  }

  toggleGene(event) {
    const card = event.currentTarget;
    const geneId = card.dataset.geneId;
    const geneLevel = parseInt(card.dataset.geneLevel);
    const geneName = card.dataset.geneName;

    const existingIndex = this.selectedGenes.findIndex(g => g.id === geneId);

    if (existingIndex >= 0) {
      // Désélectionner
      this.selectedGenes.splice(existingIndex, 1);
      card.classList.remove('selected');
      const checkIcon = this.element.querySelector(`[data-traits-target="geneCheck${geneId}"]`);
      if (checkIcon) checkIcon.classList.add('d-none');
    } else {
      // Vérifier la limite de 3
      if (this.selectedGenes.length >= 3) {
        this.showAlert("Vous ne pouvez sélectionner que 3 gènes maximum.");
        return;
      }

      // Sélectionner
      this.selectedGenes.push({ id: geneId, level: geneLevel, name: geneName });
      card.classList.add('selected');
      const checkIcon = this.element.querySelector(`[data-traits-target="geneCheck${geneId}"]`);
      if (checkIcon) checkIcon.classList.remove('d-none');
    }

    this.updateGenesDisplay();
    this.updateProbabilities();
    this.updateApplyButton();
  }

  updateGenesDisplay() {
    this.geneCountTarget.textContent = this.selectedGenes.length;

    if (this.selectedGenes.length === 0) {
      this.selectedGenesTarget.innerHTML = `
        <div class="alert alert-secondary py-2">
          <em class="text-muted">Aucun gène sélectionné</em>
        </div>
      `;
    } else {
      const badges = this.selectedGenes.map(g => `
        <span class="badge bg-success me-1 mb-1">
          ${g.name} <span class="badge bg-warning text-dark">Nv.${g.level}</span>
        </span>
      `).join('');
      this.selectedGenesTarget.innerHTML = `<div>${badges}</div>`;
    }
  }

  async updateProbabilities() {
    if (this.selectedGenes.length === 0) {
      this.resetProbabilities();
      return;
    }

    try {
      const response = await fetch("/science/calculate_probabilities", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          genes: this.selectedGenes.map(g => ({ gene_id: g.id, level: g.level }))
        })
      });

      const data = await response.json();

      // Mettre à jour les barres de probabilité
      this.probFailureTarget.style.width = `${data.probabilities.failure}%`;
      this.probFailureTarget.textContent = `${data.probabilities.failure}%`;
      
      this.probPartialTarget.style.width = `${data.probabilities.partial}%`;
      this.probPartialTarget.textContent = `${data.probabilities.partial}%`;
      
      this.probSuccessTarget.style.width = `${data.probabilities.success}%`;
      this.probSuccessTarget.textContent = `${data.probabilities.success}%`;
      
      this.probPerfectTarget.style.width = `${data.probabilities.perfect}%`;
      this.probPerfectTarget.textContent = `${data.probabilities.perfect}%`;

      // Mettre à jour les coûts
      this.costEprouvettesTarget.textContent = data.costs.eprouvettes;
      this.costMatiereTarget.textContent = data.costs.matiere;
    } catch (error) {
      console.error("Erreur calcul probabilités:", error);
    }
  }

  resetProbabilities() {
    this.probFailureTarget.style.width = "0%";
    this.probFailureTarget.textContent = "0%";
    this.probPartialTarget.style.width = "0%";
    this.probPartialTarget.textContent = "0%";
    this.probSuccessTarget.style.width = "0%";
    this.probSuccessTarget.textContent = "0%";
    this.probPerfectTarget.style.width = "0%";
    this.probPerfectTarget.textContent = "0%";
    this.costEprouvettesTarget.textContent = "0";
    this.costMatiereTarget.textContent = "0";
  }

  updateApplyButton() {
    const canApply = this.selectedEmbryo && this.selectedGenes.length > 0;
    this.applyBtnTarget.disabled = !canApply;
  }

  async applyTraits() {
    if (!this.selectedEmbryo || this.selectedGenes.length === 0) return;

    this.applyBtnTarget.disabled = true;
    this.applyBtnTarget.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Application en cours...';

    try {
      const response = await fetch("/science/apply_traits", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          embryo_id: this.selectedEmbryo.id,
          genes: this.selectedGenes.map(g => ({ gene_id: g.id, level: g.level }))
        })
      });

      const data = await response.json();

      // Mettre à jour les ressources
      if (data.new_eprouvettes !== undefined) {
        this.eprouvettesTarget.textContent = data.new_eprouvettes;
      }
      if (data.new_matiere !== undefined) {
        this.matiereTarget.textContent = data.new_matiere;
      }

      this.showResult(data);
    } catch (error) {
      console.error("Erreur:", error);
      this.showAlert("Une erreur est survenue.");
    } finally {
      this.applyBtnTarget.disabled = false;
      this.applyBtnTarget.innerHTML = '<i class="fa-solid fa-dna me-2"></i>Appliquer les traits';
    }
  }

  showResult(data) {
    const resultType = data.result_type;
    
    // Configurer le modal selon le résultat
    switch (resultType) {
      case 'failure':
        this.modalHeaderTarget.className = 'modal-header bg-danger';
        this.modalTitleTarget.textContent = '❌ Échec Total';
        this.resultAnimationTarget.innerHTML = '<img src="/assets/echec.png" alt="Échec" class="img-fluid mb-3" style="max-height: 150px;">';
        this.creatureStatsTarget.classList.add('d-none');
        break;
      case 'partial':
        this.modalHeaderTarget.className = 'modal-header bg-warning';
        this.modalTitleTarget.textContent = '⚠️ Réussite Partielle';
        this.resultAnimationTarget.innerHTML = '<img src="/assets/echec.png" alt="Partiel" class="img-fluid mb-3" style="max-height: 150px; opacity: 0.7;">';
        this.showCreatureStats(data.embryo);
        break;
      case 'success':
        this.modalHeaderTarget.className = 'modal-header bg-success';
        this.modalTitleTarget.textContent = '✅ Réussite !';
        this.resultAnimationTarget.innerHTML = '<img src="/assets/reussite.png" alt="Réussite" class="img-fluid mb-3 pulse-animation" style="max-height: 150px;">';
        this.showCreatureStats(data.embryo);
        break;
      case 'perfect':
        this.modalHeaderTarget.className = 'modal-header bg-info';
        this.modalTitleTarget.textContent = '🌟 Réussite Parfaite !';
        this.resultAnimationTarget.innerHTML = '<img src="/assets/reussite.png" alt="Parfait" class="img-fluid mb-3 pulse-animation" style="max-height: 150px; filter: drop-shadow(0 0 10px gold);">';
        this.showCreatureStats(data.embryo);
        break;
    }

    this.resultMessageTarget.textContent = data.message || data.error;

    // Afficher le modal
    const modal = new bootstrap.Modal(this.resultModalTarget);
    modal.show();

    // Si succès, recharger la page après fermeture du modal
    if (data.success) {
      this.resultModalTarget.addEventListener('hidden.bs.modal', () => {
        window.location.reload();
      }, { once: true });
    }
  }

  showCreatureStats(embryo) {
    if (!embryo) return;

    this.creatureStatsTarget.classList.remove('d-none');
    
    // Infos de base (type, race, nom)
    if (this.hasStatInfoTarget) {
      this.statInfoTarget.innerHTML = `
        <p class="mb-2">
          <strong>${embryo.name}</strong>
          <span class="badge bg-success ms-2">${this.humanize(embryo.creature_type)}</span>
          ${embryo.race ? `<span class="badge bg-info ms-1">${embryo.race}</span>` : ''}
          ${embryo.gender ? `<span class="badge bg-secondary ms-1">${embryo.gender}</span>` : ''}
        </p>
      `;
    }

    this.statHpTarget.textContent = embryo.hp_max;
    this.statDamageTarget.textContent = `${embryo.damage_1}D+${embryo.damage_bonus_1}`;
    this.statWeaponTarget.textContent = embryo.weapon || '-';

    // Skills
    if (embryo.skills && embryo.skills.length > 0) {
      this.statSkillsTarget.innerHTML = embryo.skills.map(s => `
        <li class="list-group-item bg-transparent text-light">
          <i class="fa-solid fa-circle-dot text-success me-2"></i>${s.name}: <strong>${s.mastery}D+${s.bonus}</strong>
        </li>
      `).join('');
    }

    // Traits spéciaux
    if (embryo.special_traits && embryo.special_traits.length > 0) {
      this.traitsBadgesTarget.innerHTML = embryo.special_traits.map(t => `
        <span class="badge bg-info text-dark me-1 mb-1">${t}</span>
      `).join('');
    } else {
      this.traitsBadgesTarget.innerHTML = '<em class="text-muted">Aucun</em>';
    }
  }

  async startGestation(event) {
    const embryoId = event.currentTarget.dataset.embryoId;
    
    if (!confirm("Mettre cet embryon en gestation ?")) return;

    try {
      const response = await fetch("/science/start_gestation", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ embryo_id: embryoId })
      });

      const data = await response.json();

      if (data.success) {
        alert(`Embryon placé dans la cuve ${data.tube}. Durée de gestation: ${data.days} jours.`);
        window.location.reload();
      } else {
        alert(data.error);
      }
    } catch (error) {
      console.error("Erreur:", error);
      alert("Une erreur est survenue.");
    }
  }

  async recycleEmbryo(event) {
    const embryoId = event.currentTarget.dataset.embryoId;
    const embryoName = event.currentTarget.dataset.embryoName;
    
    if (!confirm(`Recycler ${embryoName} ? Vous récupérerez une partie des matières organiques.`)) return;

    try {
      const response = await fetch("/science/recycle_embryo", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ embryo_id: embryoId })
      });

      const data = await response.json();

      if (data.success) {
        alert(`Embryon recyclé ! +${data.matiere_recovered} matière organique récupérée.`);
        window.location.reload();
      } else {
        alert(data.error);
      }
    } catch (error) {
      console.error("Erreur:", error);
      alert("Une erreur est survenue.");
    }
  }

  showAlert(message) {
    alert(message);
  }

  humanize(str) {
    if (!str) return "";
    return str.replace(/_/g, " ").replace(/^\w/, c => c.toUpperCase());
  }
}

