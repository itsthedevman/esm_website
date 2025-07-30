import { Controller } from "@hotwired/stimulus";
import * as R from "ramda";
import $ from "cash-dom";

// Connects to data-controller="server-rewards"
export default class extends Controller {
  static targets = ["emptyState", "itemContainer", "itemList", "itemCount"];

  connect() {
    this.items = {};
  }

  add(_event) {
    // These values are never stored in here since the form itself will collect this data
    // Since this is following a pattern, it is easier just to pretend this is functional lol
    this.items[crypto.randomUUID()] = { classname: "", quantity: 1 };
    this.#renderItems();
  }

  update(event) {
    const elem = $(event.currentTarget);

    const id = elem.data("id");
    if (R.isNil(id)) return;

    const item = this.items[id];
    if (R.isNil(item)) return;

    const field = elem.data("field");
    item[field] = elem.val();
  }

  remove(event) {
    const id = $(event.currentTarget).data("rewardId");
    delete this.items[id];

    this.#renderItems();
  }

  //////////////////////////////////////////////////////////////////////////////

  #createItemRow(item, id) {
    return `
      <tr>
        <td class="col-2">
          <input
            type="number"
            class="form-control form-control-sm"
            name="reward_items[][quantity]"
            placeholder="1"
            min="1"
            value="${item.quantity}"
            data-action="input->server-rewards#update"
            data-id="${id}"
            data-field="quantity"
          >
        </td>
        <td class="col-9">
          <input
          type="text"
          class="form-control form-control-sm font-monospace"
          name="reward_items[][class_name]"
          placeholder="Exile_Item_PowerDrink"
          value="${item.classname}"
          data-action="input->server-rewards#update"
          data-id="${id}"
          data-field="classname"
          required
        >
        </td>
        <td class="col">
          <button
            type="button"
            class="btn btn-outline-danger btn-sm w-100"
            data-action="click->server-rewards#remove"
            data-reward-id="${id}"
            title="Remove item"
          >
            <i class="bi bi-trash"></i>
          </button>
        </td>
      </tr>
    `;
  }

  #renderItems() {
    const containerElem = $(this.itemContainerTarget);
    const emptyStateElem = $(this.emptyStateTarget);
    const itemListElem = $(this.itemListTarget);
    const itemCountElem = $(this.itemCountTarget);
    const itemLength = R.keys(this.items).length;

    if (itemLength === 0) {
      emptyStateElem.show();
      containerElem.hide();
      itemListElem.hide();
      itemCountElem.text("0");
    } else {
      emptyStateElem.hide();
      containerElem.show();
      itemListElem.show().html("");
      itemCountElem.text(itemLength);

      R.forEachObjIndexed((item, id) => {
        const row = this.#createItemRow(item, id);
        itemListElem.append(row);
      }, this.items);
    }
  }
}
