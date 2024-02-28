defmodule Wire.PingTest do
  use WireWeb.ConnCase, async: true

  test "PING" do
    {:ok, conn} = Redix.start_link("redis://localhost:6543")
    assert Redix.command!(conn, ["PING"]) == ["PONG"]
  end

  test "SET/GET" do
    {:ok, conn} = Redix.start_link("redis://localhost:6543")
    assert Redix.command!(conn, ["SET", "k", "v"]) == ["OK"]
    assert Redix.command!(conn, ["GET", "k"]) == ["v"]
  end
end
