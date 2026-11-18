import { llmsTxt } from "@/lib/llms";

// Static export: written to /llms.txt at build time.
export const dynamic = "force-static";

export function GET() {
  return new Response(llmsTxt(), { headers: { "Content-Type": "text/plain; charset=utf-8" } });
}
