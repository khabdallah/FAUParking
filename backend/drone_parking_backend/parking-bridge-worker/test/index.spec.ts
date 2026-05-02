import { describe, it, expect, vi, beforeEach } from 'vitest';

/**
 * Unit tests for the parking-bridge-worker queue consumer.
 *
 * The key behavior under test is the payload unwrapping logic:
 *   const realData = payload.body || payload;
 *
 * When the general-parking-worker publishes via the Queues REST API it sends
 *   { body: { key, lot_id, ... } }
 * so the consumer receives message.body = { body: { key, lot_id, ... } }.
 * The unwrapping line handles both the wrapped and flat formats.
 */

// helpers

// Build a fake Message object with ack/retry spies.
function createMessage(body: any) {
  return {
    body,
    ack: vi.fn(),
    retry: vi.fn(),
  };
}

// Build a minimal MessageBatch from an array of messages.
function createBatch(messages: ReturnType<typeof createMessage>[]) {
  return { messages } as unknown as MessageBatch<any>;
}

// We import the worker default export so we can call worker.queue() directly.
import worker from '../src/index';

// tests

describe('parking-bridge-worker queue consumer', () => {
  let fetchSpy: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
  });

  // Wrapped payload

  it('correctly unwraps a double-wrapped payload and sends key + lot_id to Cloud Run', async () => {
    fetchSpy.mockResolvedValue(new Response('ok', { status: 200 }));

    const msg = createMessage({
      body: { key: 'frames/03_29_2026/123-photo.jpg', lot_id: '2' },
    });

    await worker.queue(createBatch([msg]), {} as Env);

    // fetch should have been called once with the Cloud Run URL
    expect(fetchSpy).toHaveBeenCalledTimes(1);

    const [url, init] = fetchSpy.mock.calls[0];
    expect(url).toContain('/process');
    expect(init.method).toBe('POST');

    const sentBody = JSON.parse(init.body);
    expect(sentBody).toEqual({
      lot_id: '2',
      key: 'frames/03_29_2026/123-photo.jpg',
    });

    // message should be acknowledged
    expect(msg.ack).toHaveBeenCalledTimes(1);
    expect(msg.retry).not.toHaveBeenCalled();
  });

  // Flat payload (direct binding publish)

  it('handles a flat (non-wrapped) payload', async () => {
    fetchSpy.mockResolvedValue(new Response('ok', { status: 200 }));

    const msg = createMessage({
      key: 'frames/03_29_2026/456-photo.jpg',
      lot_id: '1',
    });

    await worker.queue(createBatch([msg]), {} as Env);

    const sentBody = JSON.parse(fetchSpy.mock.calls[0][1].body);
    expect(sentBody.key).toBe('frames/03_29_2026/456-photo.jpg');
    expect(sentBody.lot_id).toBe('1');

    expect(msg.ack).toHaveBeenCalledTimes(1);
  });

  // Failure → retry

  it('retries the message when Cloud Run returns a non-200 status', async () => {
    fetchSpy.mockResolvedValue(new Response('error', { status: 500 }));

    const msg = createMessage({
      body: { key: 'frames/03_29_2026/789-photo.jpg', lot_id: '1' },
    });

    await worker.queue(createBatch([msg]), {} as Env);

    expect(msg.retry).toHaveBeenCalledTimes(1);
    expect(msg.ack).not.toHaveBeenCalled();
  });

  it('retries the message when fetch throws a network error', async () => {
    fetchSpy.mockRejectedValue(new Error('network failure'));

    const msg = createMessage({
      body: { key: 'frames/03_29_2026/000-photo.jpg', lot_id: '3' },
    });

    await worker.queue(createBatch([msg]), {} as Env);

    expect(msg.retry).toHaveBeenCalledTimes(1);
    expect(msg.ack).not.toHaveBeenCalled();
  });

  // Default lot_id

  it('defaults lot_id to "1" when not provided in the payload', async () => {
    fetchSpy.mockResolvedValue(new Response('ok', { status: 200 }));

    const msg = createMessage({
      body: { key: 'frames/03_29_2026/111-photo.jpg' },
    });

    await worker.queue(createBatch([msg]), {} as Env);

    const sentBody = JSON.parse(fetchSpy.mock.calls[0][1].body);
    expect(sentBody.lot_id).toBe('1');
    expect(msg.ack).toHaveBeenCalledTimes(1);
  });

  // Batch processing

  it('processes multiple messages in a single batch', async () => {
    // Each call needs its own Response because .text() consumes the body
    fetchSpy.mockImplementation(() => Promise.resolve(new Response('ok', { status: 200 })));

    const msgs = [
      createMessage({ body: { key: 'frames/a.jpg', lot_id: '1' } }),
      createMessage({ body: { key: 'frames/b.jpg', lot_id: '2' } }),
      createMessage({ body: { key: 'frames/c.jpg', lot_id: '3' } }),
    ];

    await worker.queue(createBatch(msgs), {} as Env);

    expect(fetchSpy).toHaveBeenCalledTimes(3);
    msgs.forEach((m) => {
      expect(m.ack).toHaveBeenCalledTimes(1);
      expect(m.retry).not.toHaveBeenCalled();
    });
  });

  it('acks successful messages and retries failed ones within the same batch', async () => {
    // First call succeeds, second fails
    fetchSpy
      .mockResolvedValueOnce(new Response('ok', { status: 200 }))
      .mockResolvedValueOnce(new Response('err', { status: 502 }));

    const ok = createMessage({ body: { key: 'frames/ok.jpg', lot_id: '1' } });
    const fail = createMessage({ body: { key: 'frames/fail.jpg', lot_id: '1' } });

    await worker.queue(createBatch([ok, fail]), {} as Env);

    expect(ok.ack).toHaveBeenCalledTimes(1);
    expect(ok.retry).not.toHaveBeenCalled();

    expect(fail.retry).toHaveBeenCalledTimes(1);
    expect(fail.ack).not.toHaveBeenCalled();
  });
});
