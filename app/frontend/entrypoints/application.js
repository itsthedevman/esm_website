// Entry point for the build script in your package.json
import "@hotwired/turbo-rails";
import "../controllers";
import * as bootstrap from "bootstrap";
import $ from "cash-dom";

window.showTurboModal = function () {
  bootstrap.Modal.getOrCreateInstance($("#turbo-modal")[0]).show();
};

window.hideTurboModal = function () {
  bootstrap.Modal.getOrCreateInstance($("#turbo-modal")[0]).hide();
};

$(document).on("turbo:load", function () {
  bindToolTips();
  bindTurboModal();
});

function bindToolTips() {
  $('[data-bs-toggle="tooltip"]').each(function (i, el) {
    new bootstrap.Tooltip(el);
  });
}

function bindTurboModal() {
  let elem = $("#turbo-modal");
  if (elem.length === 0) return;

  // Remove the content once it is hidden
  elem.on("hidden.bs.modal", (_event) => {
    $("#turbo_modal").html("");
  });
}
