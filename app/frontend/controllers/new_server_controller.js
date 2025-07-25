import { Controller } from "@hotwired/stimulus";
import * as R from "ramda";
import $ from "cash-dom";

// Connects to data-controller="new-server"
export default class extends Controller {
  static targets = ["v1Card", "v2Card", "version"];

  connect() {
    this.cards = {
      1: $(this.v1CardTarget),
      2: $(this.v2CardTarget),
    };

    this.setActiveCard(2);
  }

  onVersionSelected(event) {
    const version = event.params.version;
    this.setActiveCard(version);
  }

  setActiveCard(version) {
    this.#resetCards();
    this.#setVersion(version);

    // Now select the one that was picked
    const selectedCard = this.cards[version];
    selectedCard.addClass("selected");

    const button = selectedCard.find("button");
    button.html("SELECTED");
  }

  //////////////////////////////////////////////////////////////////////////////

  #resetCards() {
    R.values(this.cards).map((card, _) => {
      card.removeClass("selected");

      const button = card.find("button");
      const version = button.data("newServerVersionParam");

      button.html(`Choose v${version}`);
    });
  }

  #setVersion(version) {
    $(this.versionTarget).val(version);
  }
}
