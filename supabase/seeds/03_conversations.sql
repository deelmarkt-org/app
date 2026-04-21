-- ──────────────────────────────────────────────────────────────────────────
-- DeelMarkt — Local dev seed: conversations + messages
--
-- Two conversations so the chat tab has something to render and realtime
-- subscriptions have real rows to stream.
--
-- buyer-l2 (11...12) ↔ seller-kyc2 (22...22) about the iPhone (a1...01)
-- buyer-l0 (11...11) ↔ seller-kyc2 (22...22) about the Air Max (a1...03)
-- ──────────────────────────────────────────────────────────────────────────

INSERT INTO conversations (id, listing_id, buyer_id, created_at, last_message_at) VALUES
  ('b0000000-0000-0000-0000-000000000001',
   'a1111111-0000-0000-0000-000000000001',
   '11111111-1111-1111-1111-111111111112',
   now() - interval '2 days', now() - interval '1 hour'),
  ('b0000000-0000-0000-0000-000000000002',
   'a1111111-0000-0000-0000-000000000003',
   '11111111-1111-1111-1111-111111111111',
   now() - interval '1 day', now() - interval '30 minutes')
ON CONFLICT (id) DO NOTHING;

INSERT INTO messages (id, conversation_id, sender_id, text, type, is_read, created_at) VALUES
  -- iPhone conversation
  ('b1111111-0000-0000-0000-000000000001',
   'b0000000-0000-0000-0000-000000000001',
   '11111111-1111-1111-1111-111111111112',
   'Hi! Is the iPhone still available?', 'text', true,
   now() - interval '2 days'),
  ('b1111111-0000-0000-0000-000000000002',
   'b0000000-0000-0000-0000-000000000001',
   '22222222-2222-2222-2222-222222222222',
   'Yes, still for sale. Battery health is 92%.', 'text', true,
   now() - interval '2 days' + interval '15 minutes'),
  ('b1111111-0000-0000-0000-000000000003',
   'b0000000-0000-0000-0000-000000000001',
   '11111111-1111-1111-1111-111111111112',
   'Would you accept €600?', 'text', false,
   now() - interval '1 hour'),

  -- Air Max conversation
  ('b1111111-0000-0000-0000-000000000011',
   'b0000000-0000-0000-0000-000000000002',
   '11111111-1111-1111-1111-111111111111',
   'Would these fit a European 42?', 'text', true,
   now() - interval '1 day'),
  ('b1111111-0000-0000-0000-000000000012',
   'b0000000-0000-0000-0000-000000000002',
   '22222222-2222-2222-2222-222222222222',
   'They run a touch small — I''d say closer to 42.5.', 'text', false,
   now() - interval '30 minutes')
ON CONFLICT (id) DO NOTHING;
