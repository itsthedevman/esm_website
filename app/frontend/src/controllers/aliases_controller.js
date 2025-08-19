import { Controller } from "@hotwired/stimulus";
import $ from "cash-dom";
import * as R from "ramda";

// Connects to data-controller="aliases"
export default class extends Controller {
  static targets = ["container", "placeholder"];

  static values = { data: Array };

  connect() {
    this.#renderAliases();
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

  #renderAlias(alias) {
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
                      data-alias-id="${alias.public_id}">
                <i class="bi bi-pencil"></i>
              </button>
              <button class="btn btn-outline-danger btn-sm"
                      type="button"
                      title="Delete alias"
                      data-action="click->aliases#delete"
                      data-alias-id="${alias.public_id}">
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
    const aliasesHtml = this.dataValue
      .map((alias) => this.#renderAlias(alias))
      .join("");

    $(this.containerTarget).html(aliasesHtml).show();
    $(this.placeholderTarget).hide();
  }
}
