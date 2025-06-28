defmodule Hot.Trakt.Updater do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    schedule_next_update()
    {:ok, state}
  end

  @impl true
  def handle_info(:update, state) do
    update()
    schedule_next_update()

    {:noreply, state}
  end

  defp update() do
    Hot.Trakt.Api.update_db()
  end

  def schedule_next_update() do
    hours = 8
    interval_ms = 1000 * 60 * 60 * hours
    Process.send_after(self(), :update, interval_ms)
  end
end
