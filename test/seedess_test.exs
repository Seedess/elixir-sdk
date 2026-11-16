defmodule SeedessTest do
  use ExUnit.Case, async: true

  defp fake(status, body, _calls) do
    fn method, url, headers, payload ->
      send(self(), {:call, method, url, headers, payload})
      {status, if(is_nil(body), do: "", else: :json.encode(body))}
    end
  end

  test "create_stream sends auth and body" do
    client = Seedess.new("key_test", transport: fake(201, %{"ok" => true, "id" => "demo", "publicToken" => "pk_1"}, nil))
    stream = Seedess.create_stream(client, "https://origin/master.m3u8", id: "demo")
    assert stream["id"] == "demo"
    assert_received {:call, "POST", "https://seedess.com/api/v1/streams", headers, payload}
    assert {"authorization", "Bearer key_test"} in headers
    assert :json.decode(IO.iodata_to_binary(payload))["id"] == "demo"
  end

  test "path ids are encoded" do
    client = Seedess.new("key_test", transport: fake(200, %{"ok" => true}, nil))
    Seedess.get_stream(client, "a/b")
    assert_received {:call, "GET", "https://seedess.com/api/v1/streams/a%2Fb", _, _}
  end

  test "disable and enable peers map to kill and revive" do
    client = Seedess.new("key_test", transport: fake(200, %{"ok" => true}, nil))
    Seedess.disable_peers(client, "demo")
    assert_received {:call, "POST", "https://seedess.com/api/v1/streams/demo/kill", _, _}
    Seedess.enable_peers(client, "demo")
    assert_received {:call, "POST", "https://seedess.com/api/v1/streams/demo/revive", _, _}
  end

  test "telemetry has no api key" do
    client = Seedess.new("key_test", transport: fake(204, nil, nil))
    Seedess.send_telemetry(client, "s", "demo", p2p_bytes: 10)
    assert_received {:call, "POST", "https://seedess.com/api/v1/telemetry", headers, _}
    refute List.keymember?(headers, "authorization", 0)
  end

  test "error envelope becomes Seedess.Error" do
    client = Seedess.new("key_test", transport: fake(429, %{"ok" => false, "error" => %{"code" => "QUOTA_EXCEEDED", "message" => "Limit reached"}}, nil))
    error = assert_raise Seedess.Error, fn -> Seedess.create_stream(client, "https://origin") end
    assert error.status == 429
    assert error.code == "QUOTA_EXCEEDED"
    assert error.message == "Limit reached"
  end

  test "rejects a public token" do
    assert_raise ArgumentError, fn -> Seedess.new("pk_stream") end
  end
end
