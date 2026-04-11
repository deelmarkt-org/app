/**
 * PagerDuty Events API v2 integration.
 * M7: Logs full alert content as fallback if PagerDuty is unreachable.
 */
export async function triggerPagerDuty(
  routingKey: string,
  summary: string,
  severity: "critical" | "error" | "warning" | "info",
  details: Record<string, unknown>,
  options?: { source?: string; dedupKey?: string; component?: string },
): Promise<void> {
  const payload: Record<string, unknown> = {
    routing_key: routingKey,
    event_action: "trigger",
    payload: {
      summary: `[DeelMarkt] ${summary}`,
      source: options?.source ?? "edge-function",
      severity,
      ...(options?.component ? { component: options.component } : {}),
      custom_details: details,
    },
  };

  if (options?.dedupKey) {
    payload.dedup_key = options.dedupKey;
  }

  try {
    const response = await fetch("https://events.pagerduty.com/v2/enqueue", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      console.error(
        `[pagerduty] ALERT DELIVERY FAILED — PagerDuty returned ${response.status}. ` +
          `Original alert: ${summary}. Details: ${JSON.stringify(details)}`,
      );
    }
  } catch (err) {
    console.error(
      `[pagerduty] ALERT DELIVERY FAILED — PagerDuty unreachable: ${
        (err as Error).message
      }. ` +
        `Original alert: ${summary}. Details: ${JSON.stringify(details)}`,
    );
  }
}
