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

  connect() {
    const enabledElem = $(this.element).find(
      "[name='command_configuration[enabled]']"
    );

    if (enabledElem[0]) {
      this.#toggleForm(enabledElem.is(":checked"));
    }
  }

  onEnableClicked(event) {
    const elem = $(event.currentTarget);

    this.#toggleForm(elem.is(":checked"));
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

  #toggleForm(enabled) {
    if (this.hasNotifyWhenDisabledTarget) {
      $(this.notifyWhenDisabledTarget).prop("disabled", !enabled);
    }

    if (this.hasAllowInTextChannelsTarget) {
      $(this.allowInTextChannelsTarget).prop("disabled", !enabled);
    }

    if (this.hasAllowlistEnabledTarget) {
      $(this.allowlistEnabledTarget).prop("disabled", !enabled);
    }

    if (this.hasCooldownQuantityTarget) {
      $(this.cooldownQuantityTarget).prop("disabled", !enabled);
    }

    if (this.hasCooldownTypeTarget) {
      $(this.cooldownTypeTarget).prop("disabled", !enabled);
    }

    if (this.hasAllowlistedRoleIdsTarget) {
      $(this.allowlistedRoleIdsTarget).prop("disabled", !enabled);

      this.dispatch("enableChanged", {
        detail: { enabled, targetId: this.idValue },
      });
    }
  }
}
