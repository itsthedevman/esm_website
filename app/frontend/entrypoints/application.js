// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "../controllers"
import * as bootstrap from "bootstrap"

document.addEventListener("turbo:load", function() {
  bindToolTips();
  bindTurboModal();
});

function bindToolTips() {
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl)
  })
}

function bindTurboModal() {
    let elem = document.getElementById("turbo-modal");
    if (elem == null) return;

    // Remove the content once it is hidden
    elem.addEventListener("hidden.bs.modal", _event => {
        document.getElementById("turbo_modal").innerHTML = "";
    });
}
