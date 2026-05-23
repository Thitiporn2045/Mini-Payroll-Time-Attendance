import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["panel"];
    static values = {
        closeUrl: String,
        open: { type: Boolean, default: false },
    };

    connect() {
        if (this.openValue) {
            this.element.classList.add("is-open");
            this.panelTarget.classList.add("is-open");
            return;
        }

        requestAnimationFrame(() => {
            this.element.classList.add("is-open");
            this.panelTarget.classList.add("is-open");
            this.openValue = true;
        });
    }

    backdropClicked(event) {
        if (event.target !== this.element) return;
        this.closeTo(this.closeUrlValue);
    }

    linkClose(event) {
        event.preventDefault();
        this.closeTo(event.currentTarget.href);
    }

    closeTo(url) {
        if (!url || !this.openValue) return;

        this.openValue = false;
        this.element.classList.remove("is-open");
        this.panelTarget.classList.remove("is-open");

        window.setTimeout(() => {
            if (window.Turbo) {
                window.Turbo.visit(url);
            } else {
                window.location.href = url;
            }
        }, 220);
    }
}
