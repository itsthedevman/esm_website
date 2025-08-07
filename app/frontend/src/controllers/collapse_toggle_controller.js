import ApplicationController from "./application_controller";

// Connects to data-controller="collapse-toggle"
export default class extends ApplicationController {
  static values = {
    defaultText: String,
    activeText: String,
  };

  connect() {
    // Set initial text and track state
    this.element.textContent = this.defaultTextValue;
    this.isExpanded = false;
  }

  toggle() {
    // Just flip the state and update text accordingly
    this.isExpanded = !this.isExpanded;

    this.element.textContent = this.isExpanded
      ? this.activeTextValue
      : this.defaultTextValue;
  }
}
