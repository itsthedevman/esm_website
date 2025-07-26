import { Controller } from "@hotwired/stimulus";
import JustValidate from "just-validate";

// Connects to data-controller="edit-community"
export default class extends Controller {
  static targets = ["form"];

  connect() {
    this.validator = new JustValidate(this.formTarget, {
      submitFormAutomatically: true,
    });

    this.#initializeValidator();
  }

  //////////////////////////////////////////////////////////////////////////////

  #initializeValidator() {
    this.validator
      .addField("#community_community_id", [
        { rule: "required" },
        { rule: "minLength", value: 2 },
      ])
      .addField("#community_welcome_message", [
        { rule: "maxLength", value: 1000 },
      ]);
  }
}
