# Full working Seedess example for Elixir.
#
#   SEEDESS_API_KEY=key_... mix run examples/server.exs
#   open http://localhost:8787

defmodule Seedess.Example do
  @origin "https://seedess.com"

  def handoff do
    case :persistent_term.get({__MODULE__, :payload}, nil) do
      nil ->
        api_key = System.fetch_env!("SEEDESS_API_KEY")
        base_url = System.get_env("SEEDESS_API_BASE", @origin)
        stream_url = System.get_env("SEEDESS_STREAM_URL", "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")
        stream_id = System.get_env("SEEDESS_STREAM_ID", "sdk-example")

        client = Seedess.new(api_key, base_url: base_url)
        stream = Seedess.create_stream(client, stream_url, id: stream_id, title: "Seedess Elixir SDK example")
        token = stream["publicToken"]
        playback = stream["playback"]

        payload = %{
          "ok" => true,
          "stream" => stream["id"],
          "token" => token,
          "playback" => %{
            "master" => @origin <> playback["master"],
            "signaling" => @origin <> playback["signaling"],
            "config" => @origin <> "/signaling/config?token=" <> URI.encode_www_form(token)
          }
        }

        :persistent_term.put({__MODULE__, :payload}, payload)
        payload

      payload ->
        payload
    end
  end

  def html, do: File.read!(Path.join(__DIR__, "public/index.html"))
end

defmodule Seedess.Example.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/api/seedess" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, :json.encode(Seedess.Example.handoff()))
  end

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, Seedess.Example.html())
  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, :json.encode(%{"ok" => false, "error" => "Not found"}))
  end
end

port = String.to_integer(System.get_env("PORT", "8787"))
IO.puts("Seedess example on http://localhost:#{port}")
IO.puts("The first /api/seedess request creates the stream.")
Plug.Cowboy.http(Seedess.Example.Router, [], port: port)
Process.sleep(:infinity)
