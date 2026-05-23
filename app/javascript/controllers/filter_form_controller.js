import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static values = { delay: { type: Number, default: 350 } };

    connect() {
        this.timeout = null;
    }

    disconnect() {
        this.clearTimeout();
    }

    submitNow(event) {
        if (event?.isComposing) return;
        this.clearTimeout();
        this.element.requestSubmit();
    }

    submitDebounced(event) {
        if (event?.isComposing) return;
        this.clearTimeout();
        this.timeout = setTimeout(() => {
            this.element.requestSubmit();
        }, this.delayValue);
    }

    clearTimeout() {
        if (this.timeout) {
            clearTimeout(this.timeout);
            this.timeout = null;
        }
    }
}
