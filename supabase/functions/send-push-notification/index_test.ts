import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { describe, it } from "https://deno.land/std@0.224.0/testing/bdd.ts";

// ---------------------------------------------------------------------------
// HTTP-layer handler (mirrors index.ts, decoupled from Supabase/FCM)
// ---------------------------------------------------------------------------

async function handleRequest(
  req: Request,
  serviceRoleKey: string,
  processFn: (payload: Record<string, string>) => Promise<Record<string, unknown>>,
): Promise<Response> {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const authHeader = req.headers.get("Authorization");
  const token = authHeader?.replace("Bearer ", "");
  if (token !== serviceRoleKey) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  let payload: Record<string, string>;
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!payload.conversation_id || !payload.sender_id) {
    return new Response(
      JSON.stringify({ error: "Missing conversation_id or sender_id" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  try {
    const result = await processFn(payload);
    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(
      JSON.stringify({ status: "error", message: (e as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
}

// ---------------------------------------------------------------------------
// Tests — HTTP layer
// ---------------------------------------------------------------------------

const SERVICE_KEY = "test-service-role-key"; // pragma: allowlist secret
const authHeaders = { Authorization: `Bearer ${SERVICE_KEY}` };

describe("HTTP handler", () => {
  const successFn = () =>
    Promise.resolve({ status: "ok", sent: 1, failed: 0, stale_cleaned: 0 });

  it("returns 405 for non-POST methods", async () => {
    const req = new Request("http://localhost/send-push-notification", {
      method: "GET",
      headers: authHeaders,
    });
    const res = await handleRequest(req, SERVICE_KEY, successFn);
    assertEquals(res.status, 405);
  });

  it("returns 401 when Authorization header is missing", async () => {
    const req = new Request("http://localhost/send-push-notification", {
      method: "POST",
    });
    const res = await handleRequest(req, SERVICE_KEY, successFn);
    assertEquals(res.status, 401);
  });

  it("returns 401 when token is wrong", async () => {
    const req = new Request("http://localhost/send-push-notification", {
      method: "POST",
      headers: { Authorization: "Bearer wrong-key" },
    });
    const res = await handleRequest(req, SERVICE_KEY, successFn);
    assertEquals(res.status, 401);
  });

  it("returns 400 for invalid JSON body", async () => {
    const req = new Request("http://localhost/send-push-notification", {
      method: "POST",
      headers: { ...authHeaders, "Content-Type": "application/json" },
      body: "not json",
    });
    const res = await handleRequest(req, SERVICE_KEY, successFn);
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "Invalid JSON body");
  });

  it("returns 400 when conversation_id is missing", async () => {
    const req = new Request("http://localhost/send-push-notification", {
      method: "POST",
      headers: { ...authHeaders, "Content-Type": "application/json" },
      body: JSON.stringify({ sender_id: "user-1" }),
    });
    const res = await handleRequest(req, SERVICE_KEY, successFn);
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "Missing conversation_id or sender_id");
  });

  it("returns 400 when sender_id is missing", async () => {
    const req = new Request("http://localhost/send-push-notification", {
      method: "POST",
      headers: { ...authHeaders, "Content-Type": "application/json" },
      body: JSON.stringify({ conversation_id: "conv-1" }),
    });
    const res = await handleRequest(req, SERVICE_KEY, successFn);
    assertEquals(res.status, 400);
  });

  it("returns 200 with result on success", async () => {
    const req = new Request("http://localhost/send-push-notification", {
      method: "POST",
      headers: { ...authHeaders, "Content-Type": "application/json" },
      body: JSON.stringify({
        message_id: "msg-1",
        conversation_id: "conv-1",
        sender_id: "user-1",
        text: "Hello!",
        type: "text",
      }),
    });
    const res = await handleRequest(req, SERVICE_KEY, successFn);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.status, "ok");
    assertEquals(body.sent, 1);
  });

  it("returns 500 when processor throws", async () => {
    const req = new Request("http://localhost/send-push-notification", {
      method: "POST",
      headers: { ...authHeaders, "Content-Type": "application/json" },
      body: JSON.stringify({
        message_id: "msg-1",
        conversation_id: "conv-1",
        sender_id: "user-1",
        text: "Hello!",
        type: "text",
      }),
    });
    const res = await handleRequest(req, SERVICE_KEY, () =>
      Promise.reject(new Error("FCM unavailable")),
    );
    assertEquals(res.status, 500);
    const body = await res.json();
    assertEquals(body.status, "error");
    assertEquals(body.message, "FCM unavailable");
  });
});

// ---------------------------------------------------------------------------
// Tests — recipient resolution logic
// ---------------------------------------------------------------------------

describe("recipient resolution", () => {
  function resolveRecipient(
    senderId: string,
    buyerId: string,
    sellerId: string,
  ): string {
    return senderId === buyerId ? sellerId : buyerId;
  }

  it("returns seller when sender is buyer", () => {
    assertEquals(resolveRecipient("buyer-1", "buyer-1", "seller-1"), "seller-1");
  });

  it("returns buyer when sender is seller", () => {
    assertEquals(resolveRecipient("seller-1", "buyer-1", "seller-1"), "buyer-1");
  });
});

// ---------------------------------------------------------------------------
// Tests — notification title formatting
// ---------------------------------------------------------------------------

describe("notification title", () => {
  function formatTitle(senderName: string, type: string): string {
    return type === "offer"
      ? `${senderName} sent an offer`
      : `${senderName} sent a message`;
  }

  it("formats offer message title", () => {
    assertEquals(formatTitle("Jan", "offer"), "Jan sent an offer");
  });

  it("formats text message title", () => {
    assertEquals(formatTitle("Jan", "text"), "Jan sent a message");
  });

  it("formats system_alert as generic message", () => {
    assertEquals(formatTitle("Jan", "system_alert"), "Jan sent a message");
  });
});

// ---------------------------------------------------------------------------
// Tests — body truncation
// ---------------------------------------------------------------------------

describe("body truncation", () => {
  function truncateBody(text: string): string {
    return text.length > 100 ? `${text.slice(0, 97)}...` : text;
  }

  it("keeps short text as-is", () => {
    assertEquals(truncateBody("Hello!"), "Hello!");
  });

  it("truncates text over 100 chars", () => {
    const long = "a".repeat(150);
    const result = truncateBody(long);
    assertEquals(result.length, 100);
    assertEquals(result.endsWith("..."), true);
  });

  it("keeps exactly 100 chars as-is", () => {
    const exact = "b".repeat(100);
    assertEquals(truncateBody(exact), exact);
  });
});
