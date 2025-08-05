import ApplicationController from "./application_controller";

// Connects to data-controller="notification-new"
export default class extends ApplicationController {
  static targets = ["colorPicker"];

  connect() {}

  onColorChanged(event) {

  }
}
