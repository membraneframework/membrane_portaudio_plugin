import Config

config :mockery, history: true

if config_env() == :test do
  config :mockery, enable: true
end
