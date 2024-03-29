defmodule Wire.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WireWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:wire, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Wire.PubSub},
      # Start a worker by calling: Wire.Worker.start_link(arg)
      # {Wire.Worker, arg},
      # Start to serve requests, typically the last entry
      WireWeb.Endpoint,
      Wire.ExternalRedis,
      Supervisor.child_spec({Task, fn -> Wire.Redis.accept(6543) end}, restart: :permanent)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Wire.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WireWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
