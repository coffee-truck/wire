defmodule Wire.ExternalRedis do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def handle_command(command) do
    result = GenServer.call(__MODULE__, {:command, command})
    # IO.inspect(result, label: "handle_command")
    result
  end

  # Server callbacks
  def init(_opts) do
    Logger.info("Starting Redis connection")
    # {:ok, conn} = Redix.start_link(opts)
    {:ok, conn} = Redix.start_link(name: :external_redis, host: "localhost", port: 13621)
    {:ok, conn}
  end

  def handle_call({:command, command}, _from, conn) do
    case Redix.command(conn, command) do
      {:ok, result} -> {:reply, {:ok, result}, conn}
      {:error, reason} -> {:reply, {:error, reason}, conn}
    end
  end

end
