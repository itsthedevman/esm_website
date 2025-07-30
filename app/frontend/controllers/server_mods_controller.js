import { Controller } from "@hotwired/stimulus";
import * as R from "ramda";
import $ from "cash-dom";
import Validate from "../helpers/validator";
import * as bootstrap from "bootstrap";

// Connects to data-controller="server-mods"
export default class extends Controller {
  static targets = [
    "addForm",
    "editForm",
    "emptyState",
    "modsList",
    "modCount",
    "save",
  ];

  connect() {
    this.addValidator = new Validate();
    this.editValidator = new Validate();

    this.#initializeValidators();

    this.mods = R.pipe($, R.invoker(0, "val"), JSON.parse)(this.saveTarget);
    this.#renderMods();

    // Cash's #on method wasn't firing...
    $("#add_mod_modal")[0].addEventListener("hidden.bs.modal", (_event) =>
      this.#clearAddModal()
    );

    $("#edit_mod_modal")[0].addEventListener("hidden.bs.modal", (_event) =>
      this.#clearEditModal()
    );
  }

  create(_event) {
    this.addValidator.validate().then((isValid) => {
      if (!isValid) return;

      const id = crypto.randomUUID();
      const name = $("#add_mod_name").val();
      const version = $("#add_mod_version").val();
      const link = $("#add_mod_link").val();
      const required = $("#add_mod_required").is(":checked");

      this.#setMod({ id, name, version, link, required });
      this.#renderMods();

      bootstrap.Modal.getOrCreateInstance("#add_mod_modal").hide();
    });
  }

  edit(event) {
    const id = $(event.currentTarget).data("modId");
    const mod = this.mods[id];

    $("#edit_mod_save").data("modId", id);
    $("#edit_mod_name").val(mod.name);
    $("#edit_mod_version").val(mod.version);
    $("#edit_mod_link").val(mod.link);
    $("#edit_mod_required").prop("checked", mod.required);

    bootstrap.Modal.getOrCreateInstance("#edit_mod_modal").show();
  }

  update(event) {
    this.editValidator.validate().then((isValid) => {
      if (!isValid) return;

      const id = $(event.currentTarget).data("modId");
      const name = $("#edit_mod_name").val();
      const version = $("#edit_mod_version").val();
      const link = $("#edit_mod_link").val();
      const required = $("#edit_mod_required").is(":checked");

      this.#setMod({ id, name, version, link, required });
      this.#renderMods();

      bootstrap.Modal.getOrCreateInstance("#edit_mod_modal").hide();
    });
  }

  delete(event) {
    const id = $(event.currentTarget).data("modId");
    delete this.mods[id];

    this.#renderMods();
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

  #initializeValidators() {
    this.addValidator.addField("#add_mod_name", [{ rule: "required" }]);
    this.editValidator.addField("#edit_mod_name", [{ rule: "required" }]);
  }

  #setMod({ id, name, version, link, required }) {
    this.mods[id] = { name, version, link, required };
  }

  #clearAddModal() {
    $("#add_mod_name").val("");
    $("#add_mod_version").val("");
    $("#add_mod_link").val("");
    $("#add_mod_required").prop("checked", false);

    this.addValidator.clearAllErrors();
  }

  #clearEditModal() {
    $("#edit_mod_save").data("modId", "");
    $("#edit_mod_name").val("");
    $("#edit_mod_version").val("");
    $("#edit_mod_link").val("");
    $("#edit_mod_required").prop("checked", false);

    this.editValidator.clearAllErrors();
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
                data-action="click->server-mods#edit"
                data-mod-id="${id}"
              >
                <i class="bi bi-pencil me-1"></i>Edit
              </button>
              <button
                class="btn btn-outline-danger btn-sm"
                type="button"
                data-action="click->server-mods#delete"
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
    const saveElem = $(this.saveTarget);
    const modLength = R.keys(this.mods).length;

    if (modLength === 0) {
      emptyStateElem.show();
      modsListElem.hide();
      modCountElem.text("0");
      saveElem.val("");
    } else {
      emptyStateElem.hide();
      modsListElem.show().html("");
      modCountElem.text(modLength);
      saveElem.val(R.pipe(R.values, JSON.stringify)(this.mods));

      R.forEachObjIndexed((mod, id) => {
        const modCard = this.#createModCard(mod, id);
        modsListElem.append(modCard);
      }, this.mods);
    }
  }
}
