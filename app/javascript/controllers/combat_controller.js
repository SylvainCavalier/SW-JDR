import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["participantRow", "hp", "shield", "turnCounter"];

  updateEnemyStat(participantId, field, value) {
    fetch(`/combat/update_enemy_stat/${participantId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content },
      body: JSON.stringify({ [field]: value })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        let participantRow = this.participantRowTargets.find(row => row.dataset.participantId == participantId);
        if (participantRow) {
          if (field === "hp_current") participantRow.querySelector("[data-combat-target='hp']").textContent = data.hp_current;
          if (field === "shield_current") participantRow.querySelector("[data-combat-target='shield']").textContent = data.shield_current;
        }
      }
    })
    .catch(error => console.error("Erreur de mise à jour :", error));
  }

  updatePlayerStat(participantId, type, field, value) {
    fetch(`/combat/update_player_stat/${participantId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content },
      body: JSON.stringify({ [field]: value, type: type })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        let participantRow = this.participantRowTargets.find(row => row.dataset.participantId == participantId);
        if (participantRow) {
          if (field === "hp_current") participantRow.querySelector("[data-combat-target='hp']").textContent = data.hp_current;
          if (field === "shield_current") participantRow.querySelector("[data-combat-target='shield']").textContent = data.shield_current;
        }
      } else {
        console.error("Erreur:", data.error);
      }
    })
    .catch(error => console.error("Erreur de mise à jour :", error));
  }
  
  incrementHp(event) {
    let participantId = event.currentTarget.dataset.participantId;
    let participantType = event.currentTarget.dataset.participantType;
    let currentHp = parseInt(this.hpTargets.find(el => el.closest("tr").dataset.participantId == participantId).textContent, 10);
    
    if (participantType === "Enemy") {
      this.updateEnemyStat(participantId, "hp_current", currentHp + 1);
    } else {
      this.updatePlayerStat(participantId, participantType, "hp_current", currentHp + 1);
    }
  }
  
  decrementHp(event) {
    let participantId = event.currentTarget.dataset.participantId;
    let participantType = event.currentTarget.dataset.participantType;
    let currentHp = parseInt(this.hpTargets.find(el => el.closest("tr").dataset.participantId == participantId).textContent, 10);
    
    if (participantType === "Enemy") {
      this.updateEnemyStat(participantId, "hp_current", currentHp - 1);
    } else {
      this.updatePlayerStat(participantId, participantType, "hp_current", currentHp - 1);
    }
  }
  
  incrementShield(event) {
    let participantId = event.currentTarget.dataset.participantId;
    let participantType = event.currentTarget.dataset.participantType;
    let currentShield = parseInt(this.shieldTargets.find(el => el.closest("tr").dataset.participantId == participantId).textContent, 10);
    
    if (participantType === "Enemy") {
      this.updateEnemyStat(participantId, "shield_current", currentShield + 1);
    } else {
      this.updatePlayerStat(participantId, participantType, "shield_current", currentShield + 1);
    }
  }
  
  decrementShield(event) {
    let participantId = event.currentTarget.dataset.participantId;
    let participantType = event.currentTarget.dataset.participantType;
    let currentShield = parseInt(this.shieldTargets.find(el => el.closest("tr").dataset.participantId == participantId).textContent, 10);
    
    if (participantType === "Enemy") {
      this.updateEnemyStat(participantId, "shield_current", currentShield - 1);
    } else {
      this.updatePlayerStat(participantId, participantType, "shield_current", currentShield - 1);
    }
  }

  incrementTurn() {
    console.log("🟢 IncrementTurn déclenché");
    
    fetch("/combat/increment_turn", { 
      method: "PATCH", 
      headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content } 
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            console.log(`✅ Tour après mise à jour : ${data.turn}`);
            this.turnCounterTarget.innerText = data.turn;
        } else {
            console.error("🔴 Erreur serveur :", data.error);
        }
    })
    .catch(error => console.error("🔴 Erreur dans incrementTurn :", error));
  }

  decrementTurn() {
    console.log("🟢 DecrementTurn déclenché");

    fetch("/combat/decrement_turn", { 
      method: "PATCH", 
      headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content } 
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            console.log(`✅ Tour après mise à jour : ${data.turn}`);
            this.turnCounterTarget.innerText = data.turn;
        } else {
            console.error("🔴 Erreur serveur :", data.error);
        }
    })
    .catch(error => console.error("🔴 Erreur dans decrementTurn :", error));
  }

  updateStatus(event) {
    const participantId = event.target.dataset.participantId;
    const participantType = event.target.dataset.participantType;
    const statusId = event.target.value;

    fetch(`/combat/update_status`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({
        participant_id: participantId,
        participant_type: participantType,
        status_id: statusId
      })
    })
    .then(response => response.json())
    .then(data => {
      if (!data.success) {
        console.error('Erreur lors de la mise à jour du statut:', data.error);
      }
    })
    .catch(error => {
      console.error('Erreur:', error);
    });
  }
}