import { Controller } from "@hotwired/stimulus";
import $ from "cash-dom";

// Connects to data-controller="command-configuration"
export default class extends Controller {
  static targets = [
    "enable",
    "notifyWhenDisabled",
    "allowInTextChannels",
    "allowlistEnabled",
    "allowlistedRoleIds",
    "cooldownQuantity",
    "cooldownType",
  ];

  static values = { id: String };

  connect() {}

  onEnableClicked(event) {
    const elem = $(event.currentTarget);

    this.#toggleForm(elem.is(":checked"));
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

  #toggleForm(enabled) {
    $(this.notifyWhenDisabledTarget).prop("disabled", !enabled);
    $(this.allowInTextChannelsTarget).prop("disabled", !enabled);
    $(this.allowlistEnabledTarget).prop("disabled", !enabled);
    $(this.cooldownQuantityTarget).prop("disabled", !enabled);
    $(this.cooldownTypeTarget).prop("disabled", !enabled);

    $(this.allowlistedRoleIdsTarget)
      .children()
      .each((e) => $(e).prop("disabled", !enabled));

    this.dispatch("enableChanged", {
      detail: { enabled, targetId: this.idValue },
    });
  }
}
