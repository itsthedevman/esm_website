import { Controller } from "@hotwired/stimulus";
import $ from "cash-dom";
import * as R from "ramda";
import Validate from "../helpers/validator";
import { onModalHidden } from "../helpers/modals";

// Connects to data-controller="alias"
export default class extends Controller {
  static targets = [
    "communityButton",
    "communitySection",
    "communityID",

    "serverButton",
    "serverSection",
    "serverID",

    "value",

    "communityPreviewSection",
    "communityPreview",

    "serverPreviewSection",
    "serverPreview",
  ];

  connect() {
    console.log("Connected");
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
      community: $(this.communityPreviewTarget),
      server: $(this.serverPreviewTarget),
    };

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
      const value = $("#add_alias_value").val();

      this.#setAlias({ id, server, community, value });

      bootstrap.Modal.getOrCreateInstance(this.modal).hide();
    });
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

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
              )(R.values(this.aliases)) ?? false;

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

  #setAlias({ id, server, community, value }) {
    this.aliases[id] = { id, server, community, value: R.toLower(value) };
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
}
