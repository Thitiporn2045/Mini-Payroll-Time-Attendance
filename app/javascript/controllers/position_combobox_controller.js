import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["input", "panel", "option", "empty", "button"];

    connect() {
        this.boundOutsideClick = this.handleOutsideClick.bind(this);
        document.addEventListener("click", this.boundOutsideClick);
        this.filterOptions();
        this.close();
    }

    disconnect() {
        document.removeEventListener("click", this.boundOutsideClick);
    }

    open() {
        this.panelTarget.hidden = false;
        this.buttonTarget.setAttribute("aria-expanded", "true");
        this.filterOptions();
    }

    close() {
        if (!this.hasPanelTarget) return;

        this.panelTarget.hidden = true;
        this.buttonTarget.setAttribute("aria-expanded", "false");
    }

    toggle(event) {
        event.preventDefault();
        this.panelTarget.hidden ? this.open() : this.close();
        this.inputTarget.focus();
    }

    filter() {
        this.open();
        this.filterOptions();
    }

    select(event) {
        event.preventDefault();
        this.inputTarget.value = event.currentTarget.dataset.positionValue;
        this.filterOptions();
        this.close();
    }

    handleKeydown(event) {
        if (event.key === "Escape") {
            this.close();
            return;
        }

        if (event.key === "ArrowDown") {
            event.preventDefault();
            this.open();
            this.optionTargets.find((option) => !option.hidden)?.focus();
        }
    }

    handleOutsideClick(event) {
        if (!this.element.contains(event.target)) {
            this.close();
        }
    }

    filterOptions() {
        const query = this.inputTarget.value.trim().toLowerCase();
        let visibleCount = 0;

        this.optionTargets.forEach((option) => {
            const matches =
                query === "" ||
                option.dataset.positionValue.toLowerCase().includes(query);
            option.hidden = !matches;
            option.classList.toggle(
                "combobox-option-active",
                query !== "" &&
                    option.dataset.positionValue.toLowerCase() === query,
            );

            if (matches) visibleCount += 1;
        });

        if (this.hasEmptyTarget) {
            this.emptyTarget.hidden = visibleCount > 0;
        }
    }
}
