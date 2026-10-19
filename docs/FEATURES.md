# Bubble — complete feature reference

## 💬 Messaging
- **Real-time 1:1 chat** — messages arrive instantly via Supabase Realtime; 5-second poll fallback if the socket drops.
- **Message types** — text, photos (compressed client-side), voice notes (record in-browser, webm), polls, call logs, deleted tombstones.
- **Quote-reply** — reply to any message; quoted block shows sender + snippet, click jumps to the original.
- **Emoji reactions** — hover/long-press → 6 quick emojis; one reaction per user per message; live count chips.
- **Forward** — pick a chat, resend any message with a "Forwarded" label.
- **Delete for everyone** — sender-only; both sides see "This message was deleted".
- **Ticks** — ✓ sent, ✓✓ delivered (peer online), blue ✓✓ read. Read-receipts toggle in Settings disables both directions.
- **Typing indicators & online presence** — live via Realtime presence.
- **Unread badges** — coral count pills per chat; muted chats stay quiet.
- **Day dividers** — Today / Yesterday / date separators in chat history.
- **Message info** — click your ticks → Sent / Read timestamps.
- **Search** — in-chat search + global search across all conversations with highlighted jumps.
- **Export chat** — download any conversation as plain `.txt`.

## 📞📹 Calls
- **Voice & video calls** — true peer-to-peer WebRTC; signaling over Supabase Broadcast (no call server).
- Incoming call modal with ringtone, accept/decline, 30s no-answer timeout, busy auto-decline.
- In-call: mute, camera on/off, live timer, remote fullscreen + local picture-in-picture.
- Call history rows in chat ("📞 Voice call • 2:05", "✕ Missed voice call"), tap to call back.
- Offline peer → "not online" toast instead of a dead call.

## ⭕ Status
- Post **text** (6 background colors) or **photo** statuses.
- 24-hour auto-expiry; story rings (coral = unviewed, gray = viewed).
- Fullscreen viewer with progress bars, tap navigation.
- **Viewed-by sheet** — tap the 👁 count on your status to see exactly who viewed it (name, photo, "2h ago"), updating live.
- **Reply to a status** — reply bar in the viewer; arrives in chat with a mini status preview card.
- **React to a status** — 6 quick emojis; owner sees live reaction chips and who reacted.

## ✨ Bubble-only extras
| Feature | Notes |
|---|---|
| 🎨 Per-chat themes | 6 bubble colors + wallpaper tints per conversation; saved in the DB, synced live to both people |
| 🌍 Translate | Any message → your language via free keyless API; target language in Settings |
| 📊 Polls | Question + 2–4 options; one vote per user, change anytime; live % bars for both sides |

## 🔒 Privacy & safety
- **Block/unblock** — enforced by a *restrictive* database policy: a blocked user physically cannot insert messages or reach you by call. Block list stays private (you never see who blocked you).
- **Change password**, **log out**, per-chat **mute**.
- **Confirm before destroy** — clear chat and delete chat always ask for confirmation first.
- All data access governed by Postgres Row Level Security — users can only ever touch their own conversations.

## 🗂️ Organization
- **Pin** chats to the top · **Archive** to a collapsible section · **Mute** notifications per chat.
- Contact-info drawer (tap the chat header): bio, shared-media gallery with lightbox, quick actions.

## 👤 Profiles & settings
- Display name, @username, bio, **profile photo** (upload, shown everywhere) or 8 avatar colors — edited in Settings, synced to the other side.
- Appearance: dark mode, chat wallpapers (tints + doodle patterns), 3 font sizes.
- Notifications: message sound toggle + test-sound button. Account: invite-friends link, logout.
- Guided profile setup right after signup.

## 🔊 Sounds
- Message notification pops (WebAudio, no files needed), incoming-call ringtone, **outgoing ring-ring while your call connects**.
