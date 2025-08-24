import { Controller } from "@hotwired/stimulus";
import $ from "cash-dom";
import * as R from "ramda";
import Validate from "../helpers/validator";
import { onModalHidden } from "../helpers/modals";
import * as bootstrap from "bootstrap";

// Connects to data-controller="alias"
export default class extends Controller {
  static outlets = ["aliases"];

  static targets = [
    "communityButton",
    "communitySection",
    "communityID",

    "serverButton",
    "serverSection",
    "serverID",

    "value",

    "communityPreviewSection",
    "communityPreviewBefore",
    "communityPreviewAfter",

    "serverPreviewSection",
    "serverPreviewBefore",
    "serverPreviewAfter",
  ];

  connect() {
    this.modal = this.element;

    this.validator = new Validate();
    this.#initializeValidator();

    // Prepare the new alias cards
    this.cards = {
      community: $(this.communityButtonTarget),
      server: $(this.serverButtonTarget),
    };

    this.selectedType = "community";
    this.#setActiveCard("community");

    // Prepare the previews
    this.previews = {
      community: {
        before: $(this.communityPreviewBeforeTarget),
        after: $(this.communityPreviewAfterTarget),
      },
      server: {
        before: $(this.serverPreviewBeforeTarget),
        after: $(this.serverPreviewAfterTarget),
      },
    };

    this.#renderPreview();

    // Prepare the modal
    onModalHidden(this.modal, () => this.#clearModal());
  }

  showSection(event) {
    const targetElem = $(event.currentTarget);
    const type = targetElem.data("type");

    this.selectedType = type;
    this.#setActiveCard(type);

    const communitySectionElem = $(this.communitySectionTarget);
    const serverSectionElem = $(this.serverSectionTarget);
    const communityPreviewElem = $(this.communityPreviewSectionTarget);
    const serverPreviewElem = $(this.serverPreviewSectionTarget);

    this.#renderPreview();

    if (this.selectedType === "server") {
      // Change the preview
      communityPreviewElem.hide();
      serverPreviewElem.show();

      // Toggle the sections
      communitySectionElem.hide();
      serverSectionElem.show();
    } else {
      // Change the preview
      communityPreviewElem.show();
      serverPreviewElem.hide();

      // Toggle the sections
      communitySectionElem.show();
      serverSectionElem.hide();
    }
  }

  onValueInput(_event) {
    this.#renderPreview();
  }

  onIDChanged(_event) {
    this.#renderPreview();
  }

  create(_event) {
    this.validator.validate().then((isValid) => {
      if (!isValid) return;

      let community = null;
      let server = null;

      if (this.selectedType === "server") {
        const [server_id, server_name] = $(this.serverIDTarget)
          .val()
          .split(":", 2);

        server = { server_id, server_name };
      } else {
        const [community_id, community_name] = $(this.communityIDTarget)
          .val()
          .split(":", 2);

        community = { community_id, community_name };
      }

      const id = crypto.randomUUID();
      const value = $(this.valueTarget).val();

      this.dispatch("create", {
        detail: { id, server, community, value: R.toLower(value) },
      });

      bootstrap.Modal.getOrCreateInstance(this.modal).hide();
    });
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////

  #initializeValidator() {
    this.validator
      .addField(this.valueTarget, [
        { rule: "required" },
        {
          validator: (value, _context) => {
            value = R.toLower(value);

            const exists =
              R.find(
                R.where({
                  value: R.equals(value),
                  type: R.equals(this.selectedType),
                })
              )(R.values(this.aliasesOutlet.aliases)) ?? false;

            return !exists;
          },
          errorMessage: "Alias already exists",
        },
      ])
      .addField(this.communityIDTarget, [
        {
          validator: (value, _context) => {
            if (this.selectedType !== "community") return true;

            return !R.isEmpty(value);
          },
          errorMessage: "Please select a community",
        },
      ])
      .addField(this.serverIDTarget, [
        {
          validator: (value, _context) => {
            if (this.selectedType !== "server") return true;

            return !R.isEmpty(value);
          },
          errorMessage: "Please select a server",
        },
      ]);
  }

  #clearModal() {
    $(this.valueTarget).val("");

    this.#clearSelection(this.communityIDTarget);
    this.#clearSelection(this.serverIDTarget);

    this.validator.clearAllErrors();
  }

  #clearSelection(selector) {
    this.dispatch("clearSelection", { target: $(selector)[0] });
  }

  #setActiveCard(id) {
    this.#resetCards();

    // Now select the one that was picked
    const selectedCard = this.cards[id];
    selectedCard.addClass("selected");

    const button = selectedCard.find("button");
    button.addClass("selected");
    button.html("SELECTED");
  }

  #resetCards() {
    R.values(this.cards).map((card, _) => {
      card.removeClass("selected");

      const button = card.find("button");
      button.removeClass("selected");
      button.html("Select");
    });
  }

  #renderPreview() {
    const previews = this.previews[this.selectedType];

    // Preview the selected server
    const beforeElem = previews.before;

    if (this.selectedType === "server") {
      const [server_id, _] = $(this.serverIDTarget).val().split(":", 2);

      beforeElem.html(server_id?.trim() || "&lt;server&gt;");
    } else {
      const [community_id, _] = $(this.communityIDTarget).val().split(":", 2);

      beforeElem.html(community_id?.trim() || "&lt;community&gt;");
    }

    // Preview the alias value
    const afterElem = previews.after;
    const value = $(this.valueTarget).val();

    if (R.isEmpty(value)) {
      afterElem.hide();
    } else {
      afterElem.show();
    }

    afterElem.html(value);
  }
}
