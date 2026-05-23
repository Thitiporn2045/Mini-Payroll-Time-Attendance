import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = [
        "timeFields",
        "statusInput",
        "statusOption",
        "checkIn",
        "checkOut",
    ];

    connect() {
        this.sync();
    }

    statusChanged() {
        this.sync();
    }

    sync() {
        this.syncStatusOptions();

        if (this.currentStatus() === "present") {
            this.timeFieldsTarget.classList.remove("hidden");
            this.timeFieldsTarget.hidden = false;

            if (this.checkInTarget.value === "") {
                this.checkInTarget.value = "09:00";
            }

            if (this.checkOutTarget.value === "") {
                this.checkOutTarget.value = "18:00";
            }
        } else {
            this.timeFieldsTarget.classList.add("hidden");
            this.timeFieldsTarget.hidden = true;
            this.checkInTarget.value = "";
            this.checkOutTarget.value = "";
        }
    }

    currentStatus() {
        const checked = this.statusInputTargets.find((input) => input.checked);
        return checked ? checked.value : "present";
    }

    syncStatusOptions() {
        const activeStatus = this.currentStatus();

        this.statusOptionTargets.forEach((option) => {
            const isActive = option.dataset.statusValue === activeStatus;

            option.classList.toggle("segmented-option-active", isActive);
            option.classList.toggle("segmented-option-inactive", !isActive);
        });
    }
}
