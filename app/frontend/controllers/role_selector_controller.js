import { Controller } from "@hotwired/stimulus";
import Choices from "choices.js";
import "choices.js/public/assets/styles/choices.css";

// Connects to data-controller="role-selector"
export default class extends Controller {
  connect() {
    const element = this.element;
    if (element.classList.contains("choices__input")) return;

    const rolesJSON = element.dataset.roles;
    if (rolesJSON == null || rolesJSON.length === 0) return;

    const roles = JSON.parse(rolesJSON);
    new Choices(
      element,
      {
        choices: roles,
        allowHTML: true,
        removeItemButton: true
      }
    );
  }
}
