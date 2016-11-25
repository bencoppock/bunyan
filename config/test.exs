use Mix.Config

config :logger,
  compile_time_purge_level: :debug

config :logger, :console,
  format: "$message\n"

config :bunyan,
  env_vars: [{"CUSTOM_ENV_VAR", "our_env_var"}],
  header_prefix: "x-some-prefix-",
  filter_parameters: ["passWORD", "SSN", "secret|sauce"]
