import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "weaponSection", 
    "turretSection", 
    "specialEquipmentSection",
    "userCredits",
    "flashMessage"
  ];

  connect() {
    console.log("Ship improve controller connected");
    this.csrfToken = document.querySelector("[name='csrf-token']").content;
  }

  // Méthode générique pour les appels API
  async makeRequest(url, method = 'PATCH', body = null) {
    try {
      const response = await fetch(url, {
        method: method,
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken,
          'Accept': 'application/json'
        },
        ...(body && { body: JSON.stringify(body) })
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || 'Une erreur est survenue');
      }

      return await response.json();
    } catch (error) {
      this.showFlashMessage(error.message, 'danger');
      throw error;
    }
  }

  // Méthode pour afficher les messages flash
  showFlashMessage(message, type = 'success') {
    if (this.hasFlashMessageTarget) {
      this.flashMessageTarget.innerHTML = `
        <div class="alert alert-${type} alert-dismissible fade show" role="alert">
          ${message}
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      `;
    }
  }

  // Méthode pour mettre à jour les crédits de l'utilisateur
  updateUserCredits(newCredits) {
    if (this.hasUserCreditsTarget) {
      this.userCreditsTarget.textContent = newCredits;
    }
  }

  // Actions pour les armes
  async buyWeapon(event) {
    event.preventDefault();
    const form = event.target;
    const weaponName = form.querySelector('[name="weapon_name"]').value;
    
    try {
      const data = await this.makeRequest(form.action, 'PATCH', { weapon_name: weaponName });
      this.weaponSectionTarget.innerHTML = data.weapons_html;
      this.updateUserCredits(data.user_credits);
      this.showFlashMessage(data.message);
    } catch (error) {
      console.error('Erreur lors de l\'achat de l\'arme:', error);
    }
  }

  async installWeapon(event) {
    event.preventDefault();
    const form = event.target;
    const weaponId = form.querySelector('[name="weapon_id"]').value;
    const slot = form.querySelector('[name="slot"]').value;
    
    try {
      const data = await this.makeRequest(form.action, 'PATCH', { weapon_id: weaponId, slot: slot });
      this.weaponSectionTarget.innerHTML = data.weapons_html;
      this.showFlashMessage(data.message);
    } catch (error) {
      console.error('Erreur lors de l\'installation de l\'arme:', error);
    }
  }

  async uninstallWeapon(event) {
    event.preventDefault();
    const form = event.target;
    const slot = form.querySelector('[name="slot"]').value;
    
    try {
      const data = await this.makeRequest(form.action, 'PATCH', { slot: slot });
      this.weaponSectionTarget.innerHTML = data.weapons_html;
      this.showFlashMessage(data.message);
    } catch (error) {
      console.error('Erreur lors de la désinstallation de l\'arme:', error);
    }
  }

  async sellWeapon(event) {
    event.preventDefault();
    const form = event.target;
    const weaponId = form.querySelector('[name="weapon_id"]').value;
    
    try {
      const data = await this.makeRequest(form.action, 'PATCH', { weapon_id: weaponId });
      this.weaponSectionTarget.innerHTML = data.weapons_html;
      this.updateUserCredits(data.user_credits);
      this.showFlashMessage(data.message);
    } catch (error) {
      console.error('Erreur lors de la vente de l\'arme:', error);
    }
  }

  // Actions pour les tourelles
  async buyTurret(event) {
    event.preventDefault();
    const form = event.target;
    const turretName = form.querySelector('[name="turret_name"]').value;
    
    try {
      const data = await this.makeRequest(form.action, 'PATCH', { turret_name: turretName });
      this.turretSectionTarget.innerHTML = data.turrets_html;
      this.updateUserCredits(data.user_credits);
      this.showFlashMessage(data.message);
    } catch (error) {
      console.error('Erreur lors de l\'achat de la tourelle:', error);
    }
  }

  async installTurret(event) {
    event.preventDefault();
    const form = event.target;
    const turretId = form.querySelector('[name="turret_id"]').value;
    
    try {
      const data = await this.makeRequest(form.action, 'PATCH', { turret_id: turretId });
      this.turretSectionTarget.innerHTML = data.turrets_html;
      this.showFlashMessage(data.message);
    } catch (error) {
      console.error('Erreur lors de l\'installation de la tourelle:', error);
    }
  }

  async uninstallTurret(event) {
    event.preventDefault();
    const form = event.target;
    const turretId = form.querySelector('[name="turret_id"]').value;
    
    try {
      const data = await this.makeRequest(form.action, 'PATCH', { turret_id: turretId });
      this.turretSectionTarget.innerHTML = data.turrets_html;
      this.showFlashMessage(data.message);
    } catch (error) {
      console.error('Erreur lors de la désinstallation de la tourelle:', error);
    }
  }

  async sellTurret(event) {
    event.preventDefault();
    const form = event.target;
    const turretId = form.querySelector('[name="turret_id"]').value;
    
    try {
      const data = await this.makeRequest(form.action, 'PATCH', { turret_id: turretId });
      this.turretSectionTarget.innerHTML = data.turrets_html;
      this.updateUserCredits(data.user_credits);
      this.showFlashMessage(data.message);
    } catch (error) {
      console.error('Erreur lors de la vente de la tourelle:', error);
    }
  }

  // Actions pour les équipements spéciaux
  async buySpecialEquipment(event) {
    event.preventDefault();
    const form = event.target;
    const equipmentName = form.querySelector('[name="equipment_name"]').value;
    
    try {
      const data = await this.makeRequest(form.action, 'PATCH', { equipment_name: equipmentName });
      this.specialEquipmentSectionTarget.innerHTML = data.special_equipment_html;
      this.updateUserCredits(data.user_credits);
      this.showFlashMessage(data.message);
    } catch (error) {
      console.error('Erreur lors de l\'achat de l\'équipement:', error);
    }
  }

  async installSpecialEquipment(event) {
    event.preventDefault();
    const form = event.target;
    const equipmentId = form.querySelector('[name="equipment_id"]').value;
    
    try {
      const data = await this.makeRequest(form.action, 'PATCH', { equipment_id: equipmentId });
      this.specialEquipmentSectionTarget.innerHTML = data.special_equipment_html;
      this.showFlashMessage(data.message);
    } catch (error) {
      console.error('Erreur lors de l\'installation de l\'équipement:', error);
    }
  }

  async uninstallSpecialEquipment(event) {
    event.preventDefault();
    const form = event.target;
    const equipmentId = form.querySelector('[name="equipment_id"]').value;
    
    try {
      const data = await this.makeRequest(form.action, 'PATCH', { equipment_id: equipmentId });
      this.specialEquipmentSectionTarget.innerHTML = data.special_equipment_html;
      this.showFlashMessage(data.message);
    } catch (error) {
      console.error('Erreur lors de la désinstallation de l\'équipement:', error);
    }
  }

  async sellSpecialEquipment(event) {
    event.preventDefault();
    const form = event.target;
    const equipmentId = form.querySelector('[name="equipment_id"]').value;
    
    try {
      const data = await this.makeRequest(form.action, 'PATCH', { equipment_id: equipmentId });
      this.specialEquipmentSectionTarget.innerHTML = data.special_equipment_html;
      this.updateUserCredits(data.user_credits);
      this.showFlashMessage(data.message);
    } catch (error) {
      console.error('Erreur lors de la vente de l\'équipement:', error);
    }
  }
} 