import { Controller } from "@hotwired/stimulus";
import SlimSelect from "slim-select";

export default class extends Controller {
  static targets = ["select"];
  static values = {
    placeholder: String,
    searchText: String,
    allowDeselect: Boolean,
    closeOnSelect: Boolean,
  };

  connect() {
    this.initializeSlimSelect();
  }

  disconnect() {
    if (this.slimSelect) {
      this.slimSelect.destroy();
    }
  }

  initializeSlimSelect() {
    const config = {
      select: this.hasSelectTarget ? this.selectTarget : this.element,
      settings: {
        searchText: this.searchTextValue || "Search...",
        searchPlaceholder: this.searchTextValue || "Search...",
        closeOnSelect: this.closeOnSelectValue ?? true,
        allowDeselect: this.allowDeselectValue ?? false,
        showSearch: true,
      },
    };

    // Add placeholder if provided
    if (this.placeholderValue) {
      config.settings.placeholderText = this.placeholderValue;
    }

    this.slimSelect = new SlimSelect(config);
  }

  // Helper method to get/set selected value if needed
  get selectedValue() {
    return this.slimSelect?.selected();
  }

  set selectedValue(value) {
    this.slimSelect?.setSelected(value);
  }
}
