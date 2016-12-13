use Mix.Config

config :bugsnag, use_logger: false
config :bugsnag, http_client: Bugsnag.HttpTestClient
