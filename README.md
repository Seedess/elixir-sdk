# seedess_sdk

Official Seedess SDK for Elixir.

**Server-side only.** The SDK uses a secret API key (`key_…`) to create and control streams.
Never ship it in a browser or a mobile app. Playback uses the separate `@seedess/*-p2p`
packages and a per-stream public token (`pk_…`).

## Install

```elixir
def deps do
  [{:seedess_sdk, "~> 0.1.0"}]
end
```

Requires OTP 27+ for the built-in `:json` module.

## Use

```elixir
client = Seedess.new(System.fetch_env!("SEEDESS_API_KEY"))

stream = Seedess.create_stream(client, "https://origin.example/master.m3u8",
  id: "demo",
  live: true
)

IO.puts(stream["publicToken"])
IO.puts(stream["playback"]["master"])
```

Pass only the public token and stream id to the page.

## Full working example

See [`examples/`](./examples) for a server that creates a stream and a browser page
that plays it with hls.js + the Seedess P2P adapter.

## Methods

| Method | HTTP | Purpose |
| --- | --- | --- |
| `Seedess.create_stream(client, url, id:, title:, live:)` | `POST /api/v1/streams` | Ingest a manifest, mint the public token. |
| `Seedess.get_stream(client, id)` | `GET /api/v1/streams/:id` | Status, variants, segment count. |
| `Seedess.list_streams(client)` | `GET /api/v1/streams` | All streams in the tenant. |
| `Seedess.refresh_stream(client, id)` | `POST /api/v1/streams/:id/refresh` | Pull new live segments. |
| `Seedess.disable_peers(client, id)` | `POST /api/v1/streams/:id/kill` | CDN only; playback continues. |
| `Seedess.enable_peers(client, id)` | `POST /api/v1/streams/:id/revive` | Re-enable peer delivery. |
| `Seedess.get_metrics(client, id)` | `GET /api/v1/streams/:id/metrics` | Offload and delivery counters. |
| `Seedess.send_telemetry(client, session_id, stream_id, opts)` | `POST /api/v1/telemetry` | One session batch (public, rate limited). |

`Seedess.request(client, method, path, body, auth)` is available for routes without a helper.

## Errors

```elixir
try do
  Seedess.create_stream(client, url)
rescue
  error in Seedess.Error ->
    IO.puts("#{error.status} #{error.code} #{error.message}")
end
```

## Links

- Docs: https://seedess.com/docs/
- API: https://seedess.com/docs/api/
- Libraries: https://seedess.com/docs/libraries/

## License

MIT.
