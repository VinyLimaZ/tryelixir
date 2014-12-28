use Mix.Config

config :tryelixir,
  secret: System.get_env("TRYELIXIR_SECRET")

if Mix.env in [:test, :dev] do
  config :tryelixir,
    secret: System.get_env("TRYELIXIR_SECRET") || String.duplicate("abcdef0123456789", 8)
end
