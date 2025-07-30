import $ from "cash-dom";

export function disableSubmitOnEnter() {
  $(document).on("keydown", "form", function (event) {
    return event.key != "Enter";
  });
}
