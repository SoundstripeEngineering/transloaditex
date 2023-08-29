import Config

config :transloaditex,
  auth_key: "1526fdc376af415795be46f6c2b979a6",
  auth_secret: "a2dd4f8707164d2bb0738cee70056c6ed15b4c19",
  # auth_key: System.get_env("TRANSLOADIT_AUTH_KEY"),
  # auth_secret: System.get_env("TRANSLOADIT_AUTH_SECRET"),
  max_retries: String.to_integer(System.get_env("TRANSLOADIT_MAX_RETRIES", "10")),
  duration: String.to_integer(System.get_env("TRANSLOADIT_DURATION", "300"))
