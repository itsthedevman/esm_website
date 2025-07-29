import { Controller } from "@hotwired/stimulus";
import * as R from "ramda";
import $ from "cash-dom";
import JustValidate from "just-validate";
import * as bootstrap from "bootstrap";

// Connects to data-controller="server-mods"
export default class extends Controller {
  static targets = [
    "addForm",
    "editForm",
    "emptyState",
    "modsList",
    "modCount",
  ];

  connect() {
    this.addValidator = new JustValidate(this.addFormTarget);
    this.editValidator = new JustValidate(this.editFormTarget);
    this.mods = {};

    this.#initializeModValidators();

    // Add Exile as a required default mod
    this.#setMod({
      id: crypto.randomUUID(),
      name: "@ExileMod",
      version: "1.0.4",
      link: "https://steamcommunity.com/workshop/filedetails/?id=1487484880",
      required: true,
    });

    this.#renderMods();
  }

  addMod(_event) {
    this.validators.addMod.revalidateField("#add_mod_name").then((isValid) => {
      if (!isValid) return;

      const nameElem = $("#add_mod_name");
      const versionElem = $("#add_mod_version");
      const linkElem = $("#add_mod_link");
      const requiredElem = $("#add_mod_required");

      this.#setMod({
        id: crypto.randomUUID(),
        name: nameElem.val(),
        version: versionElem.val(),
        link: linkElem.val(),
        required: requiredElem.is(":checked"),
      });

      this.#renderMods();

      bootstrap.Modal.getOrCreateInstance("#add_mod_modal").hide();

      // Reset the form
      nameElem.val("");
      versionElem.val("");
      linkElem.val("");
      requiredElem.prop("checked", false);
    });
  }

  editMod(event) {
    const id = $(event.currentTarget).data("modId");
    const mod = this.mods[id];

    $("#edit-mod-save").data("modId", id);
    $("#edit_mod_name").val(mod.name);
    $("#edit_mod_version").val(mod.version);
    $("#edit_mod_link").val(mod.link);
    $("#edit_mod_required").prop("checked", mod.required);

    bootstrap.Modal.getOrCreateInstance("#edit_mod_modal").show();
  }

  updateMod(event) {
    this.validators.editMod
      .revalidateField("#edit_mod_name")
      .then((isValid) => {
        if (!isValid) return;

        const id = $(event.currentTarget).data("modId");
        const nameElem = $("#edit_mod_name");
        const versionElem = $("#edit_mod_version");
        const linkElem = $("#edit_mod_link");
        const requiredElem = $("#edit_mod_required");
        const saveElem = $("#edit-mod-save");

        this.#setMod({
          id,
          name: nameElem.val(),
          version: versionElem.val(),
          link: linkElem.val(),
          required: requiredElem.is(":checked"),
        });

        this.#renderMods();

        bootstrap.Modal.getOrCreateInstance("#edit_mod_modal").hide();

        // Reset the form
        nameElem.val("");
        versionElem.val("");
        linkElem.val("");
        requiredElem.prop("checked", false);
        saveElem.data("modId", "");
      });
  }

  deleteMod(event) {
    const id = $(event.currentTarget).data("modId");
    delete this.mods[id];

    this.#renderMods();
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

  #initializeModValidators() {
    this.addValidator.addField("#add_mod_name", [{ rule: "required" }]);
    this.editValidator.addField("#edit_mod_name", [{ rule: "required" }]);
  }

  #setMod({ id, name, version, link, required }) {
    this.mods[id] = { name, version, link, required };
  }

  #createModCard(mod, id) {
    const requiredBadge = mod.required
      ? `<div class="position-absolute top-0 end-0 m-2"><span class="badge bg-warning text-dark">Required</span></div>`
      : "";

    const version = mod.version ? `Version: ${mod.version}` : "";

    const linkIcon = mod.link
      ? `<i class="bi bi-box-arrow-up-right text-muted ms-2"
        title="${mod.link}"
        style="font-size: 0.8rem;"></i>`
      : "";

    return `
      <div class="col-6">
        <div class="card bg-dark border-secondary h-100 position-relative">
          ${requiredBadge}
          <div class="card-body d-flex flex-column">
            <div class="flex-fill">
              <h6 class="card-title text-light d-flex align-items-center">
                <span>${mod.name}</span>
                ${linkIcon}
              </h6>
              <p class="card-text small text-muted mb-3">${version}</p>
            </div>

            <div class="d-flex gap-2 mt-auto">
              <button
                class="btn btn-outline-primary btn-sm flex-fill"
                type="button"
                data-action="click->server-edit#editMod"
                data-mod-id="${id}"
              >
                <i class="bi bi-pencil me-1"></i>Edit
              </button>
              <button
                class="btn btn-outline-danger btn-sm"
                type="button"
                data-action="click->server-edit#deleteMod"
                data-mod-id="${id}"
              >
                <i class="bi bi-trash"></i>
              </button>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  #renderMods() {
    const emptyStateElem = $(this.emptyStateTarget);
    const modsListElem = $(this.modsListTarget);
    const modCountElem = $(this.modCountTarget);
    const modLength = R.keys(this.mods).length;

    if (modLength === 0) {
      emptyStateElem.show();
      modsListElem.hide();
      modCountElem.text("0");
    } else {
      emptyStateElem.hide();
      modsListElem.show().html("");
      modCountElem.text(modLength);

      R.forEachObjIndexed((mod, id) => {
        const modCard = this.#createModCard(mod, id);
        modsListElem.append(modCard);
      }, this.mods);
    }
  }
}
