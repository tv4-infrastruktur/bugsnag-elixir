defmodule BugsnagTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  setup do
    Bugsnag.Worker.empty
    Bugsnag.subscribe
    on_exit &Bugsnag.unsubscribe/0
    :ok
  end

  test "it doesn't raise errors if you report garbage" do
    capture_log fn ->
      Bugsnag.report(Enum, %{ignore: :this_error_in_test})
    end
  end

  test "it returns proper results if you use sync_report" do
    assert :ok = Bugsnag.sync_report(RuntimeError.exception("some_error"))
  end

  test "it handles real errors" do
    try do
      raise "foo bar"
    rescue
      exception -> Bugsnag.report(exception)
    end
  end

  test "it properly sets config" do
    assert Application.get_env(:bugsnag, :release_stage) == "test"
    assert Application.get_env(:bugsnag, :api_key) == "FAKEKEY"
    assert Application.get_env(:bugsnag, :use_logger) == false
  end

  test "it enqueues errors that are periodically reported to Bugsnag" do
    Bugsnag.report(RuntimeError.exception("some_error"), [])
    assert_receive {:enqueued, %Bugsnag.Payload{api_key: "FAKEKEY", events: [%{app: %{releaseStage: "test"}, exceptions: [%{errorClass: RuntimeError, message: "some_error", stacktrace: _}], payloadVersion: "2", severity: "error"}], notifier: %{name: "Bugsnag Elixir", url: "https://github.com/jarednorman/bugsnag-elixir", version: "1.4.0-beta2"}}}, 250
  end

  test "it periodically reports the errors" do
    Bugsnag.report(RuntimeError.exception("some_error"), [])
    assert_receive {:enqueued, _payload}
    assert_receive {:report, %Bugsnag.Payload{}}
  end
end
