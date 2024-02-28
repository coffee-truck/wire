defmodule Wire.Redis do
  require Logger

  def accept(port) do
    case :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true]) do
      {:ok, socket} ->
        Logger.info("Accepting connections on port #{port}")
        loop_acceptor(socket)
      {:error, :eaddrinuse} ->
        Logger.error("Port #{port} already in use")
      {:error, reason} ->
        Logger.error("Failed to open socket: #{reason}")
    end
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} =
      Task.start(fn ->
        serve(client, %{continuation: nil})
      end)

    :ok = :gen_tcp.controlling_process(client, pid)

    loop_acceptor(socket)
  end

  defp serve(socket, %{continuation: nil}) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->  handle_parse(socket, Redix.Protocol.parse(data))
      {:error, :closed} -> :ok
    end
  end

  defp serve(socket, %{continuation: fun}) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->  handle_parse(socket, fun.(data))
      {:error, :closed} -> :ok
    end
  end

  defp handle_parse(socket, {:continuation, fun}) do
    serve(socket, %{continuation: fun})
  end

  defp handle_parse(socket, {:ok, req, left_over}) do
    resp = handle(req)

    :gen_tcp.send(socket,  Redix.Protocol.pack([resp]))
    # :gen_tcp.send(socket, Redix.Protocol.pack(resp))

    case left_over do
      "" -> serve(socket, %{continuation: nil})
      _ -> handle_parse(socket, Redix.Protocol.parse(left_over))
    end
  end

  def handle(data) do
    # IO.inspect(data, label: "handle data")
    case Wire.ExternalRedis.handle_command(data) do
      {:ok, result} ->
        # IO.inspect(result, label: "handle result")
        result

      {:error, reason} ->
        Logger.error("Redis command failed: #{reason}")
    end
    # data
  end
end
