import { Controller } from "@hotwired/stimulus"

// Click-to-load video embed.
//
// The iframe is never inserted until the user asks for it. On the library
// screen that is a privacy and page-weight win; on the gym screen it matters
// more, because a client on bad wifi should not pay for a YouTube player they
// did not open.
export default class extends Controller {
  static targets = ["poster", "frame"]
  static values  = { src: String }

  play() {
    const iframe = document.createElement("iframe")
    iframe.src = this.srcValue
    iframe.title = this.element.dataset.videoTitle || "video"
    iframe.loading = "lazy"
    iframe.allow = "accelerometer; autoplay; encrypted-media; picture-in-picture"
    iframe.allowFullscreen = true
    iframe.className = "absolute inset-0 h-full w-full"

    this.frameTarget.appendChild(iframe)
    this.posterTarget.remove()
  }
}
