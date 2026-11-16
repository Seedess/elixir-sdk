defmodule Seedess.Error do
  @moduledoc "A non-2xx Seedess response."
  defexception [:status, :code, :message, :body]

  @impl true
  def message(%{message: message}), do: message
end

defmodule Seedess do
  @moduledoc """
  Official Seedess SDK for Elixir.

  Server-side only: uses a secret API key (`key_…`). Playback uses the separate
  `@seedess/*-p2p` packages and a per-stream public token.

  Requires OTP 27+ for the built-in `:json` module.
  """

  @default_base_url "https://seedess.com"

  defstruct [:api_key, :base_url, :transport]

  @type t :: %__MODULE__{
          api_key: String.t(),
          base_url: String.t(),
          transport: (String.t(), String.t(), list(), String.t() -> {integer(), binary()})
        }

  @doc """
  Create a client.

      Seedess.new(System.fetch_env!("SEEDESS_API_KEY"))
  """
  def new(api_key, opts \\ []) do
    unless is_binary(api_key) and String.starts_with?(api_key, "key_") do
      raise ArgumentError, "Seedess: api_key must be a server API key (key_…)"
    end

    %__MODULE__{
      api_key: api_key,
      base_url: String.trim_trailing(Keyword.get(opts, :base_url, @default_base_url), "/"),
      transport: Keyword.get(opts, :transport, &http_transport/4)
    }
  end

  @doc "Raw request. `path` is appended to the base URL."
  def request(%__MODULE__{} = client, method, path, body \\ nil, auth \\ true) do
    url = client.base_url <> (if String.starts_with?(path, "/"), do: path, else: "/" <> path)
    headers = [{"accept", "application/json"}]
    headers = if auth, do: [{"authorization", "Bearer " <> client.api_key} | headers], else: headers

    {payload, headers} =
      if is_nil(body) do
        {"", headers}
      else
        {:json.encode(body), [{"content-type", "application/json"} | headers]}
      end

    {status, raw} = client.transport.(method, url, headers, payload)
    data = decode(raw)

    if status >= 200 and status < 300 do
      data
    else
      error = if is_map(data), do: Map.get(data, "error", %{}), else: %{}
      raise Seedess.Error,
        status: status,
        code: Map.get(error, "code", "http_error"),
        message: Map.get(error, "message", "HTTP #{status}"),
        body: data
    end
  end

  def create_stream(%__MODULE__{} = client, url, opts \\ []) do
    body =
      %{"url" => url}
      |> maybe_put("id", Keyword.get(opts, :id))
      |> maybe_put("title", Keyword.get(opts, :title))
      |> maybe_put("live", Keyword.get(opts, :live))

    request(client, "POST", "/api/v1/streams", body)
  end

  def get_stream(%__MODULE__{} = client, id),
    do: request(client, "GET", "/api/v1/streams/#{escape(id)}")

  def list_streams(%__MODULE__{} = client), do: request(client, "GET", "/api/v1/streams")

  def refresh_stream(%__MODULE__{} = client, id),
    do: request(client, "POST", "/api/v1/streams/#{escape(id)}/refresh")

  def disable_peers(%__MODULE__{} = client, id),
    do: request(client, "POST", "/api/v1/streams/#{escape(id)}/kill")

  def enable_peers(%__MODULE__{} = client, id),
    do: request(client, "POST", "/api/v1/streams/#{escape(id)}/revive")

  def get_metrics(%__MODULE__{} = client, id),
    do: request(client, "GET", "/api/v1/streams/#{escape(id)}/metrics")

  def send_telemetry(%__MODULE__{} = client, session_id, stream_id, opts \\ []) do
    body = %{
      "sessionId" => session_id,
      "streamId" => stream_id,
      "cdnBytes" => Keyword.get(opts, :cdn_bytes, 0),
      "p2pBytes" => Keyword.get(opts, :p2p_bytes, 0),
      "hashFailures" => Keyword.get(opts, :hash_failures, 0),
      "fallbacks" => Keyword.get(opts, :fallbacks, 0),
      "rebuffers" => Keyword.get(opts, :rebuffers, 0),
      "peakPeers" => Keyword.get(opts, :peak_peers, 0)
    }

    request(client, "POST", "/api/v1/telemetry", body, false)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp escape(value), do: URI.encode_www_form(to_string(value))

  defp decode(nil), do: nil
  defp decode(""), do: nil

  defp decode(raw) do
    raw = IO.iodata_to_binary(raw)

    case :json.decode(raw) do
      value -> value
    end
  rescue
    _ -> %{"error" => %{"code" => "invalid_json", "message" => String.slice(raw, 0, 200)}}
  end

  defp http_transport(method, url, headers, body) do
    method = method |> String.downcase() |> String.to_atom()
    headers = Enum.map(headers, fn {name, value} -> {String.to_charlist(name), String.to_charlist(value)} end)
    request = {String.to_charlist(url), headers, ~c"application/json", body}
    http_options = [timeout: 30_000, connect_timeout: 10_000]
    options = [body_format: :binary]

    case :httpc.request(method, request, http_options, options) do
      {:ok, {{_, status, _}, _headers, response_body}} -> {status, response_body}
      {:error, reason} -> raise "Seedess transport error: #{inspect(reason)}"
    end
  end
end
