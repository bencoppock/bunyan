use Mix.Config

config :logger, :console,
  format: "$message\n",
  level: :info,
  metadata: [:request_id]

config :bunyan,
  env_vars: [{"CUSTOM_ENV_VAR", "our_env_var"}],
  header_prefix: "x-some-prefix-",
  filter_parameters: ["passWORD", "SSN", "secret|sauce"]
