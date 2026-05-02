# parking-bridge-worker
A Cloudflare Worker that acts as a bridge between the `general-parking-worker` and the external frame-processing service running on Google Cloud Run. It consumes messages from a Cloudflare Queue and forwards each frame-processing job to the Cloud Run endpoint.

## Architecture
```
general-parking-worker ──► Cloudflare Queue (frame-jobs) ──► parking-bridge-worker ──► Cloud Run (frame-processor)
```

When a camera frame is uploaded through the general-parking-worker, a job message is published to the `frame-jobs` queue. This worker automatically picks up batches of messages, extracts the R2 key and lot ID, and sends them to the Cloud Run processing service via HTTP POST.

### Error Handling
| Scenario | Behavior |
|----------|----------|
| Cloud Run returns **2xx** | Message is acknowledged and removed from the queue |
| Cloud Run returns **4xx** (client error) | Message is acknowledged and **dropped** (retrying won't help) |
| Cloud Run returns **5xx** or network error | Message is **retried** (up to 5 times) |
| Message has no valid `key` field | Message is acknowledged and **dropped** (poison message) |
| All retries exhausted | Message is sent to the `frame-jobs-dlq` dead-letter queue |

## How to Use

### Prerequisites
- [Node.js](https://nodejs.org/) (v18+)
- A [Cloudflare](https://dash.cloudflare.com/) account
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/install-and-update/) (`npm i -g wrangler`)

### Installation
```bash
cd parking-bridge-worker
npm install
```

### Local Development
Start a local dev server with Wrangler:
```bash
npm run dev
```
> **Note:** Queue consumers cannot be triggered locally via HTTP. Use `wrangler dev --remote` or deploy to test queue consumption end-to-end.

### Running Tests
The project uses Vitest with the Cloudflare Workers pool for unit testing:
```bash
npm test
```

### Generate Types
If you modify bindings in `wrangler.jsonc`, regenerate the TypeScript types:
```bash
npm run cf-typegen
```

### Deployment
Deploy the worker to Cloudflare:
```bash
npm run deploy
```
> **Note:** Ensure the `frame-jobs` queue and its dead-letter queue `frame-jobs-dlq` already exist in your Cloudflare account before deploying.

### Environment & Bindings
The worker relies on the following bindings configured in `wrangler.jsonc`:

| Binding | Type | Purpose |
|---------|------|---------|
| `frame-jobs` | Queue (Consumer) | Receives frame-processing job messages |
| `frame-jobs-dlq` | Queue (Dead Letter) | Catches messages that fail all retry attempts |

### Queue Configuration

| Setting | Value | Description |
|---------|-------|-------------|
| `max_batch_size` | 5 | Process up to 5 messages per invocation |
| `max_batch_timeout` | 1 second | Wait up to 1 second to fill a batch |
| `max_retries` | 5 | Retry failed messages up to 5 times |

### Expected Message Format
The worker expects each queue message body to contain:
```json
{
  "key": "frames/05_02_2026/1746200000000-abc12345-frame.jpg",
  "lot_id": "1",
  "uploaded_at": 1746200000000,
  "content_type": "image/jpeg"
}
```
The `key` (R2 object key) and `lot_id` fields are forwarded to the Cloud Run service. Messages missing a `key` field are dropped as poison messages.
