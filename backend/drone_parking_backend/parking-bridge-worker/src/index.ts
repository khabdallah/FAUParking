/**
 * Welcome to Cloudflare Workers! This is your first worker.
 *
 * - Run `npm run dev` in your terminal to start a development server
 * - Open a browser tab at http://localhost:8787/ to see your worker in action
 * - Run `npm run deploy` to publish your worker
 *
 * Bind resources to your worker in `wrangler.jsonc`. After adding bindings, a type definition for the
 * `Env` object can be regenerated with `npm run cf-typegen`.
 *
 * Learn more at https://developers.cloudflare.com/workers/
 */

export default {
  // This handler is triggered automatically by the Queue
  async queue(batch: MessageBatch<any>, env: Env): Promise<void> {
    const cloudRunUrl = "https://frame-processor-524432058998.us-south1.run.app/process";
    
    console.log("[BRIDGE] Received batch of", batch.messages.length, "messages");

    const promises = batch.messages.map(async (message, idx) => {
      try {
        // === DEBUG: Dump raw message ===
        const raw = message.body;
        console.log(`[BRIDGE][${idx}] raw message.body type:`, typeof raw);
        console.log(`[BRIDGE][${idx}] raw message.body:`, JSON.stringify(raw));

        // Unwrap: try every possible nesting
        let data: any = raw;

        // If the queue wraps in { body: ... }
        if (typeof data === 'object' && data !== null && 'body' in data) {
          console.log(`[BRIDGE][${idx}] found .body wrapper, unwrapping`);
          data = data.body;
        }

        // If it's a string (double-serialized), parse it
        if (typeof data === 'string') {
          console.log(`[BRIDGE][${idx}] data is string, parsing JSON`);
          try {
            data = JSON.parse(data);
          } catch (e) {
            console.error(`[BRIDGE][${idx}] JSON.parse failed:`, e);
          }
        }

        // If STILL wrapped in { body: ... } after parse
        if (typeof data === 'object' && data !== null && 'body' in data && !('key' in data)) {
          console.log(`[BRIDGE][${idx}] found nested .body after parse, unwrapping again`);
          data = data.body;
        }

        // If it's STILL a string after all that
        if (typeof data === 'string') {
          console.log(`[BRIDGE][${idx}] data is STILL string after unwrap, trying parse again`);
          try {
            data = JSON.parse(data);
          } catch (e) {
            console.error(`[BRIDGE][${idx}] second JSON.parse failed:`, e);
          }
        }

        console.log(`[BRIDGE][${idx}] final data:`, JSON.stringify(data));
        console.log(`[BRIDGE][${idx}] final data.key:`, data?.key);
        console.log(`[BRIDGE][${idx}] final data.lot_id:`, data?.lot_id);

        // Drop poison messages
        if (!data || !data.key) {
          console.warn(`[BRIDGE][${idx}] DROPPING: no key found in data`);
          message.ack();
          return;
        }

        const outPayload = {
          lot_id: data.lot_id || "1",
          key: data.key
        };
        console.log(`[BRIDGE][${idx}] sending to Cloud Run:`, JSON.stringify(outPayload));

        const response = await fetch(cloudRunUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(outPayload),
        });

        const respText = await response.text();
        console.log(`[BRIDGE][${idx}] Cloud Run response: ${response.status} ${respText}`);

        if (!response.ok) {
          // If it's a 4xx error (e.g. Bad Request, image not found), retrying won't help. Drop it.
          if (response.status >= 400 && response.status < 500) {
            console.error(`[BRIDGE][${idx}] Cloud Run 4xx Client Error. Dropping. Detail: ${respText}`);
            message.ack();
            return;
          }
          throw new Error(`Cloud Run returned ${response.status}: ${respText}`);
        }

        message.ack();
        
      } catch (error) {
        console.error(`[BRIDGE][${idx}] FAILED with network or 5xx error:`, error);
        message.retry(); 
      }
    });

    await Promise.all(promises);
  },
};
