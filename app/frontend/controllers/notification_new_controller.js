import ApplicationController from "./application_controller";
import $ from "../helpers/cash_dom";
import Markdown from "../helpers/markdown";

// Connects to data-controller="notification-new"
export default class extends ApplicationController {
  static targets = ["colorSelect", "colorPicker", "livePreview"];

  connect() {
    this.preview = {
      color: $(this.colorSelectTarget).val(),
      title: "Preview title will appear here",
      description: "Preview message will appear here",
      footer: "[esm] Exile Server Manager",
    };

    this.#renderLivePreview();
  }

  onColorChanged(_event) {
    const selectedColor = $(this.colorSelectTarget).val();
    const colorPicker = $(this.colorPickerTarget);

    // Toggle the color picker
    if (selectedColor == "custom") {
      colorPicker.show();

      this.preview.color = colorPicker.val();
    } else {
      colorPicker.hide();

      this.preview.color = selectedColor;
    }

    this.#renderLivePreview();
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
}
