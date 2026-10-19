# Bubble — architecture

## The big idea

The entire app is **one HTML file** (`index.html`, ~192KB): HTML + CSS + vanilla JS, no framework, no build step, no npm. It talks directly to Supabase from the browser. Hosting = serving a static file.

```
┌─────────────┐         HTTPS          ┌──────────────────┐
│  index.html │ ◄────────────────────► │    Supabase      │
│  (browser)  │                        │  ┌────────────┐  │
└─────────────┘                        │  │  Postgres  │  │
        │  WebRTC media (P2P)          │  │  + RLS      │  │
        └────────────────────────────► │  ├────────────┐  │
              (browser to browser)     │  │ Realtime   │  │
                                       │  ├────────────┐  │
                                       │  │ Storage    │  │
                                       │  └────────────┘  │
                                       └──────────────────┘
```

## Data model

- **profiles** — one row per user (`id` = auth user id): username (unique), display_name, avatar_color, bio.
- **conversations** — 1:1 chats. `participant_a < participant_b` (canonical ordering) + unique pair = one conversation per pair, no duplicates. Carries `theme`, `pinned`, `archived`, `muted`.
- **messages** — `kind` discriminates: `text | image | voice | poll | call | deleted`. Media lives in Storage; the row holds the URL. `reply_to_id` self-FK for quotes, `poll` JSONB for polls, `read_at` for blue ticks.
- **reactions** / **poll_votes** — one row per (message, user); votes are upserted so re-voting moves the vote.
- **statuses** / **status_views** — 24h-filtered story system with view receipts.
- **blocks** — `(blocker_id, blocked_id)`; private by RLS (you only see your own list).

## Security model (RLS)

Every table has Row Level Security. The two load-bearing pieces:

1. **`is_participant(conv_id)`** — `SECURITY DEFINER` helper; almost every policy builds on it, so users can only touch conversations they're in.
2. **Restrictive block policy** — `no send when blocked` is `AS RESTRICTIVE`: it must pass *in addition to* every permissive policy, so a blocked sender is denied even though other policies would allow the insert. It checks via `is_blocked_by_other()`, also `SECURITY DEFINER`, because the `blocks` table is intentionally invisible to anyone but the blocker (you can't see who blocked you).

## Realtime

- `postgres_changes` subscriptions on `messages`, `reactions`, `poll_votes`, `statuses`, `conversations` → new messages, chips, votes, stories, and theme/pin/archive changes push live.
- `presence` channels per conversation → online status, delivered ticks, typing indicators.
- `broadcast` channels per conversation → WebRTC call signaling (`call-offer`/`call-answer`/`ice`/`call-decline`/`call-end`). Media itself is peer-to-peer and never touches the server.
- 5-second polling fallback keeps chat working if the socket drops.

## Calls in brief

`getUserMedia` → `RTCPeerConnection` (free Google STUN, no TURN) → SDP/ICE exchanged over the broadcast channel → direct media. Full cleanup of tracks, peer connection, timers, and ringtone on every exit path. Honest limit: symmetric-NAT / strict corporate networks may fail without a paid TURN relay.

## Conventions in the code

- `sb` = Supabase client; `me` = current user; `msgById` = message cache.
- Sections are numbered comments (`/* ---------- 22. V3: … ---------- */`).
- Optimistic UI for sends; realtime events reconcile.
- All animations are transform/opacity-only with a `prefers-reduced-motion` guard.
- `localStorage` keys (`wa-clone-v3-*`) hold device prefs: theme, language, font size, wallpaper, receipt/sound toggles.
