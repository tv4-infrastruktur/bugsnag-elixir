defmodule Bugsnag.LoggerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  setup_all do
    :error_logger.add_report_handler(Bugsnag.Logger)

    on_exit fn ->
      :error_logger.delete_report_handler(Bugsnag.Logger)
    end
  end

  setup do
    Bugsnag.Worker.empty
    Bugsnag.subscribe
    on_exit &Bugsnag.unsubscribe/0
  end

  test "logging a crash" do
    :proc_lib.spawn fn ->
      raise RuntimeError, "Oops"
    end

    assert_receive({
      :enqueued,
      %Bugsnag.Payload{
        api_key: "FAKEKEY",
        events: [%{
          app: %{releaseStage: "test"},
          exceptions: [%{
            errorClass: RuntimeError,
            message: "Oops",
            stacktrace: _
          }],
          payloadVersion: "2",
          severity: "error"
        }],
        notifier: _
      }
    })
  end

  test "crashes do not cause recursive logging" do
    log_msg = capture_log fn ->
      error_report = [[error_info: {:error, %RuntimeError{message: "Oops"}, []}], []]
      :error_logger.error_report(error_report)
    end

    assert_receive({:enqueued, %Bugsnag.Payload{}}, 250)
    assert log_msg =~ "[[error_info: {:error, %RuntimeError{message: \"Oops\"}, []}], []]"
  end

  test "log levels lower than :error_report are ignored" do
    message_types = [:info_msg, :info_report, :warning_msg, :error_msg]

    Enum.each message_types, fn(type) ->
      log_msg = capture_log fn ->
        apply(:error_logger, type, ["Ignore me"])
      end

      assert log_msg =~ "Ignore me"
    end
    refute_receive({:enqueued, %Bugsnag.Payload{}})
  end

  test "logging exceptions from special processes" do
    :proc_lib.spawn fn -> Float.parse("12.345e308") end
    assert_receive({:enqueued, %Bugsnag.Payload{}}, 250)
  end

  test "logging exceptions from Tasks" do
    log_msg = capture_log fn ->
      Task.start fn -> Float.parse("12.345e308") end
      Process.sleep 250
    end

    assert_received({:enqueued, %Bugsnag.Payload{}})
    assert log_msg =~ "(ArgumentError) argument error"
  end

  test "logging exceptions from GenServers" do
    {:ok, pid} = ErrorServer.start

    log_msg = capture_log fn ->
      GenServer.cast(pid, :fail)
      Process.sleep 250
    end

    assert log_msg =~ "(stop) bad cast: :fail" || log_msg =~ "but no handle_cast"
    assert_received({:enqueued, %Bugsnag.Payload{}})
  end
end
