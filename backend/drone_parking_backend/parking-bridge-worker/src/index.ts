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
    
    // process messages in parallel to be faster
    const promises = batch.messages.map(async (message) => {
      try {
        const payload = message.body; 
        
        // Extract the actual data 
        const realData = payload.body || payload; 

        const response = await fetch(cloudRunUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            lot_id: realData.lot_id || "1",
            key: realData.key
          }),
        });

        if (!response.ok) {
          throw new Error(`Cloud Run returned ${response.status}`);
        }

        // If successful, we explicitly acknowledge the message so it's removed from queue
        message.ack();
        
      } catch (error) {
        console.error("Failed to push to Cloud Run:", error);
        // If DON'T ack(), Cloudflare will retry this message later automatically
        message.retry(); 
      }
    });

    // Wait for all requests to finish
    await Promise.all(promises);
  },
};
