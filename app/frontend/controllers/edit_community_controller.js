import { Controller } from "@hotwired/stimulus";
import JustValidate from "just-validate";
import { allowTurbo } from "../helpers/just_validate";

// Connects to data-controller="edit-community"
export default class extends Controller {
  static targets = ["form"];

  connect() {
    this.validator = new JustValidate(this.formTarget);

    this.#initializeValidator();
    allowTurbo(this.validator);
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
