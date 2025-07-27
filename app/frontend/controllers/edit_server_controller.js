import { Controller } from "@hotwired/stimulus";
import JustValidate from "just-validate";
import * as R from "ramda";
import { allowTurbo } from "../helpers/just_validate";

// Connects to data-controller="edit-server"
export default class extends Controller {
  static targets = ["form"];

  connect() {
    this.validator = new JustValidate(this.formTarget);

    this.#initializeValidator();
    allowTurbo(this.validator);
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

  #initializeValidator() {
    this.validator
      .addField("#server_server_id", [
        { rule: "required" },
        {
          rule: "customRegexp",
          value: /\S+/gi,
          errorMessage: "Server ID cannot contain whitespace",
        },
        {
          rule: "customRegexp",
          value: /\w+/gi,
          errorMessage: "Server ID cannot contain any symbols",
        },
        {
          validator: (value, _context) => {
            return !R.includes(value, this.idsValue);
          },
          errorMessage: "Server ID already exists",
        },
      ])
      .addField("#server_server_ip", [
        { rule: "required" },
        {
          rule: "customRegexp",
          value: /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/i,
          errorMessage: "Provide a valid public facing IPv4 address",
        },
      ])
      .addField("#server_server_port", [
        { rule: "required" },
        {
          rule: "customRegexp",
          value: /\d+/,
          errorMessage: "Provide a valid port",
        },
      ]);
  }
}
