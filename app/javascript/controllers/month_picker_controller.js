import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["input"];

    openPicker(event) {
        if (!this.hasInputTarget || event.defaultPrevented) return;
        if (event.target instanceof Element && event.target.closest("a, button, select, textarea")) return;
        if (event.target === this.inputTarget) return;

        if (typeof this.inputTarget.showPicker === "function") {
            try {
                this.inputTarget.showPicker();
                return;
            } catch (_error) {
                // Fall back to focus when the browser blocks programmatic picker opening.
            }
        }

        this.inputTarget.focus({ preventScroll: true });
    }
}
