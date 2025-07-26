import { Controller } from "@hotwired/stimulus";
import JustValidate from "just-validate";
import { allowTurbo } from "../helpers/just_validate";
import $ from "cash-dom";

// Connects to data-controller="edit-community"
export default class extends Controller {
  static targets = ["form"];

  connect() {
    this.validator = new JustValidate(this.formTarget);

    this.#initializeValidator();
    allowTurbo(this.validator);
  }

  onWelcomeMessageToggleClick(event) {
    const toggleElem = $(event.currentTarget);
    const messageBoxElem = $("#community_welcome_message");

    messageBoxElem.prop("disabled", !toggleElem.is(":checked"));
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
