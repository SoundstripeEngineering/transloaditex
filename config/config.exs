import Config

config :transloaditex,
  auth_key: System.get_env("TRANSLOADIT_AUTH_KEY"),
  auth_secret: System.get_env("TRANSLOADIT_AUTH_SECRET"),
  max_retries: String.to_integer(System.get_env("TRANSLOADIT_MAX_RETRIES", "10")),
  duration: String.to_integer(System.get_env("TRANSLOADIT_DURATION", "300"))

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
