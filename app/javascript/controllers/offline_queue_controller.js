import { Controller } from "@hotwired/stimulus"

// Keeps a dropped set from being lost.
//
// Gym wifi fails mid-session far more often than it fails at load. When a set
// submission cannot reach the server, the payload is queued in localStorage
// and replayed when connectivity returns. Server-side writes are idempotent on
// (session, block exercise, set, segment), so replaying is safe even if the
// original request actually landed.
//
// Scope is deliberate: this survives a connection dropping mid-workout. It does
// not make the app usable when opened with no connection at all -- that needs a
// service worker precaching the session, which is a separate piece of work.
export default class extends Controller {
  static targets = ["banner", "count"]

  connect() {
    this.key = "fitfusion.pendingSets"
    this.flush = this.flush.bind(this)
    window.addEventListener("online", this.flush)
    this.render()
    if (navigator.onLine) this.flush()
  }

  disconnect() { window.removeEventListener("online", this.flush) }

  get queue() {
    try { return JSON.parse(localStorage.getItem(this.key) || "[]") } catch { return [] }
  }

  set queue(items) { localStorage.setItem(this.key, JSON.stringify(items)) }

  // Intercepts the set form only when the network is already known to be down;
  // otherwise Turbo handles it normally and the server response wins.
  async submit(event) {
    if (navigator.onLine) return

    event.preventDefault()
    const form = event.target.closest("form")
    const body = new URLSearchParams(new FormData(form)).toString()

    this.queue = [...this.queue, { url: form.action, body }]
    this.render()
    form.closest("[data-set-row]")?.classList.add("opacity-50")
  }

  async flush() {
    const items = this.queue
    if (items.length === 0) return

    const remaining = []
    for (const item of items) {
      try {
        const response = await fetch(item.url, {
          method: "POST",
          headers: { "Content-Type": "application/x-www-form-urlencoded", "Accept": "text/html" },
          body: item.body,
          credentials: "same-origin"
        })
        if (!response.ok) remaining.push(item)
      } catch {
        remaining.push(item)
      }
    }

    this.queue = remaining
    this.render()
    if (remaining.length === 0 && items.length > 0) window.location.reload()
  }

  render() {
    const pending = this.queue.length
    if (!this.hasBannerTarget) return
    this.bannerTarget.hidden = pending === 0
    if (this.hasCountTarget) this.countTarget.textContent = String(pending)
  }
}
