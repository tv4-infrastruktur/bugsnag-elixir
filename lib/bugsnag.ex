defmodule Bugsnag do
  use Application
  import Supervisor.Spec

  require Logger

  alias Bugsnag.Payload

  def start(_type, _args) do
    config = default_config
    |> Keyword.merge(Application.get_all_env(:bugsnag))
    |> Enum.map(fn {k, v} -> {k, eval_config(v)} end)

    case config[:use_logger] |> to_string do
      "true" ->
        :error_logger.add_report_handler(Bugsnag.Logger)
      _ -> :ok
    end

    # Update Application config with evaluated configuration
    # It's needed for use in Bugsnag.Payload, could be removed
    # by using GenServer instead of this kind of app.
    Enum.each config, fn {k, v} ->
      Application.put_env :bugsnag, k, v
    end

    # put normalized api key to application config
    Application.put_env(:bugsnag, :api_key, config[:api_key])

    children = [
      worker(Bugsnag.Worker, [])
    ]

    opts = [strategy: :one_for_one, name: Bugsnag.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def subscribe do
    Bugsnag.Worker.subscribe
  end

  def unsubscribe do
    Bugsnag.Worker.unsubscribe
  end

  @doc """
  Report the exception without waiting for the result of the Bugsnag API call.
  (I.e. this might fail silently)
  """
  def report(exception, options \\ []) do
    Bugsnag.Worker.enqueue(exception, options)
  end

  defp default_config do
    [
      api_key:       {:system, "BUGSNAG_API_KEY", "FAKEKEY"},
      use_logger:    {:system, "BUGSNAG_USE_LOGGER", true},
      release_stage: {:system, "BUGSNAG_RELEASE_STAGE", "test"}
    ]
  end

  defp eval_config({:system, env_var, default}) do
    case System.get_env(env_var) do
      nil -> default
      val -> val
    end
  end

  defp eval_config({:system, env_var}) do
    eval_config({:system, env_var, nil})
  end

  defp eval_config(value), do: value
end
