import ApplicationController from "./application_controller";
import $ from "../helpers/cash_dom";
import Markdown from "../helpers/markdown";
import * as R from "ramda";

// Connects to data-controller="notification-new"
export default class extends ApplicationController {
  static targets = [
    "livePreview",
    "colorSelect",
    "colorPicker",
    "titleLength",
    "descriptionLength",
    "variableChips",
  ];

  static values = { variables: Object };

  connect() {
    this.preview = {
      color: $(this.colorSelectTarget).val(),
      title: "Preview title",
      description: "Preview message",
      footer: "[esm] Exile Server Manager",
    };

    this.#renderLivePreview();
  }

  onTypeChanged(event) {
    const typeElem = $(event.currentTarget);
    const notificationType = typeElem.val();

    this.#renderVariableChips(notificationType);
  }

  onTitleChanged(event) {
    const inputBox = $(event.currentTarget);
    const title = inputBox.val();

    this.preview.title = title || "Preview title";
    $(this.titleLengthTarget).html(title.length);

    this.#renderLivePreview();
  }

  onDescriptionChanged(event) {
    const inputBox = $(event.currentTarget);
    const description = inputBox.val();

    this.preview.description = description || "Preview message";
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
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

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
    const variables = this.#getVariablesForType(notificationType);

    const chipsHtml = R.pipe(
      R.toPairs,
      R.map(
        ([key, config]) =>
          `
            <button type="button"
              class="btn btn-outline-info btn-sm me-1 mb-1"
              data-action="click->notification-new#onVariableClicked"
              data-variable="${key}"
              title="${config.description}"
            >
              {{ ${key} }}
            </button>
          `
      ),
      R.join("")
    )(variables);

    $(this.variableChipsTarget).html(chipsHtml);
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

    if (notificationType === "marxet-item-sold") {
      return { ...variables, ...this.variablesValue.marxet };
    }

    if (R.includes(notificationType, ["won", "loss"])) {
      return { ...variables, ...this.variablesValue.gambling };
    }

    if (R.includes(notificationType, ["kill", "heal"])) {
      return { ...variables, ...this.variablesValue.player_actions };
    }

    if (R.includes(notificationType, ["money", "locker", "respect"])) {
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
        "base-raid",
        "flag-stolen",
        "flag-restored",
        "protection-money-due",
        "protection-money-paid",
        "charge-plant-started",
        "grind-started",
        "hack-started",
        "flag-steal-started",
      ],
      marxet: ["marxet-item-sold"],
      gambling: ["won", "loss"],
      player_actions: ["kill", "heal"],
      player_currency: ["money", "locker", "respect"],
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
      (str, [varName, value]) =>
        str.replace(new RegExp(`{{\\s*${varName}\\s*}}`, "gi"), value),
      string,
      R.toPairs(variables)
    );
  }
}
