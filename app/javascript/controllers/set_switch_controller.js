import { Controller } from "@hotwired/stimulus"

// Which set of the current exercise is expanded.
//
// All the exercise's sets stay on screen -- the ones you are not on collapse to
// a single line showing what was prescribed, or what you logged. The server
// renders that state and the chips are real links, so this works without
// JavaScript; the controller just avoids the round trip.
export default class extends Controller {
  static targets = ["set", "chip"]
  static values  = { open: String }

  connect() {
    if (!this.openValue) this.openValue = this.defaultKey()
    this.render()
  }

  // The first set with nothing logged against it; if the exercise is finished,
  // the last one, so a client correcting a number is not bounced elsewhere.
  defaultKey() {
    const pending = this.setTargets.find((s) => s.dataset.logged !== "true")
    const chosen  = pending || this.setTargets[this.setTargets.length - 1]
    return chosen ? chosen.dataset.key : ""
  }

  open(event) {
    const key = event.params.key
    if (key === undefined || key === null) return
    event.preventDefault()
    this.openValue = String(key)
  }

  openValueChanged() { this.render() }

  render() {
    this.setTargets.forEach((set) => {
      const isOpen = set.dataset.key === this.openValue
      const collapsed = set.querySelector("[data-collapsed]")
      const expanded  = set.querySelector("[data-expanded]")
      if (collapsed) collapsed.hidden = isOpen
      if (expanded)  expanded.hidden  = !isOpen
    })

    this.chipTargets.forEach((chip) => {
      const isOpen = chip.dataset.key === this.openValue
      chip.setAttribute("aria-current", isOpen ? "true" : "false")
      chip.classList.toggle("chip-open", isOpen)
    })
  }
}
