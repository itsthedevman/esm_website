import { Controller } from "@hotwired/stimulus";

export default class ApplicationController extends Controller {
  nextTick(callback) {
    setTimeout(callback, 0);
  }
}
