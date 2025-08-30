import ApplicationController from "./application_controller";
import $ from "../helpers/cash_dom";
import * as R from "ramda";
import CardSelector from "../helpers/card_selector";

// Connects to data-controller="route-new"
export default class extends ApplicationController {
  static targets = [
    "sourceAny",
    "sourceCustom",
    "presetEverything",
    "presetRaid",
    "presetMoney",
    "presetCustom",
  ];

  connect() {
    this.sourceCards = new CardSelector({
      any: $(this.sourceAnyTarget),
      custom: $(this.sourceCustomTarget),
    });

    this.presetCards = new CardSelector({
      everything: $(this.presetEverythingTarget),
      raid: $(this.presetRaidTarget),
      money: $(this.presetMoneyTarget),
      custom: $(this.presetCustomTarget),
    });

    this.sourceCards.select("any");
    this.presetCards.select("everything");
  }

  onSourceCardChanged(event) {
    const id = $(event.currentTarget).data("id");
    this.sourceCards.select(id);
  }

  onPresetCardChanged(event) {
    const id = $(event.currentTarget).data("id");
    this.presetCards.select(id);
  }
}
