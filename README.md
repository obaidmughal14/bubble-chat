# 🫧 Bubble — Chat that pops.

**Live demo:** https://obaidasiaone-whatsapp-web-clone.static.hf.space

Bubble is a complete, real-time chat app inspired by WhatsApp — with real user accounts, a real Postgres database, voice & video calls, Status updates, and a few features even WhatsApp doesn't have. One HTML file. Zero build step. Free to run.

## Features

**Messaging**
- Real-time 1:1 chat (Supabase Realtime — no refresh needed)
- Text, photos, voice notes (record & play in-chat)
- Quote-replies, emoji reactions, forward messages, delete-for-everyone
- Sent → delivered → read ticks (✓ → ✓✓ → blue ✓✓), typing indicators, online presence
- In-chat search, global search across all chats, export any chat as `.txt`

**Calls**
- Voice & video calls (WebRTC, peer-to-peer — no call server needed)
- Ringing, accept/decline, mute, camera toggle, call timer, call history in chat

**Status**
- Post text (with colors) or photo statuses, 24-hour auto-expiry
- Story rings (coral = unviewed), fullscreen viewer, view counts

**Bubble-only extras** (not in WhatsApp)
- 🎨 Per-chat themes — custom bubble colors per conversation, synced to both people
- 🌍 In-chat message translation (free, no API key)
- 📊 Polls with live vote counts

**Privacy & organization**
- Block/unblock — enforced at the *database* level: blocked users cannot message or call you, period
- Pin, archive, mute chats · unread count badges · day dividers · message info (sent/read times)
- Read-receipts toggle, per-chat notification mute, change password

**Personalization**
- Profile (name, bio, avatar color), dark mode, chat wallpapers, 3 font sizes
- Contact-info drawer with shared-media gallery

## Tech stack

| Layer | Choice |
|---|---|
| Frontend | Single `index.html` — vanilla JS + CSS, no framework, no build |
| Database | Supabase (free tier): Postgres + Row Level Security |
| Realtime | Supabase Realtime (messages, reactions, votes, statuses, themes) |
| Calls | WebRTC P2P + Supabase Broadcast signaling, free STUN |
| Uploads | Supabase Storage (`chat-images` bucket) |
| Translation | Google translate endpoint (free, keyless) |
| Hosting | Any static host (live on Hugging Face Static Spaces) |

## Run it yourself

1. **Use it instantly:** open the live demo link above, create an account, pick a username — done.
2. **Self-host with your own backend:** see [docs/SETUP.md](docs/SETUP.md) — create a free Supabase project, run [docs/SCHEMA.sql](docs/SCHEMA.sql) once, paste your project URL + publishable key into the two `const` lines at the top of `index.html`, and host the file anywhere static.

## Project structure

```
bubble-chat/
├── index.html          # the entire app (v5, ~192KB)
├── docs/
│   ├── SETUP.md        # backend setup guide
│   ├── SCHEMA.sql      # complete database schema (run once)
│   ├── FEATURES.md     # full feature reference
│   └── ARCHITECTURE.md # how it all works
└── LICENSE             # MIT
```

## Honest limits

- No end-to-end encryption (messages are protected by database access rules, not E2EE)
- Calls need both users online with the app open; very restrictive corporate networks may fail (no paid TURN relay)
- No push notifications when the app is closed
- Translation uses a free unofficial endpoint — generous, but not SLA-backed

## License

MIT — do whatever you want with it.
