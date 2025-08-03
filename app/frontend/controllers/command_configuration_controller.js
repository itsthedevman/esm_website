import { Controller } from "@hotwired/stimulus";
import $ from "cash-dom";
import { isChecked } from "../helpers/forms";

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
    if (this.hasEnableTarget) {
      const commandEnabled = isChecked(this.enableTarget);

      // This will cause a race condition with the next toggle
      // Plus, the elements are already enabled by default
      if (!commandEnabled) {
        console.log("Toggling form");
        this.#toggleForm(commandEnabled);
      }

      if (commandEnabled && this.hasAllowlistEnabledTarget) {
        console.log("Toggling allowlist");
        this.#toggleAllowlist(isChecked(this.allowlistEnabledTarget));
      }
    }
  }

  onEnableClicked(event) {
    this.#toggleForm(isChecked(event.currentTarget));
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

  #toggleAllowlist(enabled) {
    if (!this.hasAllowlistedRoleIdsTarget) return;

    $(this.allowlistedRoleIdsTarget).prop("disabled", !enabled);

    console.log(`Dispatching enable changed to ${this.idValue} - ${enabled}`);
    this.dispatch("enableChanged", {
      detail: { enabled, targetId: this.idValue },
    });
  }

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

    this.#toggleAllowlist(enabled);
  }
}
