// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"
// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import Sortable from "../vendor/sortable.js";

let Hooks = {};

// Global variable to track dragging state
let isDragging = false;

// Base dropzone behavior shared between finished and cancelled dropzones
const BaseDropzone = {
    mounted() {
        this.dropzone = this.el;
        this.dropzoneType = this.el.id.includes("finished")
            ? "finished"
            : "cancelled";
    },

    showDropzone() {
        this.dropzone.classList.remove("opacity-0", "pointer-events-none");
        this.dropzone.classList.add("opacity-100", "pointer-events-auto");
    },

    hideDropzone() {
        this.dropzone.classList.add("opacity-0", "pointer-events-none");
        this.deactivateDropzone();
    },

    handleDropzoneEnter() {
        if (isDragging) {
            this.activateDropzone();
        }
    },

    handleDropzoneLeave() {
        this.deactivateDropzone();
    },
};

Hooks.FinishedDropzone = Object.assign({}, BaseDropzone, {
    activateDropzone() {
        this.dropzone.classList.add(
            "border-green-600",
            "bg-green-100",
            "scale-100"
        );
        this.dropzone.classList.remove(
            "border-green-400",
            "bg-green-50",
            "scale-75"
        );
    },

    deactivateDropzone() {
        this.dropzone.classList.remove(
            "border-green-600",
            "bg-green-100",
            "scale-100"
        );
        this.dropzone.classList.add(
            "border-green-400",
            "bg-green-50",
            "scale-75"
        );
    },

    showSuccessFeedback() {
        const originalContent = this.dropzone.innerHTML;
        this.dropzone.innerHTML = `
            <svg class="w-6 h-6 sm:w-7 sm:h-7 md:w-8 md:h-8 text-green-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
            <span class="text-xs sm:text-sm font-medium text-green-700 mt-1">Finished!</span>
        `;

        this.dropzone.classList.remove("border-green-400", "bg-green-50");
        this.dropzone.classList.add("border-green-700", "bg-green-200");

        setTimeout(() => {
            this.dropzone.innerHTML = originalContent;
            this.dropzone.classList.remove("border-green-700", "bg-green-200");
            this.dropzone.classList.add("border-green-400", "bg-green-50");
        }, 1500);
    },
});

Hooks.CancelledDropzone = Object.assign({}, BaseDropzone, {
    activateDropzone() {
        this.dropzone.classList.add(
            "border-red-600",
            "bg-red-100",
            "scale-100"
        );
        this.dropzone.classList.remove(
            "border-red-400",
            "bg-red-50",
            "scale-75"
        );
    },

    deactivateDropzone() {
        this.dropzone.classList.remove(
            "border-red-600",
            "bg-red-100",
            "scale-100"
        );
        this.dropzone.classList.add("border-red-400", "bg-red-50", "scale-75");
    },

    showSuccessFeedback() {
        const originalContent = this.dropzone.innerHTML;
        this.dropzone.innerHTML = `
            <svg class="w-6 h-6 sm:w-7 sm:h-7 md:w-8 md:h-8 text-red-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
            <span class="text-xs sm:text-sm font-medium text-red-700 mt-1">Cancelled!</span>
        `;

        this.dropzone.classList.remove("border-red-400", "bg-red-50");
        this.dropzone.classList.add("border-red-700", "bg-red-200");

        setTimeout(() => {
            this.dropzone.innerHTML = originalContent;
            this.dropzone.classList.remove("border-red-700", "bg-red-200");
            this.dropzone.classList.add("border-red-400", "bg-red-50");
        }, 1500);
    },
});

// Global keyboard handler for dropzone shortcuts
Hooks.DropzoneKeyboard = {
    mounted() {
        document.addEventListener("keydown", this.handleKeydown.bind(this));
    },

    destroyed() {
        document.removeEventListener("keydown", this.handleKeydown.bind(this));
    },

    handleKeydown(e) {
        const focusedCard = document.activeElement.closest("[data-card-id]");
        if (!focusedCard || !focusedCard.dataset.cardId) return;

        // Handle Shift+F to finish focused card
        if (e.shiftKey && (e.key === "F" || e.key === "f")) {
            e.preventDefault();
            this.pushEvent("finish_card", {
                card_id: focusedCard.dataset.cardId,
            });
            this.announceAction("Card finished successfully");
        }

        // Handle Shift+C to cancel focused card
        if (e.shiftKey && (e.key === "C" || e.key === "c")) {
            e.preventDefault();
            this.pushEvent("cancel_card", {
                card_id: focusedCard.dataset.cardId,
            });
            this.announceAction("Card cancelled successfully");
        }
    },

    announceAction(message) {
        const announcement = document.createElement("div");
        announcement.setAttribute("aria-live", "assertive");
        announcement.setAttribute("aria-atomic", "true");
        announcement.className = "sr-only";
        announcement.textContent = message;
        document.body.appendChild(announcement);

        setTimeout(() => {
            document.body.removeChild(announcement);
        }, 1000);
    },
};

// Unified board management - single SortableJS group handles all drag/drop
Hooks.BoardContainer = {
    mounted() {
        // Initialize SortableJS for each cards container with unified group and events
        this.sortables = [];
        const cardsContainers = this.el.querySelectorAll(".cards-container");
        
        cardsContainers.forEach(container => {
            const sortable = new Sortable(container, {
                group: "board-cards",
                animation: 150,
                draggable: "[data-card-id]", // Specify which elements are draggable
                onStart: (evt) => {
                    isDragging = true;
                    this.showDropzones();
                },
                onEnd: (evt) => {
                    isDragging = false;
                    this.hideDropzones();

                    const cardId = evt.item.dataset.cardId;
                    
                    // Handle normal list movement only if within cards containers
                    if (evt.to.closest(".cards-container")) {
                        this.pushEvent("move_card", {
                            card_id: cardId,
                            from_list_id: evt.from.closest("[data-list-id]").dataset.listId,
                            to_list_id: evt.to.closest("[data-list-id]").dataset.listId,
                            new_position: evt.newIndex,
                        });
                    }
                },
            });
            this.sortables.push(sortable);
        });

        // Setup dropzones as SortableJS containers in the same group
        this.setupDropzone("finished-dropzone", "finish_card");
        this.setupDropzone("cancelled-dropzone", "cancel_card");
    },

    setupDropzone(dropzoneId, eventName) {
        const dropzone = document.getElementById(dropzoneId);
        if (dropzone) {
            const sortable = new Sortable(dropzone, {
                group: "board-cards",
                onAdd: (evt) => {
                    const cardId = evt.item.dataset.cardId;
                    this.pushEvent(eventName, { card_id: cardId });
                    
                    // Show success feedback
                    const dropzoneType = dropzoneId.includes("finished") ? "finished" : "cancelled";
                    this.showDropzoneFeedback(dropzoneType);
                    
                    // Remove the card from dropzone (it shouldn't stay there visually)
                    evt.item.remove();
                },
            });
            this.sortables.push(sortable);
        }
    },

    showDropzones() {
        const finishedDropzone = document.getElementById("finished-dropzone");
        const cancelledDropzone = document.getElementById("cancelled-dropzone");

        if (finishedDropzone) {
            finishedDropzone.classList.remove("opacity-0", "pointer-events-none");
            finishedDropzone.classList.add("opacity-100", "pointer-events-auto");
        }

        if (cancelledDropzone) {
            cancelledDropzone.classList.remove("opacity-0", "pointer-events-none");
            cancelledDropzone.classList.add("opacity-100", "pointer-events-auto");
        }
    },

    hideDropzones() {
        const finishedDropzone = document.getElementById("finished-dropzone");
        const cancelledDropzone = document.getElementById("cancelled-dropzone");

        if (finishedDropzone) {
            finishedDropzone.classList.add("opacity-0", "pointer-events-none");
            finishedDropzone.classList.remove(
                "opacity-100", "pointer-events-auto",
                "border-green-600", "bg-green-100", "scale-100"
            );
            finishedDropzone.classList.add("border-green-400", "bg-green-50", "scale-75");
        }

        if (cancelledDropzone) {
            cancelledDropzone.classList.add("opacity-0", "pointer-events-none");
            cancelledDropzone.classList.remove(
                "opacity-100", "pointer-events-auto", 
                "border-red-600", "bg-red-100", "scale-100"
            );
            cancelledDropzone.classList.add("border-red-400", "bg-red-50", "scale-75");
        }
    },

    showDropzoneFeedback(type) {
        const dropzoneId = type === "finished" ? "finished-dropzone" : "cancelled-dropzone";
        const dropzone = document.getElementById(dropzoneId);
        
        if (dropzone && dropzone.phxHook && dropzone.phxHook.showSuccessFeedback) {
            dropzone.phxHook.showSuccessFeedback();
        }
    },

    destroyed() {
        this.sortables.forEach(sortable => sortable.destroy());
    },
};

Hooks.FocusInput = {
    mounted() {
        this.el.focus();
    },
};

Hooks.FocusAndSelect = {
    mounted() {
        this.el.focus();
        this.el.select();
    },
};

Hooks.TextareaAutoSave = {
    mounted() {
        this.el.focus();
        this.el.select();

        // Handle Ctrl+Enter to submit
        this.el.addEventListener("keydown", (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key === "Enter") {
                e.preventDefault();
                this.saveValue();
            }
        });

        // Handle blur to save
        this.el.addEventListener("blur", (e) => {
            this.saveValue();
        });
    },

    saveValue() {
        const cardId = this.el
            .closest("form")
            .querySelector('input[name="card_id"]').value;
        const field = this.el
            .closest("form")
            .querySelector('input[name="field"]').value;
        const value = this.el.value;

        this.pushEvent("save_card_field", {
            card_id: cardId,
            field: field,
            value: value,
        });
    },
};

let csrfToken = document
    .querySelector("meta[name='csrf-token']")
    .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
    longPollFallbackMs: 2500,
    params: {
        _csrf_token: csrfToken,
    },
    hooks: Hooks,
});
// Show progress bar on live navigation and form submits
topbar.config({
    barColors: {
        0: "#29d",
    },
    shadowColor: "rgba(0, 0, 0, .3)",
});
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());
// connect if there are any LiveViews on the page
liveSocket.connect();
// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
