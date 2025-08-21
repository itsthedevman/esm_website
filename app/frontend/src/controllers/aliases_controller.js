import ApplicationController from "./application_controller";
import * as R from "ramda";
import $ from "../helpers/cash_dom";
import Validate from "../helpers/validator";
import * as bootstrap from "bootstrap";
import { Serializer } from "../helpers/forms";

// Connects to data-controller="aliases"
export default class extends ApplicationController {
  static targets = ["placeholder", "emptyState", "container", "count"];

  static values = { data: Object };

  connect() {
    this.addValidator = new Validate();
    this.editValidator = new Validate();
    this.serializer = new Serializer("form[data-aliases-target]", "aliases");

    this.#initializeValidators();

    this.aliases = R.clone(this.dataValue);
    this.#renderAliases();

    // Cash's #on method wasn't firing...
    $("#add_alias_modal")[0].addEventListener("hidden.bs.modal", (_event) =>
      this.#clearAddModal()
    );

    $("#edit_alias_modal")[0].addEventListener("hidden.bs.modal", (_event) =>
      this.#clearEditModal()
    );
  }

  create(_event) {
    this.addValidator.validate().then((isValid) => {
      if (!isValid) return;

      this.#renderAliases();

      bootstrap.Modal.getOrCreateInstance("#add_alias_modal").hide();
    });
  }

  edit(event) {
    bootstrap.Modal.getOrCreateInstance("#edit_alias_modal").show();
  }

  update(event) {
    this.editValidator.validate().then((isValid) => {
      if (!isValid) return;

      this.#renderAliases();

      bootstrap.Modal.getOrCreateInstance("#edit_alias_modal").hide();
    });
  }

  delete(event) {
    this.#renderAliases();
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

  #initializeValidators() {
    this.addValidator
      .addField("#add_alias_value", [{ rule: "required" }])
      .addField("#add_alias_community_id");

    this.editValidator.addField("#edit_alias_value", [{ rule: "required" }]);
  }

  #setMod({ id, name, version, link, required }) {
    this.mods[id] = { name, version, link, required };
  }

  #clearAddModal() {
    $("#add_alias_value").val("");
    $("#add_alias_community_id").val("");
    $("#add_alias_server_id").val("");

    this.addValidator.clearAllErrors();
  }

  #clearEditModal() {
    $("#edit_alias_value").val("");
    $("#edit_alias_community_id").val("");
    $("#edit_alias_server_id").val("");

    this.editValidator.clearAllErrors();
  }

  #createAliasCard(alias, id) {
    const isServer = alias.server !== null;
    const entity = isServer ? alias.server : alias.community;
    const badgeClass = isServer ? "bg-success" : "bg-primary";

    const iconClass = isServer
      ? "bi-server text-success"
      : "bi-discord text-primary";

    const entityName = isServer ? entity.server_name : entity.community_name;
    const entityId = isServer ? entity.server_id : entity.community_id;

    return `
    <div class="card bg-dark border-secondary">
      <div class="card-body">
        <div class="row align-items-center">
          <div class="col-2">
            <span class="badge fs-6 px-3 py-2 font-monospace text-wrap text-break ${badgeClass}">
              ${alias.value}
            </span>
          </div>
          <div class="col">
            <div class="d-flex align-items-center">
              <i class="bi ${iconClass} fs-4 me-3"></i>
              <div>
                <div class="text-light fw-medium">${entityName}</div>
                <small class="text-muted">${entityId}</small>
              </div>
            </div>
          </div>
          <div class="col-2">
            <div class="d-flex gap-1 justify-content-end">
              <button class="btn btn-outline-primary btn-sm"
                      type="button"
                      title="Edit alias"
                      data-action="click->aliases#edit"
                      data-alias-id="${id}">
                <i class="bi bi-pencil"></i>
              </button>
              <button class="btn btn-outline-danger btn-sm"
                      type="button"
                      title="Delete alias"
                      data-action="click->aliases#delete"
                      data-alias-id="${id}">
                <i class="bi bi-trash"></i>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;
  }

  #renderAliases() {
    const emptyStateElem = $(this.emptyStateTarget);
    const containerElem = $(this.containerTarget);
    const countElem = $(this.countTarget);

    const aliases = R.values(this.aliases);
    const length = aliases.length;

    // Write the mods to the form
    this.serializer.serialize(aliases);

    $(this.placeholderTarget).hide();

    if (length === 0) {
      emptyStateElem.show();
      containerElem.hide();
      countElem.text("0");
    } else {
      emptyStateElem.hide();
      containerElem.show().html("");
      countElem.text(length);

      R.forEachObjIndexed((alias, id) => {
        const card = this.#createAliasCard(alias, id);
        containerElem.append(card);
      }, this.aliases);
    }
  }
}
