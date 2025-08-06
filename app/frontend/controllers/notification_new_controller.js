import ApplicationController from "./application_controller";
import $ from "../helpers/cash_dom";
import Markdown from "../helpers/markdown";
import * as R from "ramda";

// Connects to data-controller="notification-new"
export default class extends ApplicationController {
  static targets = [
    "type",
    "title",
    "description",
    "livePreview",
    "colorSelect",
    "colorPicker",
    "titleLength",
    "descriptionLength",
    "variableChips",
  ];

  static values = { variables: Object };

  connect() {
    this.lastFocusedField = null;

    this.previewValues = this.#generatePreviewValues();

    this.preview = {
      color: $(this.colorSelectTarget).val(),
      title: "Preview title",
      description: "Preview message",
      footer: `[${this.previewValues.global.serverID}] ${this.previewValues.global.serverName}`,
    };

    this.#renderLivePreview();
    this.#bindFocusEvents();
    this.#renderVariableChips();
  }

  onTypeChanged(event) {
    const typeElem = $(event.currentTarget);
    const notificationType = typeElem.val();

    this.#renderVariableChips(notificationType);
  }

  onTitleChanged(event) {
    const inputBox = $(event.currentTarget);
    const title = inputBox.val();
    const type = $(this.typeTarget).val();

    this.preview.title = this.#replaceVariables(title, type) || "Preview title";

    $(this.titleLengthTarget).html(title.length);

    this.#renderLivePreview();
  }

  onDescriptionChanged(event) {
    const inputBox = $(event.currentTarget);
    const description = inputBox.val();
    const type = $(this.typeTarget).val();

    this.preview.description =
      this.#replaceVariables(description, type) || "Preview message";

    $(this.descriptionLengthTarget).html(description.length);

    this.#renderLivePreview();
  }

  onColorChanged(_event) {
    const selectedColor = $(this.colorSelectTarget).val();
    const colorPicker = $(this.colorPickerTarget);

    if (selectedColor == "custom") {
      colorPicker.show();

      this.preview.color = colorPicker.val();
    } else {
      colorPicker.hide();

      this.preview.color = selectedColor;
    }

    this.#renderLivePreview();
  }

  onVariableClicked(event) {
    const variable = $(event.currentTarget).data("variable");
    const variableText = `{{ ${variable} }}`;

    // Use last focused field, or default to description
    const targetElement =
      this.lastFocusedField || $("#notification_notification_description")[0];

    this.#insertAtCursor(targetElement, variableText);

    // Refocus the field so they can keep typing
    targetElement.focus();
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

  #generatePreviewValues() {
    return R.map(
      R.map(R.prop("placeholder")) // For each group, extract just the placeholders
    )(this.variablesValue);
  }

  #bindFocusEvents() {
    $(this.titleTarget).on("focus", (event) => {
      this.lastFocusedField = event.target;
    });

    $(this.descriptionTarget).on("focus", (event) => {
      this.lastFocusedField = event.target;
    });
  }

  #renderLivePreview() {
    const preview = $(this.livePreviewTarget);

    preview.find("#title").html(Markdown.toHTML(this.preview.title));

    preview
      .find("#description")
      .html(Markdown.toHTML(this.preview.description));

    preview.find("#footer").html(this.preview.footer);

    if (this.preview.color == "random") {
      preview.addClass("random");
    } else {
      preview.removeClass("random");
      preview.css("border-left-color", this.preview.color);
    }
  }

  #renderVariableChips(notificationType) {
    const chipsElem = $(this.variableChipsTarget);
    const cardElem = chipsElem.parents(".card").first();

    if (R.either(R.isNil, R.isEmpty)(notificationType)) {
      chipsElem.html("");
      cardElem.hide();
      return;
    }

    const variables = this.#getVariablesForType(notificationType);

    const chipsHtml = R.pipe(
      R.toPairs,
      R.sortBy(R.head),
      R.map(
        ([key, config]) =>
          `
            <button type="button"
              class="btn btn-outline-info btn-sm"
              data-action="click->${this.identifier}#onVariableClicked"
              data-variable="${key}"
              title="${config.description}"
            >
              {{ ${key} }}
            </button>
          `
      ),
      R.join("")
    )(variables);

    chipsElem.html(chipsHtml);
    cardElem.show();
  }

  #getVariablesForType(notificationType) {
    // Always include global variables
    let variables = { ...this.variablesValue.global };

    // Add type-specific ones
    if (
      R.test(
        /base-raid|flag-|protection-money|charge-plant|grind-|hack-/,
        notificationType
      )
    ) {
      return { ...variables, ...this.variablesValue.xm8 };
    }

    if (R.test(/marxet-item-sold/, notificationType)) {
      return { ...variables, ...this.variablesValue.marxet };
    }

    if (R.includes(notificationType, ["gambling_won", "gambling_loss"])) {
      return { ...variables, ...this.variablesValue.gambling };
    }

    if (R.includes(notificationType, ["player_kill", "player_heal"])) {
      return { ...variables, ...this.variablesValue.player_actions };
    }

    if (
      R.includes(notificationType, [
        "player_money",
        "player_locker",
        "player_respect",
      ])
    ) {
      return { ...variables, ...this.variablesValue.player_currency };
    }

    return variables;
  }

  #replaceVariables(string, notificationType) {
    // Start with global variables
    let variables = { ...this.previewValues.global };

    // Add type-specific variables
    const typeGroups = {
      xm8: [
        "xm8_base-raid",
        "xm8_charge-plant-started",
        "xm8_flag-restored",
        "xm8_flag-steal-started",
        "xm8_flag-stolen",
        "xm8_grind-started",
        "xm8_hack-started",
        "xm8_protection-money-due",
        "xm8_protection-money-paid",
      ],
      marxet: ["xm8_marxet-item-sold"],
      gambling: ["gambling_loss", "gambling_won"],
      player_actions: ["player_heal", "player_kill"],
      player_currency: ["player_locker", "player_money", "player_respect"],
    };

    // Find which group this notification type belongs to
    const groupName = R.find(
      (groupKey) => R.includes(notificationType, typeGroups[groupKey]),
      R.keys(typeGroups)
    );

    if (groupName) {
      variables = { ...variables, ...this.previewValues[groupName] };
    }

    // Replace all variables in one go
    return R.reduce(
      (str, [varName, value]) => {
        return str.replace(new RegExp(`{{\\s*${varName}\\s*}}`, "gi"), value);
      },
      string,
      R.toPairs(variables)
    );
  }

  // Insert text at cursor position
  #insertAtCursor(element, textToInsert) {
    const start = element.selectionStart;
    const end = element.selectionEnd;
    const value = element.value;

    // Insert the text
    element.value =
      value.substring(0, start) + textToInsert + value.substring(end);

    // Move cursor to end of inserted text
    const newCursorPos = start + textToInsert.length;
    element.setSelectionRange(newCursorPos, newCursorPos);

    // Trigger input event so your change handlers fire
    element.dispatchEvent(new Event("input", { bubbles: true }));
  }
}
