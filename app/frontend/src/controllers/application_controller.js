import { Controller } from "@hotwired/stimulus";
import $ from "../helpers/cash_dom";

export default class ApplicationController extends Controller {
  initialize() {
    this.abortController = new AbortController();
  }

  disconnect() {
    this.abortController.abort();
  }

  addEventListener(selector, event, callback) {
    $(selector)[0].addEventListener(event, callback, {
      signal: this.abortController.signal,
    });
  }

  nextTick(callback) {
    setTimeout(callback, 0);
  }
}
