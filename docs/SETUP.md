# Bubble — backend setup guide

Everything below uses Supabase's **free tier**. Total time: ~10 minutes.

## 1. Create the project

1. Go to [supabase.com](https://supabase.com) → **Start your project** → sign in.
2. **New project** → name it `bubble-chat` (any name works), set a database password, pick the region closest to you → **Create new project**. Wait ~2 minutes.

## 2. Run the schema

1. In your project dashboard, open **SQL Editor** (left sidebar).
2. Open the file [`SCHEMA.sql`](SCHEMA.sql) from this repo, copy its entire contents.
3. Paste into the SQL Editor → **Run**. You should see "Success".
4. This creates: `profiles`, `conversations`, `messages`, `reactions`, `poll_votes`, `statuses`, `status_views`, `blocks` tables, all security policies, the realtime feeds, and the `chat-images` storage bucket.

## 3. Configure auth

1. Go to **Authentication → Providers** → enable **Email**.
2. Go to **Authentication → Sign In / Sign Up** → turn **OFF** "Confirm email" so users can log in instantly (no email step).

## 4. Get your keys

1. Go to **Project Settings → Data API**.
2. Copy the **Project URL** (looks like `https://xyzcompany.supabase.co`).
3. Copy the **Publishable key** (starts with `sb_publishable_…`). This key is public by design — it's meant to live in frontend code.

## 5. Point the app at your backend

Open `index.html`, find these two lines near the top of the script:

```js
const SUPABASE_URL = "https://mhgsygzxmzvddujozyed.supabase.co";
const SUPABASE_KEY = "sb_publishable_…";
```

Replace with your URL and publishable key. Save.

## 6. Host it

`index.html` is a complete static file — host it anywhere:

- **Hugging Face Static Spaces** (free): new Space → SDK `Static` → upload `index.html`
- **GitHub Pages**: push to a repo → Settings → Pages
- **Netlify / Vercel / Cloudflare Pages**: drag-and-drop the file
- Any static web host or even `python3 -m http.server` locally

Open the hosted URL on two devices/browsers, create two accounts, add each other by username — you're chatting.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Signup says "Signups not allowed" | Auth → Providers → enable **Email** |
| Login asks for email confirmation | Turn **OFF** "Confirm email" |
| Photos won't send | Re-run the storage section (Part 5) of `SCHEMA.sql`; check the `chat-images` bucket exists under Storage |
| Messages don't arrive live | Check the realtime publication block (Part 4) ran; tables must be listed under Database → Replication |
| "You can't message this contact" for everyone | You (or a test) created a `blocks` row — check the `blocks` table and delete it |
