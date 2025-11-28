import { Controller } from "@hotwired/stimulus"

// Controller pour afficher le graphique en camembert des parts de marché
export default class extends Controller {
  static targets = ["canvas"]
  static values = { data: Array }

  connect() {
    this.drawChart()
  }

  drawChart() {
    const canvas = this.canvasTarget
    const ctx = canvas.getContext("2d")
    const data = this.dataValue

    // Configuration du canvas
    const size = 200
    canvas.width = size
    canvas.height = size
    const centerX = size / 2
    const centerY = size / 2
    const radius = size / 2 - 10

    // Calculer le total
    const total = data.reduce((sum, item) => sum + parseFloat(item.share), 0)

    // Dessiner les segments
    let currentAngle = -Math.PI / 2 // Commencer en haut

    data.forEach((item) => {
      const sliceAngle = (parseFloat(item.share) / total) * 2 * Math.PI

      // Dessiner le segment
      ctx.beginPath()
      ctx.moveTo(centerX, centerY)
      ctx.arc(centerX, centerY, radius, currentAngle, currentAngle + sliceAngle)
      ctx.closePath()

      ctx.fillStyle = item.color
      ctx.fill()

      // Bordure du segment
      ctx.strokeStyle = "rgba(255, 255, 255, 0.2)"
      ctx.lineWidth = 2
      ctx.stroke()

      currentAngle += sliceAngle
    })

    // Cercle central pour effet "donut"
    ctx.beginPath()
    ctx.arc(centerX, centerY, radius * 0.5, 0, 2 * Math.PI)
    ctx.fillStyle = "#1a1a2e"
    ctx.fill()
    ctx.strokeStyle = "rgba(255, 255, 255, 0.1)"
    ctx.lineWidth = 2
    ctx.stroke()

    // Icône au centre
    ctx.font = "30px Arial"
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"
    ctx.fillText("🪶", centerX, centerY)
  }

  dataValueChanged() {
    this.drawChart()
  }
}

