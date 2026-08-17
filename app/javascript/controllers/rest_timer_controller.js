import { Controller } from "@hotwired/stimulus"

// Rest countdown between sets.
//
// The deadline is stored in localStorage rather than held in memory, because
// the phone WILL be locked, backgrounded, or reloaded mid-rest. Time is
// computed from an absolute timestamp, so a suspended tab resumes with the
// correct remaining time instead of a frozen clock.
export default class extends Controller {
  static targets = ["display", "panel"]
  static values  = { sessionId: Number }

  connect() {
    this.tick = this.tick.bind(this)
    this.interval = setInterval(this.tick, 250)
    this.tick()
  }

  disconnect() { clearInterval(this.interval) }

  get storageKey() { return `fitfusion.rest.${this.sessionIdValue}` }

  start(event) {
    const seconds = parseInt(event.params.seconds, 10)
    if (!seconds) return
    localStorage.setItem(this.storageKey, String(Date.now() + seconds * 1000))
    this.tick()
  }

  dismiss() {
    localStorage.removeItem(this.storageKey)
    this.tick()
  }

  tick() {
    // The panel lives on the session runner. Guarding here means the
    // controller can be attached anywhere without throwing four times a second.
    if (!this.hasPanelTarget) return

    const deadline = parseInt(localStorage.getItem(this.storageKey) || "0", 10)
    const remaining = Math.ceil((deadline - Date.now()) / 1000)

    if (!deadline || remaining <= 0) {
      if (deadline) localStorage.removeItem(this.storageKey)
      this.panelTarget.hidden = true
      return
    }

    this.panelTarget.hidden = false
    if (!this.hasDisplayTarget) return
    const m = Math.floor(remaining / 60)
    const s = remaining % 60
    this.displayTarget.textContent = `${m}:${String(s).padStart(2, "0")}`
  }
}
