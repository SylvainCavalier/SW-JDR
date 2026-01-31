import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["viewModal", "viewTitle", "viewContent"];

  connect() {
    console.log("✅ Gestation controller connected");
  }

  async viewEmbryo(event) {
    const embryoId = event.currentTarget.dataset.embryoId;

    try {
      const response = await fetch(`/science/embryo/${embryoId}`, {
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      });

      const embryo = await response.json();

      this.viewTitleTarget.textContent = `🧬 ${embryo.name}`;
      this.viewContentTarget.innerHTML = `
        <div class="row">
          <div class="col-md-6">
            <h6 class="text-info">Informations générales</h6>
            <ul class="list-group list-group-flush mb-3">
              <li class="list-group-item bg-transparent text-light">
                <strong>Type:</strong> ${this.humanize(embryo.creature_type)}
              </li>
              <li class="list-group-item bg-transparent text-light">
                <strong>Race:</strong> ${embryo.race || '-'}
              </li>
              <li class="list-group-item bg-transparent text-light">
                <strong>Genre:</strong> ${embryo.gender || '-'}
              </li>
              <li class="list-group-item bg-transparent text-light">
                <strong>Statut:</strong> <span class="badge bg-info">${embryo.status}</span>
              </li>
            </ul>
            
            <h6 class="text-info">Progression</h6>
            <ul class="list-group list-group-flush">
              <li class="list-group-item bg-transparent text-light">
                <strong>Jours restants:</strong> ${embryo.gestation_days_remaining} / ${embryo.gestation_days_total}
              </li>
            </ul>
          </div>
          
          <div class="col-md-6">
            <h6 class="text-info">Caractéristiques</h6>
            <ul class="list-group list-group-flush mb-3">
              <li class="list-group-item bg-transparent text-light">
                <i class="fa-solid fa-heart text-danger me-2"></i><strong>PV Max:</strong> ${embryo.hp_max}
              </li>
              <li class="list-group-item bg-transparent text-light">
                <i class="fa-solid fa-sword text-warning me-2"></i><strong>Dégâts:</strong> ${embryo.damage_1}D+${embryo.damage_bonus_1}
              </li>
              <li class="list-group-item bg-transparent text-light">
                <i class="fa-solid fa-hand-fist text-info me-2"></i><strong>Arme:</strong> ${embryo.weapon || '-'}
              </li>
            </ul>
            
            <h6 class="text-info">Compétences</h6>
            <ul class="list-group list-group-flush">
              ${embryo.skills.map(s => `
                <li class="list-group-item bg-transparent text-light">
                  <strong>${s.name}:</strong> ${s.mastery}D+${s.bonus}
                </li>
              `).join('')}
            </ul>
          </div>
        </div>
        
        ${embryo.special_traits && embryo.special_traits.length > 0 ? `
          <div class="mt-3">
            <h6 class="text-info">Traits spéciaux</h6>
            <div>
              ${embryo.special_traits.map(t => `<span class="badge bg-success me-1 mb-1">${t}</span>`).join('')}
            </div>
          </div>
        ` : ''}
      `;

      const modal = new bootstrap.Modal(this.viewModalTarget);
      modal.show();
    } catch (error) {
      console.error("Erreur:", error);
      alert("Impossible de charger les détails de l'embryon.");
    }
  }

  async cloneEmbryo(event) {
    const embryoId = event.currentTarget.dataset.embryoId;
    const targetTube = event.currentTarget.dataset.targetTube;

    if (!confirm("Cloner cet embryon ? (Coût: 100 crédits + 3 matières organiques, 50% de réussite)")) {
      return;
    }

    const btn = event.currentTarget;
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm"></span>';

    try {
      const response = await fetch("/science/clone_embryo", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ embryo_id: embryoId, target_tube: targetTube })
      });

      const data = await response.json();

      if (data.success) {
        alert(`Clonage réussi ! Le clone a été placé dans la cuve ${targetTube}.`);
        window.location.reload();
      } else {
        alert(data.error || "Le clonage a échoué.");
        btn.disabled = false;
        btn.innerHTML = '<i class="fa-solid fa-clone me-1"></i>Cloner';
      }
    } catch (error) {
      console.error("Erreur:", error);
      alert("Une erreur est survenue.");
      btn.disabled = false;
      btn.innerHTML = '<i class="fa-solid fa-clone me-1"></i>Cloner';
    }
  }

  async accelerateGestation(event) {
    const embryoId = event.currentTarget.dataset.embryoId;
    const embryoName = event.currentTarget.dataset.embryoName;

    if (!confirm(`Accélérer la gestation de ${embryoName} ? (Coût: 500 crédits + 1 matière organique)`)) {
      return;
    }

    const btn = event.currentTarget;
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm"></span>';

    try {
      const response = await fetch("/science/accelerate_gestation", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ embryo_id: embryoId })
      });

      const data = await response.json();

      if (data.success) {
        alert(data.message);
        window.location.reload();
      } else {
        alert(data.error);
        btn.disabled = false;
        btn.innerHTML = '<i class="fa-solid fa-forward-fast me-1"></i>Accélérer';
      }
    } catch (error) {
      console.error("Erreur:", error);
      alert("Une erreur est survenue.");
      btn.disabled = false;
      btn.innerHTML = '<i class="fa-solid fa-forward-fast me-1"></i>Accélérer';
    }
  }

  async birthCreature(event) {
    const embryoId = event.currentTarget.dataset.embryoId;
    const embryoName = event.currentTarget.dataset.embryoName;

    if (!confirm(`Faire naître ${embryoName} ? La créature sera ajoutée au bestiaire.`)) {
      return;
    }

    const btn = event.currentTarget;
    const card = btn.closest('.col-md-4');
    const cardBody = btn.closest('.card-body');

    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Naissance en cours...';

    try {
      const response = await fetch("/science/birth_creature", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ embryo_id: embryoId })
      });

      const data = await response.json();

      if (data.success) {
        // Animation de naissance sur la carte
        const innerCard = card.querySelector('.card');
        innerCard.classList.add('birth-animation');

        // Remplacer le contenu par le message de succès
        cardBody.innerHTML = `
          <div class="birth-success-content">
            <div class="birth-emoji">🐣</div>
            <h5 class="text-success mt-2">${data.pet.name} est né !</h5>
            <p class="small text-light mb-2">${data.pet.race}</p>
            <a href="/pets/${data.pet.id}" class="btn btn-outline-success btn-sm">
              <i class="fa-solid fa-eye me-1"></i>Voir dans le bestiaire
            </a>
          </div>
        `;

        // Après un délai, faire disparaître la carte
        setTimeout(() => {
          card.style.transition = 'all 0.6s ease';
          card.style.opacity = '0';
          card.style.transform = 'scale(0.8)';

          setTimeout(() => {
            card.remove();

            // Si plus aucun embryon prêt, masquer la section entière
            const readySection = document.querySelector('.border-success');
            if (readySection) {
              const remainingCards = readySection.querySelectorAll('.col-md-4');
              if (remainingCards.length === 0) {
                readySection.closest('.row').style.transition = 'all 0.4s ease';
                readySection.closest('.row').style.opacity = '0';
                setTimeout(() => readySection.closest('.row')?.remove(), 400);
              } else {
                // Mettre à jour le compteur
                const header = readySection.querySelector('.card-header h5');
                if (header) {
                  header.innerHTML = `<i class="fa-solid fa-baby me-2"></i>Créatures prêtes à naître (${remainingCards.length})`;
                }
              }
            }
          }, 600);
        }, 3000);
      } else {
        alert(data.error);
        btn.disabled = false;
        btn.innerHTML = '<i class="fa-solid fa-baby me-1"></i>Faire naître !';
      }
    } catch (error) {
      console.error("Erreur:", error);
      alert("Une erreur est survenue.");
      btn.disabled = false;
      btn.innerHTML = '<i class="fa-solid fa-baby me-1"></i>Faire naître !';
    }
  }

  humanize(str) {
    if (!str) return "";
    return str.replace(/_/g, " ").replace(/^\w/, c => c.toUpperCase());
  }
}

