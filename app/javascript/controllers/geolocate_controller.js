import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="geolocate"
export default class extends Controller {
  static targets = ["lat", "lng", "status", "button"]

  getPosition() {
    if (!("geolocation" in navigator)) {
      this.setStatus("Geolocalizzazione non supportata dal browser.", "error")
      return
    }

    this.setLoading(true)
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude, accuracy } = pos.coords
        this.latTarget.value = latitude
        this.lngTarget.value = longitude
        this.setStatus(`Posizione aggiornata ✓ (±${Math.round(accuracy)}m)`, "ok")
        this.setLoading(false)

        // 🔽 Invia subito il form associato
        this.element.closest("form")?.requestSubmit()
      },
      (err) => {
        let msg = "Impossibile ottenere la posizione."
        if (err.code === err.PERMISSION_DENIED) msg = "Permesso negato alla geolocalizzazione."
        if (err.code === err.POSITION_UNAVAILABLE) msg = "Posizione non disponibile."
        if (err.code === err.TIMEOUT) msg = "Timeout durante il rilevamento."
        this.setStatus(msg, "error")
        this.setLoading(false)
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 60000 }
    )

  }

  setLoading(loading) {
    if (!this.hasButtonTarget) return
    this.buttonTarget.disabled = loading
    this.buttonTarget.textContent = loading ? "Aggiorno…" : "Aggiorna posizione"
  }

  setStatus(text, state) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = text
    this.statusTarget.className =
      "text-xs " + (state === "ok" ? "text-emerald-700" :
                    state === "error" ? "text-red-700" :
                    "text-slate-600")
  }
}
