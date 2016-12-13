defmodule BugsnagWorkerTest do
  use ExUnit.Case
  import Bugsnag.Worker

  test "reporting errors" do
    subscribe

    enqueue(RuntimeError.exception("some_error"), [])
    report

    assert_receive {:report, %Bugsnag.Payload{
      events: [%{
        app: %{releaseStage: "test"},
        exceptions: [%{errorClass: RuntimeError, message: "some_error", stacktrace: []}],
        payloadVersion: "2",
        severity: "error"
      }]
    }}

    enqueue(RuntimeError.exception("some_other_error"), [])
    report

    assert_receive {:report, %Bugsnag.Payload{
      events: [%{
        app: %{releaseStage: "test"},
        exceptions: [%{errorClass: RuntimeError, message: "some_other_error", stacktrace: []}],
        payloadVersion: "2",
        severity: "error"
      }]
    }}
  end
end
