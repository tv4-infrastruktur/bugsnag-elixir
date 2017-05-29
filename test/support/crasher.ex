defmodule Crasher do
  use GenServer

  def start do
    GenServer.start(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, []}
  end

  def crash, do: GenServer.cast(__MODULE__, :crash)

  def handle_cast(:crash, []) do
    require Logger
    send :nobody, :something
    {:noreply, []}
  end
end
