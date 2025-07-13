import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notifications"
export default class extends Controller {
  static targets = ["toast"]

  connect() {
    setTimeout((toast) => {
      toast.hide();
    }, 7000, new bootstrap.Toast(this.toastTarget));
  }
}
