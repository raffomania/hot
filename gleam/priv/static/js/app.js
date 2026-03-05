// Focus management: auto-focus first input/textarea in newly loaded content
htmx.on("htmx:load", function (event) {
  const input = event.detail.elt.querySelector(
    "input:not([type=hidden]), textarea"
  );
  if (input) {
    input.focus();
  }
});

// Blur auto-saves for all edit fields; Ctrl+Enter submits textareas
document.addEventListener("focusin", function (event) {
  const el = event.target;
  if (el.tagName !== "INPUT" && el.tagName !== "TEXTAREA") return;
  const form = el.closest("[data-card-id] form");
  if (!form) return;
  if (el.type === "hidden") return;

  function submitForm() {
    if (form.dataset.submitted) return;
    form.dataset.submitted = "true";
    htmx.trigger(form, "submit");
  }

  if (el.tagName === "TEXTAREA") {
    el.addEventListener("keydown", function (e) {
      if ((e.ctrlKey || e.metaKey) && e.key === "Enter") {
        e.preventDefault();
        submitForm();
      }
    });
  }

  el.addEventListener("blur", function () {
    submitForm();
  });
});

// Keyboard shortcuts on focused cards
document.addEventListener("keydown", function (event) {
  const card = event.target.closest("[data-card-id]");
  if (!card) return;

  const cardId = card.dataset.cardId;

  if (event.shiftKey && event.key === "F") {
    event.preventDefault();
    htmx.ajax("POST", "/board/cards/" + cardId + "/finish", {
      target: card,
      swap: "delete",
    });
  }

  if (event.shiftKey && event.key === "C") {
    event.preventDefault();
    htmx.ajax("POST", "/board/cards/" + cardId + "/cancel", {
      target: card,
      swap: "delete",
    });
  }

  // Escape cancels edit by restoring display mode
  if (event.key === "Escape") {
    const form = card.querySelector("form");
    if (form) {
      event.preventDefault();
      htmx.ajax("GET", "/board/cards/" + cardId + "/edit?field=none", {
        target: card,
        swap: "outerHTML",
      });
    }
  }
});
