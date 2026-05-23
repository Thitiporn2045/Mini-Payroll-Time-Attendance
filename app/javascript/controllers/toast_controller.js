import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = { delay: { type: Number, default: 3200 } }

    connect() {
        requestAnimationFrame(() => {
        this.element.classList.add("toast-open")
        })

        this.timeout = window.setTimeout(() => {
        this.dismiss()
        }, this.delayValue)
    }

    disconnect() {
        this.clearTimeout()
    }

    close(event) {
        event?.preventDefault()
        this.dismiss()
    }

    dismiss() {
        this.clearTimeout()
        this.element.classList.remove("toast-open")
        window.setTimeout(() => {
        this.element.remove()
        }, 200)
    }

    clearTimeout() {
        if (this.timeout) {
        window.clearTimeout(this.timeout)
        this.timeout = null
        }
    }
}