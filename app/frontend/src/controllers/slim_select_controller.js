import { Controller } from "@hotwired/stimulus";
import SlimSelect from "slim-select";

export default class extends Controller {
  static targets = ["select"];
  static values = {
    data: Array,
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
      data: this.dataValue || [],
      settings: {
        searchText: this.searchTextValue || "No results",
        searchPlaceholder: this.searchTextValue || "Search",
        closeOnSelect: this.closeOnSelectValue ?? true,
        allowDeselect: this.allowDeselectValue ?? false,
        placeholderText: this.placeholderValue || "Select value",
        showSearch: true,
      },
    };

    this.slimSelect = new SlimSelect(config);
  }
}
