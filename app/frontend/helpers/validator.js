import $ from "cash-dom";
import * as R from "ramda";

class Validator {
  constructor() {
    this.fields = [];
    this.errors = {};
  }

  addField(selector, rules = []) {
    this.fields.push({ selector, rules });
    return this;
  }

  async validate() {
    this.errors = {};
    let isValid = true;

    for (const field of this.fields) {
      const el = $(field.selector)[0];
      if (!el) continue;

      const value = el.value;
      for (const ruleObj of field.rules) {
        let valid = true;
        let errorMsg = ruleObj.errorMessage || "Invalid value";

        if (ruleObj.rule === "required") {
          valid = R.trim(value) !== "";
          errorMsg = ruleObj.errorMessage || "This field is required";
        } else if (typeof ruleObj.validator === "function") {
          try {
            valid = await Promise.resolve(ruleObj.validator(value, el));
          } catch (e) {
            valid = false;
            errorMsg = e.message || errorMsg;
          }
        }

        if (!valid) {
          isValid = false;
          this.errors[field.selector] = errorMsg;
          break; // Stop at first error for this field
        }
      }
    }

    this.displayErrors();

    return isValid;
  }

  displayErrors() {
    for (const selector in this.errors) {
      const el = $(selector)[0];
      if (el) {
        // Remove any previous error message
        $(el).next(".validator-error").remove();
        // Insert new error message after the field
        $(el).after(
          `<div class="validator-error" style="color:red;">${this.errors[selector]}</div>`
        );
      }
    }
  }
}

export default Validator;
