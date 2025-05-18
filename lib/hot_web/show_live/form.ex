defmodule HotWeb.ShowLive.Form do
  use HotWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      {@page_title}
      <:subtitle>Use this form to manage show records in your database.</:subtitle>
    </.header>

    <.form for={@form} id="show-form" phx-change="validate" phx-submit="save">
      <.button phx-disable-with="Saving..." variant="primary">Save Show</.button>
      <.button navigate={return_path(@return_to, @show)}>Cancel</.button>
    </.form>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    show =
      case params["id"] do
        nil -> nil
        id -> Ash.get!(Hot.Trakt.Show, id)
      end

    action = if is_nil(show), do: "New", else: "Edit"
    page_title = action <> " " <> "Show"
    dbg(params)

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(show: show)
     |> assign(:page_title, page_title)
     |> assign_form()}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  @impl true
  def handle_event("validate", %{"show" => show_params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, show_params))}
  end

  def handle_event("save", %{"show" => show_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: show_params) do
      {:ok, show} ->
        notify_parent({:saved, show})

        socket =
          socket
          |> put_flash(:info, "Show created successfully")
          |> push_navigate(to: return_path(socket.assigns.return_to, show))

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{show: show}} = socket) do
    form =
      AshPhoenix.Form.for_create(show, :create, as: "show")

    assign(socket, form: to_form(form))
  end

  defp return_path("index", _show), do: ~p"/shows"
  defp return_path("show", show), do: ~p"/shows/#{show.id}"
end
