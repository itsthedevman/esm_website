import { Controller } from "@hotwired/stimulus";
import * as R from "ramda";
import $ from "cash-dom";
import JustValidate from "just-validate";
import { allowTurbo } from "../helpers/just_validate";
import * as bootstrap from "bootstrap";

// Connects to data-controller="edit-server"
export default class extends Controller {
  static targets = ["form", "addModForm", "modsTable"];

  connect() {
    this.validator = new JustValidate(this.formTarget);
    this.mods = [];

    this.#initializeValidator();
    allowTurbo(this.validator);
  }

  onAddMod(event) {
    const nameElem = $("#add-mod-name");
    const versionElem = $("#add-mod-version");
    const linkElem = $("#add-mod-link");
    const requiredElem = $("#add-mod-required");

    this.mods.push({
      id: crypto.randomUUID(),
      name: nameElem.val(),
      version: versionElem.val(),
      link: linkElem.val(),
      required: requiredElem.is(":checked"),
    });

    this.#renderMods();

    bootstrap.Modal.getOrCreateInstance("#add-mod-modal").hide();

    // Reset the form
    nameElem.val("");
    versionElem.val("");
    linkElem.val("");
    requiredElem.prop("checked", false);

    console.log("Mods: ", this.mods);
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

  #initializeValidator() {
    this.validator
      .addField("#server_server_id", [
        { rule: "required" },
        {
          rule: "customRegexp",
          value: /\S+/gi,
          errorMessage: "Server ID cannot contain whitespace",
        },
        {
          rule: "customRegexp",
          value: /\w+/gi,
          errorMessage: "Server ID cannot contain any symbols",
        },
        {
          validator: (value, _context) => {
            return !R.includes(value, this.idsValue);
          },
          errorMessage: "Server ID already exists",
        },
      ])
      .addField("#server_server_ip", [
        { rule: "required" },
        {
          rule: "customRegexp",
          value: /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/i,
          errorMessage: "Provide a valid public facing IPv4 address",
        },
      ])
      .addField("#server_server_port", [
        { rule: "required" },
        {
          rule: "customRegexp",
          value: /\d+/,
          errorMessage: "Provide a valid port",
        },
      ]);
  }

  #renderMods() {
    const tbodyElem = $(this.modsTableTarget).find("tbody");

    tbodyElem.html("");

    this.mods.forEach((mod) => {
      const row = this.#createModRow(mod);
      tbodyElem.append(row);
    });
  }

  #createModRow(mod) {
    return `
      <tr>
        <td>${mod.name}</td>
        <td>${mod.version || "N/A"}</td>
        <td>
          ${
            mod.required ? '<span class="badge bg-warning">Required</span>' : ""
          }
        </td>
        <td>
          <button class="btn btn-sm btn-outline-primary"
                  data-action="click->edit-server#editMod"
                  data-mod-id="${mod.id}">Edit</button>
          <button class="btn btn-sm btn-outline-danger"
                  data-action="click->edit-server#deleteMod"
                  data-mod-id="${mod.id}">Delete</button>
        </td>
      </tr>
    `;
  }
}
