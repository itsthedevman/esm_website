import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="edit-server"
export default class extends Controller {
  static targets = ["form"];

  connect() {}
}
