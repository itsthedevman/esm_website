import ApplicationController from "./application_controller";
import $ from "../helpers/cash_dom";
import * as R from "ramda";
import CardSelector from "../helpers/card_selector";

// Connects to data-controller="route-new"
export default class extends ApplicationController {
  static targets = [
    "sourceAny",
    "sourceCustom",
    "sourceSelect",

    "presetEverything",
    "presetRaid",
    "presetMoney",
    "presetCustom",
    "typeSelect",

    "selectedServers",
    "selectedTypes",
    "selectedCommunity",
    "selectedChannel",

    "previewSelectedServers",
    "previewSelectedTypes",
    "previewTo",
  ];

  static presets = {
    everything: [
      "base-raid",
      "charge-plant-started",
      "custom",
      "flag-restored",
      "flag-steal-started",
      "flag-stolen",
      "grind-started",
      "hack-started",
      "marxet-item-sold",
      "protection-money-due",
      "protection-money-paid",
    ],
    raid: [
      "base-raid",
      "charge-plant-started",
      "flag-restored",
      "flag-steal-started",
      "flag-stolen",
      "grind-started",
      "hack-started",
    ],
    money: [
      "marxet-item-sold",
      "protection-money-due",
      "protection-money-paid",
    ],
    custom: [],
  };

  connect() {
    this.presets = R.clone(this.constructor.presets);

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

    this.selectedSource = "any";
    this.sourceCards.select("any");

    this.selectedPreset = "everything";
    this.presetCards.select("everything");

    this.#renderPreview();
  }

  onSelectedServerChanged(_event) {
    this.#renderPreview();
  }

  onSourceCardChanged(event) {
    const id = $(event.currentTarget).data("id");

    this.sourceCards.select(id);
    this.selectedSource = id;

    const selectElem = $(this.sourceSelectTarget);

    if (this.selectedSource == "custom") {
      selectElem.show();
    } else {
      selectElem.hide();
    }

    this.#renderPreview();
  }

  onPresetCardChanged(event) {
    const id = $(event.currentTarget).data("id");

    this.presetCards.select(id);
    this.selectedPreset = id;

    const selectElem = $(this.typeSelectTarget);

    if (this.selectedPreset == "custom") {
      selectElem.show();
    } else {
      selectElem.hide();
    }

    this.#renderPreview();
  }

  onCommunityChanged(_event) {
    this.#renderPreview();
  }

  onChannelChanged(_event) {
    this.#renderPreview();
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

  #renderPreview() {
    this.#renderPreviewServers();
    this.#renderPreviewCommunity();
    this.#renderPreviewTypes();
  }

  #renderPreviewServers() {
    const serversElem = $(this.previewSelectedServersTarget);

    if (this.selectedSource == "any") {
      serversElem.html(`<span class="badge bg-secondary">Any Server</span>`);
      return;
    }

    let html = $(this.selectedServersTarget)
      .val()
      .map((id) => id.split(":", 2)[0]) // Take only the server ID
      .map((label) => `<span class="badge bg-secondary">${label}</span>`)
      .join("");

    if (R.isEmpty(html)) {
      html = `<small class="text-muted">Waiting for selection...</small>`;
    }

    serversElem.html(html);
  }

  #renderPreviewCommunity() {
    const toElem = $(this.previewToTarget);

    const communityName = $(this.selectedCommunityTarget)
      .val()
      .split(":", 2)[1];

    if (R.isNil(communityName)) {
      toElem.html(`<small class="text-muted">Waiting for selection...</small>`);
      return;
    }

    let html = `
      <span class="badge bg-primary">${communityName}</span>
      <span class="text-muted mx-1">→</span>
    `;

    const channel = null;
    if (channel) {
      html += `<span class="badge bg-info">#${channel.name}</span>`;
    } else {
      html += `<small class="text-muted">Waiting for selection...</small>`;
    }

    toElem.html(html);
  }

  #renderPreviewTypes() {
    const typesElem = $(this.previewSelectedTypesTarget);
    const preset = this.presets[this.selectedPreset];

    if (R.isNotNil(preset)) {
      let values = preset
        .map((type) => this.#titleize(type))
        .map((label) => `<small>${label}</small>`)
        .join(`<span class="opacity-50">•</span>`);

      if (R.isEmpty(values)) {
        values = `<small class="text-muted">Waiting for selection...</small>`;
      }

      typesElem.html(values);
    }
  }

  #titleize(string) {
    return string
      .replace(/[-_]/g, " ")
      .split(" ")
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join(" ");
  }
}
