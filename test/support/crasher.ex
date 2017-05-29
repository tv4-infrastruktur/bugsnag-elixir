defmodule Crasher do
  use GenServer

  def start do
    GenServer.start(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, []}
  end

  def crash, do: GenServer.cast(__MODULE__, :crash)

  def handle_cast(:crash, _) do
    require Logger
    Logger.info "Crasher.handle_cast/2: crashing"
    {:noreply, 1/0}
  end
end
