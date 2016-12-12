defmodule Bugsnag.Worker do
  use GenServer
  require Logger

  @report_interval 100
  @notify_url "https://notify.bugsnag.com"
  @request_headers [{"Content-Type", "application/json"}]

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def empty do
    GenServer.call(__MODULE__, :empty)
  end

  def enqueue(exception, options) do
    GenServer.cast(__MODULE__, {:enqueue, exception, options})
  end

  def subscribe do
    GenServer.call(__MODULE__, :subscribe)
  end

  def unsubscribe do
    GenServer.call(__MODULE__, :unsubscribe)
  end

  # GenServer API

  def init(_args) do
    :timer.send_interval(@report_interval, __MODULE__, :report)
    {:ok, %{subscribers: [], payload: Bugsnag.Payload.new}}
  end

  def handle_call(:empty, _from, state) do
    {:reply, :ok, %{state | payload: Bugsnag.Payload.new}}
  end
  def handle_call(:subscribe, {caller, _ref}, state) do
    {:reply, :ok, %{state | subscribers: [caller | state.subscribers]}}
  end
  def handle_call(:unsubscribe, {caller, _ref}, state) do
    {:reply, :ok, %{state | subscribers: List.delete(state.subscribers, caller)}}
  end

  def handle_cast({:enqueue, exception, options}, state) when is_map(exception) do
    payload = if Exception.exception?(exception) do
      payload = Bugsnag.Payload.add_event(state.payload, exception, options[:stacktrace], options)
      notify(state.subscribers, {:enqueued, payload})
      payload
    else
      state.payload
    end
    {:noreply, %{state | payload: payload}}
  end
  def handle_cast({:enqueue, _exception, _options}, state) do
    {:noreply, state}
  end
  def handle_cast(:report, state) do
    send_report(state.payload)
    notify(state.subscribers, {:report, state.payload})
    {:noreply, state}
  end

  def handle_info(:report, state) do
    report()
    {:noreply, state}
  end

  defp send_report(payload) do
    # FIXME do something clever here please
    # payload
    # |> to_json
    # |> send_notification
    # |> case do
    #   {:ok, %{status_code: 200}}   -> :ok
    #   {:ok, %{status_code: other}} -> {:error, "status_#{other}"}
    #   {:error, %{reason: reason}}  -> {:error, reason}
    #   _                            -> {:error, :unknown}
    # end
  end

  def to_json(payload) do
    payload |> Poison.encode!
  end

  defp send_notification(body) do
    HTTPoison.post(@notify_url, body, @request_headers)
  end

  defp notify(subscribers, message), do: Enum.each(subscribers, &send(&1, message))

  defp report, do: GenServer.cast(__MODULE__, :report)
end
