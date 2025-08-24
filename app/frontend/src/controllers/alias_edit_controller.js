import AliasController from "./alias_controller";
import $ from "cash-dom";
import * as R from "ramda";
import * as bootstrap from "bootstrap";

// Connects to data-controller="alias-edit"
export default class extends AliasController {
  connect() {
    super.connect();
    this.#initializeValidator();
  }

  edit({ detail: { alias } }) {
    this.alias = alias;

    this.selectedType = alias.server ? "server" : "community";
    this._setActiveCard();
    this._showSection(this.selectedType);

    $(this.valueTarget).val(alias.value);

    this.#setSelection(this.communityIDTarget, alias.community?.community_id);
    this.#setSelection(this.serverIDTarget, alias.server?.server_id);
  }

  update(event) {
    this.validator.validate().then((isValid) => {
      if (!isValid) return;

      bootstrap.Modal.getOrCreateInstance(this.modal).hide();
    });
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////

  #initializeValidator() {
    this.validator.addField(this.valueTarget, [
      { rule: "required" },
      { rule: "maxLength", value: 64 },
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
    ]);
  }

  #setSelection(target, value) {
    console.log("Dispatch to:", target);
    console.log("Value:", value);
    this.dispatch("setSelection", {
      target,
      detail: { value, validate: true },
    });
  }
}
