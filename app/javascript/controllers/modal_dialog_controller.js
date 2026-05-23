import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["panel"];

    connect() {
        requestAnimationFrame(() => {
            this.element.classList.add("is-open");
            this.panelTarget.classList.add("is-open");
        });
    }

    backdropClicked(event) {
        if (event.target !== this.element) return;
        this.dismiss();
    }

    close(event) {
        event.preventDefault();
        this.dismiss();
    }

    dismiss() {
        this.element.classList.remove("is-open");
        this.panelTarget.classList.remove("is-open");

        window.setTimeout(() => {
            const frame = this.element.closest("turbo-frame");
            if (frame) frame.innerHTML = "";

            document.dispatchEvent(new CustomEvent("modal-dialog:closed"));
        }, 180);
    }
}
