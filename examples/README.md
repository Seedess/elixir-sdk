# Elixir SDK example

A complete server + browser sample:

- `server.exs` — creates a stream with `seedess_sdk`, then serves the page and `/api/seedess`.
- `public/index.html` — loads hls.js and `https://seedess.com/p2p.js`, then plays the stream
  with the P2P adapter.

## Run

```bash
cd sdks/elixir-sdk
mix deps.get
SEEDESS_API_KEY=key_… mix run examples/server.exs
open http://localhost:8787
```

Optional: `SEEDESS_STREAM_URL`, `SEEDESS_STREAM_ID`, `SEEDESS_API_BASE`, `PORT`.

The first request to `/api/seedess` creates the stream. The API key stays in the server
process; the browser only sees the public token and playback URLs.
