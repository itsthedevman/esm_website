import ApplicationController from "./application_controller";
import SlimSelect from "slim-select";

export default class extends ApplicationController {
  static targets = ["select"];
  static values = {
    data: Array,
    placeholder: String,
    searchText: String,
    allowDeselect: Boolean,
    closeOnSelect: Boolean,
    disabled: Boolean,
  };

  connect() {
    this.initializeSlimSelect();
    this.setupAttributeWatcher();
  }

  disconnect() {
    if (this.slimSelect) {
      this.slimSelect.destroy();
    }
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  initializeSlimSelect() {
    const selectElement = this.hasSelectTarget
      ? this.selectTarget
      : this.element;

    const config = {
      select: selectElement,
      data: this.dataValue || [],
      settings: {
        searchText: this.searchTextValue || "No results",
        searchPlaceholder: this.searchTextValue || "Search",
        closeOnSelect: this.closeOnSelectValue ?? true,
        allowDeselect: this.allowDeselectValue ?? false,
        placeholderText: this.placeholderValue || "Select value",
        showSearch: true,
        disabled: this.disabledValue || selectElement.disabled,
      },
      events: {
        afterChange: (newVal) => {
          // Update the underlying select element
          if (newVal && newVal.length > 0) {
            selectElement.value = newVal[0].value;
          } else {
            selectElement.value = "";
          }

          // Trigger change event for other listeners (including validation)
          this.nextTick(() => {
            selectElement.dispatchEvent(new Event("change", { bubbles: true }));
            selectElement.dispatchEvent(new Event("input", { bubbles: true }));

            // Also trigger blur to force immediate validation if configured
            selectElement.dispatchEvent(new Event("blur", { bubbles: true }));
          });
        },
      },
    };

    this.slimSelect = new SlimSelect(config);
  }

  setupAttributeWatcher() {
    const selectElement = this.hasSelectTarget
      ? this.selectTarget
      : this.element;

    // Watch for changes to disabled attribute
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.attributeName === "disabled") {
          this.handleDisabledChange();
        }
      });
    });

    this.observer.observe(selectElement, {
      attributes: true,
      attributeFilter: ["disabled"],
    });
  }

  handleDisabledChange() {
    const selectElement = this.hasSelectTarget
      ? this.selectTarget
      : this.element;
    const isDisabled = selectElement.disabled;

    if (this.slimSelect) {
      if (isDisabled) {
        this.slimSelect.disable();
      } else {
        this.slimSelect.enable();
      }
    }
  }
}
