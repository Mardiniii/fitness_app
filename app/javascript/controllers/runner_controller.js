import { Controller } from "@hotwired/stimulus"

// One exercise on screen at a time.
//
// The server already renders the right exercise open and the nav as real
// links, so the runner works with JavaScript switched off. This controller is
// enhancement only: it intercepts the nav so paging costs no round trip, which
// matters in a gym where the signal drops mid-set and the set forms are
// already in the document.
export default class extends Controller {
  static targets = ["panel", "counter"]

  connect() {
    this.index = this.startIndex()
    this.render()
  }

  // The fragment wins when there is one -- that is how the set-log redirect
  // points at the next exercise. Otherwise honour whichever panel the SERVER
  // left visible, rather than snapping back to the first one.
  startIndex() {
    const id = window.location.hash.replace(/^#/, "")
    if (id) {
      const found = this.panelTargets.findIndex((p) => p.id === id)
      if (found !== -1) return found
    }
    const open = this.panelTargets.findIndex((p) => !p.hidden)
    return open === -1 ? 0 : open
  }

  next(event) { this.move(event, this.index + 1) }
  prev(event) { this.move(event, this.index - 1) }

  move(event, i) {
    if (i < 0 || i >= this.panelTargets.length) return
    // Only swallow the click once we know we can handle it ourselves --
    // otherwise let the link do its job.
    if (event) event.preventDefault()
    this.index = i
    this.render()

    // replaceState, not a hash assignment: writing location.hash pushes a
    // history entry per exercise, so Back would walk the workout instead of
    // leaving it. ?ex= is kept so a reload lands in the same place.
    const id = this.panelTargets[i].id
    history.replaceState(null, "", `${window.location.pathname}?ex=${i}#${id}`)
    window.scrollTo({ top: 0, behavior: "auto" })
  }

  render() {
    this.panelTargets.forEach((panel, i) => { panel.hidden = i !== this.index })
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.index + 1} / ${this.panelTargets.length}`
    }
  }
}
