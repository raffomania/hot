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

Hooks.ArchiveDropzone = {
    mounted() {
        this.dropzone = this.el;
        
        // Create a global event listener for drag start/end
        document.addEventListener('dragstart', this.handleDragStart.bind(this));
        document.addEventListener('dragend', this.handleDragEnd.bind(this));
        
        // Add keyboard support
        document.addEventListener('keydown', this.handleKeydown.bind(this));
        
        // Setup drop handlers
        this.dropzone.addEventListener('dragover', this.handleDragOver.bind(this));
        this.dropzone.addEventListener('drop', this.handleDrop.bind(this));
        this.dropzone.addEventListener('dragenter', this.handleDragEnter.bind(this));
        this.dropzone.addEventListener('dragleave', this.handleDragLeave.bind(this));
    },
    
    destroyed() {
        document.removeEventListener('dragstart', this.handleDragStart.bind(this));
        document.removeEventListener('dragend', this.handleDragEnd.bind(this));
        document.removeEventListener('keydown', this.handleKeydown.bind(this));
    },
    
    handleDragStart(e) {
        // Only show dropzone when dragging cards
        if (e.target.closest('[data-card-id]')) {
            isDragging = true;
            this.showDropzone();
        }
    },
    
    handleDragEnd(e) {
        isDragging = false;
        this.hideDropzone();
    },
    
    handleKeydown(e) {
        // Handle Shift+Delete to archive focused card
        if (e.shiftKey && e.key === 'Delete') {
            const focusedCard = document.activeElement.closest('[data-card-id]');
            if (focusedCard && focusedCard.dataset.cardId) {
                e.preventDefault();
                this.pushEvent("archive_card", { card_id: focusedCard.dataset.cardId });
                this.showArchivedFeedback();
                
                // Announce the action for screen readers
                const announcement = document.createElement('div');
                announcement.setAttribute('aria-live', 'assertive');
                announcement.setAttribute('aria-atomic', 'true');
                announcement.className = 'sr-only';
                announcement.textContent = 'Card archived successfully';
                document.body.appendChild(announcement);
                
                setTimeout(() => {
                    document.body.removeChild(announcement);
                }, 1000);
            }
        }
    },
    
    handleDragOver(e) {
        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';
    },
    
    handleDragEnter(e) {
        e.preventDefault();
        if (isDragging) {
            this.dropzone.classList.add('border-red-600', 'bg-red-100', 'scale-100');
            this.dropzone.classList.remove('border-red-400', 'bg-red-50', 'scale-75');
        }
    },
    
    handleDragLeave(e) {
        // Only handle drag leave if we're actually leaving the dropzone
        if (!this.dropzone.contains(e.relatedTarget)) {
            this.dropzone.classList.remove('border-red-600', 'bg-red-100', 'scale-100');
            this.dropzone.classList.add('border-red-400', 'bg-red-50', 'scale-75');
        }
    },
    
    handleDrop(e) {
        e.preventDefault();
        e.stopPropagation();
        
        const cardElement = document.querySelector('.sortable-ghost') || 
                           document.querySelector('.sortable-chosen');
        
        if (cardElement && cardElement.dataset.cardId) {
            this.pushEvent("archive_card", { card_id: cardElement.dataset.cardId });
            this.showArchivedFeedback();
        }
        
        this.hideDropzone();
    },
    
    showDropzone() {
        this.dropzone.classList.remove('opacity-0', 'pointer-events-none');
        this.dropzone.classList.add('opacity-100', 'pointer-events-auto');
    },
    
    hideDropzone() {
        this.dropzone.classList.add('opacity-0', 'pointer-events-none');
        this.dropzone.classList.remove('opacity-100', 'pointer-events-auto', 'border-red-600', 'bg-red-100', 'scale-100');
        this.dropzone.classList.add('border-red-400', 'bg-red-50', 'scale-75');
    },
    
    showArchivedFeedback() {
        const originalContent = this.dropzone.innerHTML;
        this.dropzone.innerHTML = `
            <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
            <span class="text-xs font-medium text-green-600 mt-1">Archived!</span>
        `;
        
        this.dropzone.classList.remove('border-red-400', 'bg-red-50');
        this.dropzone.classList.add('border-green-400', 'bg-green-50');
        
        setTimeout(() => {
            this.dropzone.innerHTML = originalContent;
            this.dropzone.classList.remove('border-green-400', 'bg-green-50');
            this.dropzone.classList.add('border-red-400', 'bg-red-50');
        }, 1500);
    }
};

Hooks.BoardList = {
    mounted() {
        // Initialize SortableJS for cards (vertical sorting within lists)
        this.cardSortable = new Sortable(
            this.el.querySelector(".cards-container"),
            {
                group: "cards",
                animation: 150,
                onStart: (evt) => {
                    // Set dragging state and show archive dropzone
                    isDragging = true;
                    const archiveDropzone = document.getElementById('archive-dropzone');
                    if (archiveDropzone) {
                        archiveDropzone.classList.remove('opacity-0', 'pointer-events-none');
                        archiveDropzone.classList.add('opacity-100', 'pointer-events-auto');
                    }
                },
                onMove: (evt) => {
                    // Don't allow drops on the archive dropzone from SortableJS
                    if (evt.to && evt.to.id === 'archive-dropzone') {
                        return false;
                    }
                    return true;
                },
                onEnd: (evt) => {
                    // Reset dragging state and hide archive dropzone
                    isDragging = false;
                    const archiveDropzone = document.getElementById('archive-dropzone');
                    if (archiveDropzone) {
                        archiveDropzone.classList.add('opacity-0', 'pointer-events-none');
                        archiveDropzone.classList.remove('opacity-100', 'pointer-events-auto', 'border-red-600', 'bg-red-100', 'scale-100');
                        archiveDropzone.classList.add('border-red-400', 'bg-red-50', 'scale-75');
                    }
                    
                    // Only send move_card event if the card wasn't dropped on archive dropzone
                    if (evt.to && evt.to.closest('.cards-container')) {
                        this.pushEvent("move_card", {
                            card_id: evt.item.dataset.cardId,
                            from_list_id:
                                evt.from.closest("[data-list-id]").dataset.listId,
                            to_list_id:
                                evt.to.closest("[data-list-id]").dataset.listId,
                            new_position: evt.newIndex,
                        });
                    }
                },
            }
        );
    },
    destroyed() {
        if (this.cardSortable) this.cardSortable.destroy();
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
