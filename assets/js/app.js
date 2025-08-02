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

Hooks.BoardList = {
    mounted() {
        // Initialize SortableJS for cards (vertical sorting within lists)
        this.cardSortable = new Sortable(
            this.el.querySelector(".cards-container"),
            {
                group: "cards",
                animation: 150,
                onMove: (evt) => {
                    const targetContainer = evt.to;

                    return true; // Allow the move
                },
                onEnd: (evt) => {
                    this.pushEvent("move_card", {
                        card_id: evt.item.dataset.cardId,
                        from_list_id:
                            evt.from.closest("[data-list-id]").dataset.listId,
                        to_list_id:
                            evt.to.closest("[data-list-id]").dataset.listId,
                        new_position: evt.newIndex,
                    });
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
