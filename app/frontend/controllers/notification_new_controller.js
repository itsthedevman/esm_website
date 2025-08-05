import ApplicationController from "./application_controller";
import $ from "../helpers/cash_dom";

// Connects to data-controller="notification-new"
export default class extends ApplicationController {
  static targets = ["colorPicker"];

  connect() {}

  onColorChanged(event) {
    const value = $(event.currentTarget).val();

    if (value == "custom") {
      $(this.colorPickerTarget).show();
    } else {
      $(this.colorPickerTarget).hide();
    }
  }
}
