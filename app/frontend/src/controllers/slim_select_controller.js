import { Controller } from "@hotwired/stimulus";
import SlimSelect from "slim-select";
import $ from "../helpers/cash_dom";

export default class extends Controller {
  static targets = ["select"];
  static values = {
    data: Array,
    placeholder: String,
    searchText: String,
    allowDeselect: Boolean,
    closeOnSelect: Boolean,
    disabled: Boolean,
  };

  connect() {
    this.hasBeenValidated = false; // Track if user has interacted with field
    this.initializeSlimSelect();
    this.setupValidationIntegration();
    this.setupAttributeWatcher();
  }

  disconnect() {
    if (this.slimSelect) {
      this.slimSelect.destroy();
    }
    if (this.observer) {
      this.observer.disconnect();
    }
    if (this.validationObserver) {
      this.validationObserver.disconnect();
    }
  }

  initializeSlimSelect() {
    const selectElement = this.hasSelectTarget
      ? this.selectTarget
      : this.element;

    const config = {
      select: selectElement,
      data: this.dataValue || [],
      settings: {
        searchText: this.searchTextValue || "No results",
        searchPlaceholder: this.searchTextValue || "Search",
        closeOnSelect: this.closeOnSelectValue ?? true,
        allowDeselect: this.allowDeselectValue ?? false,
        placeholderText: this.placeholderValue || "Select value",
        showSearch: true,
        disabled: this.disabledValue || selectElement.disabled,
      },
      events: {
        afterChange: (newVal) => {
          console.log("🎉 afterChange fired!", newVal);
          this.hasBeenValidated = true;

          if (newVal.length > 0) {
            selectElement.value = newVal[0].value;
          } else {
            selectElement.value = "";
          }

          // Trigger change event for other listeners (including validation)
          selectElement.dispatchEvent(new Event("change", { bubbles: true }));
          selectElement.dispatchEvent(new Event("input", { bubbles: true }));

          // Trigger immediate validation - but give DOM a moment to settle
          this.nextTick(() => {
            selectElement.dispatchEvent(
              new CustomEvent("validation:trigger", {
                bubbles: true,
              })
            );
          });
        },
      },
    };

    this.slimSelect = new SlimSelect(config);

    // Move the error message to appear after SlimSelect UI
    this.nextTick(() => this.repositionErrorMessage());
  }

  setupValidationIntegration() {
    const selectElement = this.hasSelectTarget
      ? this.selectTarget
      : this.element;

    // Listen for validation events
    selectElement.addEventListener("invalid", this.handleInvalid.bind(this));
    selectElement.addEventListener("input", this.handleInput.bind(this));

    // Watch for class changes from your Validator
    this.validationObserver = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.attributeName === "class") {
          this.syncValidationFromOriginalSelect();
        }
      });
    });

    this.validationObserver.observe(selectElement, {
      attributes: true,
      attributeFilter: ["class"],
    });

    // Don't sync validation state on connect - wait for user interaction
  }

  setupAttributeWatcher() {
    const selectElement = this.hasSelectTarget
      ? this.selectTarget
      : this.element;

    // Watch for changes to disabled, required, etc.
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.attributeName === "disabled") {
          this.handleDisabledChange();
        } else if (mutation.attributeName === "required") {
          this.syncValidationState();
        }
      });
    });

    this.observer.observe(selectElement, {
      attributes: true,
      attributeFilter: ["disabled", "required"],
    });
  }

  handleInput() {
    this.hasBeenValidated = true; // Mark as touched
    this.syncValidationState();
  }

  handleInvalid(event) {
    // Prevent browser validation popup
    event.preventDefault();
    this.hasBeenValidated = true; // Mark as touched
    this.syncValidationState();
  }

  handleDisabledChange() {
    const selectElement = this.hasSelectTarget
      ? this.selectTarget
      : this.element;
    const isDisabled = selectElement.disabled;

    if (this.slimSelect) {
      if (isDisabled) {
        this.slimSelect.disable();
      } else {
        this.slimSelect.enable();
      }
    }
  }

  syncValidationState() {
    const selectElement = this.hasSelectTarget
      ? this.selectTarget
      : this.element;
    const slimSelectMain = $(selectElement).siblings(".ss-main")[0];
    const feedbackElement = this.getErrorElement();

    if (!slimSelectMain) return;

    const $slimSelectMain = $(slimSelectMain);

    // Clear existing validation classes first
    $slimSelectMain.removeClass("is-invalid is-valid");

    // Only apply validation styling if the field has been interacted with
    if (this.hasBeenValidated) {
      // Don't show valid state for empty required fields
      const isEmpty = !selectElement.value || selectElement.value === "";
      const isRequired = selectElement.hasAttribute("required");

      if (selectElement.validity.valid && !(isEmpty && isRequired)) {
        $slimSelectMain.addClass("is-valid");
        if (feedbackElement) $(feedbackElement).hide();
      } else {
        $slimSelectMain.addClass("is-invalid");
        if (feedbackElement) $(feedbackElement).show();
      }
    }
  }

  syncValidationFromOriginalSelect() {
    const selectElement = this.hasSelectTarget
      ? this.selectTarget
      : this.element;
    const slimSelectMain = $(selectElement).siblings(".ss-main")[0];
    const feedbackElement = this.getErrorElement();

    if (!slimSelectMain) return;

    const $slimSelectMain = $(slimSelectMain);

    // Mirror the validation classes from original select to SlimSelect UI
    if ($(selectElement).hasClass("is-invalid")) {
      $slimSelectMain.removeClass("is-valid").addClass("is-invalid");
      if (feedbackElement) $(feedbackElement).show();
    } else if ($(selectElement).hasClass("is-valid")) {
      $slimSelectMain.removeClass("is-invalid").addClass("is-valid");
      if (feedbackElement) $(feedbackElement).hide();
    } else {
      $slimSelectMain.removeClass("is-invalid is-valid");
      if (feedbackElement) $(feedbackElement).hide();
    }
  }

  repositionErrorMessage() {
    const selectElement = this.hasSelectTarget
      ? this.selectTarget
      : this.element;
    const slimSelectMain = $(selectElement).siblings(".ss-main")[0];
    const originalFeedback = $(selectElement).siblings(".invalid-feedback")[0];

    if (originalFeedback && slimSelectMain) {
      // Only move if it's not already in the right place
      const currentNext = $(slimSelectMain).next(".invalid-feedback")[0];
      if (currentNext !== originalFeedback) {
        $(originalFeedback).insertAfter(slimSelectMain);
      }
    }
  }

  getErrorElement() {
    const selectElement = this.hasSelectTarget
      ? this.selectTarget
      : this.element;
    const slimSelectMain = $(selectElement).siblings(".ss-main")[0];

    if (slimSelectMain) {
      // Look for error message after SlimSelect UI first
      return (
        $(slimSelectMain).siblings(".invalid-feedback")[0] ||
        $(selectElement).siblings(".invalid-feedback")[0]
      );
    }

    return $(selectElement).siblings(".invalid-feedback")[0];
  }

  // Public method to enable/disable from other controllers
  enable() {
    const selectElement = this.hasSelectTarget
      ? this.selectTarget
      : this.element;
    $(selectElement).prop("disabled", false);
    if (this.slimSelect) {
      this.slimSelect.enable();
    }
  }

  disable() {
    const selectElement = this.hasSelectTarget
      ? this.selectTarget
      : this.element;
    $(selectElement).prop("disabled", true);
    if (this.slimSelect) {
      this.slimSelect.disable();
    }
  }

  // Helper method for timing issues
  nextTick(callback) {
    setTimeout(callback, 0);
  }
}
