import ApplicationController from "./application_controller";
import * as R from "ramda";
import $ from "cash-dom";
import JustValidate from "just-validate";

// Connects to data-controller="server-new"
export default class extends ApplicationController {
  static targets = ["form", "v1Card", "v2Card", "version"];
  static values = { ids: Array };

  connect() {
    this.validator = new JustValidate(this.formTarget, {
      submitFormAutomatically: true,
    });

    this.cards = {
      1: $(this.v1CardTarget),
      2: $(this.v2CardTarget),
    };

    this.#initializeValidator();
    this.#setActiveCard(2);
  }

  onVersionSelected(event) {
    const version = $(event.currentTarget).data("version");
    this.#setActiveCard(version);
  }

  //////////////////////////////////////////////////////////////////////////////

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

  #setActiveCard(version) {
    this.#resetCards();
    this.#setVersion(version);

    // Now select the one that was picked
    const selectedCard = this.cards[version];
    selectedCard.addClass("selected");

    const button = selectedCard.find("button");
    button.html("SELECTED");
  }

  #resetCards() {
    R.values(this.cards).map((card, _) => {
      card.removeClass("selected");

      const button = card.find("button");
      const version = button.data("version");

      button.html(`Choose v${version}`);
    });
  }

  #setVersion(version) {
    $(this.versionTarget).val(version);
  }
}
