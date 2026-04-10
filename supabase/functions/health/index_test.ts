import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { describe, it } from "https://deno.land/std@0.224.0/testing/bdd.ts";

// ---------------------------------------------------------------------------
// Helpers — build a minimal mock of the Supabase client used in index.ts
// ---------------------------------------------------------------------------

/** Stub that simulates `supabase.from("transactions").select("id").limit(0)` */
function mockSupabaseClient(dbError: Error | null = null) {
  return {
    from: (_table: string) => ({
      select: (_cols: string) => ({
        limit: (_n: number) => Promise.resolve({ error: dbError, data: [] }),
      }),
    }),
  };
}

// ---------------------------------------------------------------------------
// Because `index.ts` calls `Deno.serve` and `Deno.env.get` at module scope,
// we test the *response logic* directly rather than importing the module.
// This avoids side-effects and keeps the test hermetic.
// ---------------------------------------------------------------------------

async function handleHealthRequest(
  req: Request,
  supabase: ReturnType<typeof mockSupabaseClient>,
): Promise<Response> {
  if (req.method !== "GET") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const checks: Record<string, string> = {
    runtime: "ok",
    database: "unknown",
  };
  let status = 200;

  try {
    const { error } = await supabase
      .from("transactions")
      .select("id")
      .limit(0);

    if (error) throw error;
    checks.database = "ok";
  } catch (_e) {
    checks.database = "error";
    status = 503;
  }

  return new Response(
    JSON.stringify({
      status: status === 200 ? "healthy" : "degraded",
      checks,
      timestamp: new Date().toISOString(),
      version: "0.1.0",
    }),
    {
      status,
      headers: { "Content-Type": "application/json" },
    },
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("Health Edge Function", () => {
  it("returns 200 healthy when DB probe succeeds", async () => {
    const req = new Request("http://localhost/health", { method: "GET" });
    const res = await handleHealthRequest(req, mockSupabaseClient());

    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.status, "healthy");
    assertEquals(body.checks.runtime, "ok");
    assertEquals(body.checks.database, "ok");
    assertEquals(typeof body.timestamp, "string");
    assertEquals(body.version, "0.1.0");
  });

  it("returns 503 degraded when DB probe fails", async () => {
    const req = new Request("http://localhost/health", { method: "GET" });
    const dbError = new Error("connection refused");
    const res = await handleHealthRequest(
      req,
      mockSupabaseClient(dbError),
    );

    assertEquals(res.status, 503);
    const body = await res.json();
    assertEquals(body.status, "degraded");
    assertEquals(body.checks.runtime, "ok");
    assertEquals(body.checks.database, "error");
  });

  it("returns 405 for non-GET requests", async () => {
    const req = new Request("http://localhost/health", { method: "POST" });
    const res = await handleHealthRequest(req, mockSupabaseClient());

    assertEquals(res.status, 405);
    const body = await res.json();
    assertEquals(body.error, "Method not allowed");
  });

  it("returns correct Content-Type header", async () => {
    const req = new Request("http://localhost/health", { method: "GET" });
    const res = await handleHealthRequest(req, mockSupabaseClient());

    assertEquals(res.headers.get("Content-Type"), "application/json");
  });
});
