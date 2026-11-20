# Deploy and Host Kokoro TTS with Railway

Kokoro TTS turns text into natural-sounding speech with the open Kokoro-82M model. This community template runs Kokoro-FastAPI on CPU behind a small gateway: an OpenAI-compatible `/v1/audio/speech` API protected by an API key, and a password-protected web player for trying voices in the browser.

## About Hosting Kokoro TTS

Kokoro-82M is a compact text-to-speech model (82 million parameters, Apache-2.0) with more than 70 voices across English, Spanish, French, Italian, Portuguese, Hindi, Japanese and Chinese. Kokoro-FastAPI wraps it in an API that speaks the OpenAI speech format, plus ElevenLabs- and Cartesia-style routes, streaming and a web player.

On Railway the model runs on CPU in a private service with the weights baked into the image, so nothing is downloaded at boot. A Caddy gateway is the only public entry: API clients send the key in a header, browsers sign in with a user name and password. Thread pools are sized from the service's CPU quota, not the host's core count, so synthesis stays fast on shared hosts.

## Common Use Cases

- Drop-in replacement for OpenAI's `tts-1` in apps, bots and automations (n8n, Open WebUI, AnythingLLM)
- Narration for articles, newsletters, videos and e-learning
- Voice output for AI agents and phone or chat assistants
- Batch audio generation in MP3, WAV, Opus, FLAC or PCM
- Trying and mixing voices in the built-in web player

## Dependencies for Kokoro TTS Hosting

- None beyond this template: the model, voices and phonemizer (espeak-ng) ship in the image
- About 1.2 GB RAM for the model service (Hobby plan or higher)

### Deployment Dependencies

- Kokoro-FastAPI: https://github.com/remsky/Kokoro-FastAPI
- Kokoro-82M model card: https://huggingface.co/hexgrad/Kokoro-82M
- OpenAI speech API format: https://platform.openai.com/docs/api-reference/audio/createSpeech
- Template source: https://github.com/baranberkay96/kokoro-tts-railway

### Implementation Details

| Service | What it runs | Public | Volume |
|---|---|---|---|
| Kokoro TTS | Caddy 2.11 gateway: API key pass-through, basic auth for browsers | yes, port 8080 | – |
| kokoro | `ghcr.io/remsky/kokoro-fastapi-cpu:v0.10.0` (pinned by digest) with a start wrapper | private, 8880 | – |

**Use the API.** The key is the `KOKORO_API_KEY` variable of the Kokoro TTS service. With any OpenAI SDK, set the base URL to `https://{your-domain}/v1` and the API key to that value:

```
curl https://{your-domain}/v1/audio/speech \
  -H "Authorization: Bearer {KOKORO_API_KEY}" -H "Content-Type: application/json" \
  -d '{"model":"kokoro","input":"Hello from Railway!","voice":"af_heart","response_format":"mp3"}' -o hello.mp3
```

`GET /v1/audio/voices` lists the voices; voices can be mixed, e.g. `af_bella+af_sky`. ElevenLabs-style clients can send the key as `xi-api-key`, Cartesia-style clients as `X-API-Key`.

**Web player.** Open `https://{your-domain}/` and sign in with `KOKORO_USERNAME` and `KOKORO_PASSWORD` (generated at deploy). The gateway adds the API key for signed-in browsers.

**Speed and memory (measured on Railway).** About 1.1–1.2 GB RAM with the model loaded. An 80-character sentence took about 1 s, a 950-character paragraph (about 65 s of audio) about 7 s. The Trial plan's 1 GB per service is too small for the model; use Hobby or higher.

**Tuning.** `KOKORO_THREADS` (default `auto` = the service's CPU quota, capped at 8). More vCPUs on the kokoro service shorten long syntheses. `MAX_INPUT_LENGTH` limits characters per request (200,000).

**Scaling.** The model service is stateless; give it more vCPUs for faster long syntheses or more parallel requests.

**Upgrading.** Versions are pinned in `services/kokoro/Dockerfile` and `services/gateway/Dockerfile` of the template repo. Change the tag and digest to a newer Kokoro-FastAPI release and redeploy.

**Security notes.** An empty, too short or otherwise unusable password or API key never opens the service: the start log says it is locked and which variable to fix. Cross-site browser requests are refused unless they carry an API key header. Debug, model-unload and voice-saving routes stay off.

### Why Deploy Kokoro TTS on Railway?

Railway gives Kokoro a private network, HTTPS and generated secrets in one click, so you get your own OpenAI-compatible speech endpoint without per-character fees. Usage-based pricing fits bursty TTS workloads, and other services in the same project can call the model over the private network.
