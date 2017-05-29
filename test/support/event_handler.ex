defmodule EventHandler do
  use GenEvent

  def init(_mod, []), do: {:ok, []}

  def handle_call({:configure, new_keys}, _state) do
    {:ok, :ok, new_keys}
  end

  def handle_event(message, state) do
    send EventHandler.MessageProxy, message
    {:ok, state}
  end

  defmodule MessageProxy do
    use GenServer

    def start(recipient), do: GenServer.start(__MODULE__, [recipient], name: __MODULE__)

    def stop, do: GenServer.stop(__MODULE__, :normal)

    def init([recipient]), do: {:ok, recipient}

    def handle_info(msg, recipient) do
      send recipient, msg
      {:noreply, recipient}
    end
  end
end
