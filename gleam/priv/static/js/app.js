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

// Drag-and-drop with SortableJS
(function () {
  var sortables = [];

  function showDropzones() {
    var finished = document.getElementById("finished-dropzone");
    var cancelled = document.getElementById("cancelled-dropzone");
    if (finished) {
      finished.classList.remove("opacity-0", "pointer-events-none", "scale-75");
      finished.classList.add("opacity-100", "pointer-events-auto", "scale-100");
    }
    if (cancelled) {
      cancelled.classList.remove(
        "opacity-0",
        "pointer-events-none",
        "scale-75"
      );
      cancelled.classList.add(
        "opacity-100",
        "pointer-events-auto",
        "scale-100"
      );
    }
  }

  function hideDropzones() {
    var finished = document.getElementById("finished-dropzone");
    var cancelled = document.getElementById("cancelled-dropzone");
    if (finished) {
      finished.classList.add("opacity-0", "pointer-events-none", "scale-75");
      finished.classList.remove(
        "opacity-100",
        "pointer-events-auto",
        "scale-100"
      );
    }
    if (cancelled) {
      cancelled.classList.add("opacity-0", "pointer-events-none", "scale-75");
      cancelled.classList.remove(
        "opacity-100",
        "pointer-events-auto",
        "scale-100"
      );
    }
  }

  function showSuccessFeedback(dropzone, type) {
    var borderActive =
      type === "finished" ? "border-green-700" : "border-red-700";
    var bgActive = type === "finished" ? "bg-green-200" : "bg-red-200";
    var borderNormal =
      type === "finished" ? "border-green-400" : "border-red-400";
    var bgNormal = type === "finished" ? "bg-green-50" : "bg-red-50";

    dropzone.classList.remove(borderNormal, bgNormal);
    dropzone.classList.add(borderActive, bgActive);

    setTimeout(function () {
      dropzone.classList.remove(borderActive, bgActive);
      dropzone.classList.add(borderNormal, bgNormal);
    }, 400);
  }

  function initBoard() {
    // Clean up previous sortables
    sortables.forEach(function (s) {
      s.destroy();
    });
    sortables = [];

    var containers = document.querySelectorAll(".cards-container");
    containers.forEach(function (container) {
      var sortable = new Sortable(container, {
        group: "board-cards",
        animation: 150,
        draggable: "[data-card-id]",
        onStart: function () {
          showDropzones();
        },
        onEnd: function (evt) {
          hideDropzones();

          var cardId = evt.item.dataset.cardId;

          // Only handle moves within card containers (not dropzones)
          if (evt.to.closest(".cards-container")) {
            // Skip no-op drops (same list, same position)
            if (evt.from === evt.to && evt.oldIndex === evt.newIndex) {
              return;
            }
            var toListId = evt.to
              .closest("[data-list-id]")
              .dataset.listId;
            htmx.ajax(
              "POST",
              "/board/cards/" + cardId + "/move",
              {
                values: {
                  to_list_id: toListId,
                  target_index: evt.newIndex,
                },
              }
            );
          }
        },
      });
      sortables.push(sortable);
    });

    // Setup dropzones as SortableJS containers in the same group
    setupDropzone("finished-dropzone", "finish");
    setupDropzone("cancelled-dropzone", "cancel");
  }

  function setupDropzone(dropzoneId, action) {
    var dropzone = document.getElementById(dropzoneId);
    if (!dropzone) return;

    var sortable = new Sortable(dropzone, {
      group: "board-cards",
      onAdd: function (evt) {
        var cardId = evt.item.dataset.cardId;
        htmx.ajax("POST", "/board/cards/" + cardId + "/" + action);

        var type = dropzoneId.includes("finished") ? "finished" : "cancelled";
        showSuccessFeedback(dropzone, type);

        // Remove the card from dropzone visually
        evt.item.remove();
      },
    });
    sortables.push(sortable);
  }

  // Initialize on page load
  if (document.getElementById("board-container")) {
    initBoard();
  }

  // Re-initialize after HTMX swaps that replace the board
  htmx.on("htmx:afterSettle", function (event) {
    if (
      event.detail.elt.id === "board-container" ||
      event.detail.elt.querySelector("#board-container")
    ) {
      initBoard();
    }
  });
})();
