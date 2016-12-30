defmodule BugsnagWorkerTest do
  use ExUnit.Case
  import Bugsnag.Worker

  setup do
    empty()
    subscribe()
    on_exit &unsubscribe/0
  end

  test "enqueuing errors" do
    enqueue(RuntimeError.exception("some_error"), [stacktrace: []])
    report()

    assert_receive {:enqueued, %Bugsnag.Payload{
      events: [%{
        app: %{releaseStage: "test"},
        exceptions: [%{errorClass: RuntimeError, message: "some_error", stacktrace: []}],
        payloadVersion: "2",
        severity: "error"
      }]
    }}

    enqueue(RuntimeError.exception("some_other_error"), [])
    report()

    assert_receive {:enqueued, %Bugsnag.Payload{
      events: [%{
        app: %{releaseStage: "test"},
        exceptions: [%{errorClass: RuntimeError, message: "some_other_error", stacktrace: []}],
        payloadVersion: "2",
        severity: "error"
      }]
    }}
  end

  test "sending a report and receiving a successful response" do
    enqueue(RuntimeError.exception("some_error"), [stacktrace: []])
    report()
    assert_receive {:reported, :ok}
  end

  test "sending a report and receiving errors" do
    enqueue(RuntimeError.exception("some_serious_error"), [stacktrace: []])
    report()
    assert_receive {:reported, {:error, "something went wrong"}}
  end
end
