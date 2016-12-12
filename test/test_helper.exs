Code.load_file("test/support/error_server.exs")
#Bugsnag.start(:ok, :ok)
ExUnit.configure(exclude: [pending: true])
ExUnit.start
