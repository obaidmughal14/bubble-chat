-- ============================================================================
-- BUBBLE CHAT — complete database schema
-- Run once in your Supabase project's SQL Editor (top to bottom).
-- Creates every table, helper, RLS policy, realtime feed and storage bucket
-- the app needs. Safe to re-run: every statement is idempotent.
-- ============================================================================

-- --------------------------------------------------------------------------
-- PART 1: TABLES
-- --------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text not null,
  avatar_color text not null default '#FF6B4A',
  bio text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  participant_a uuid not null references public.profiles(id) on delete cascade,
  participant_b uuid not null references public.profiles(id) on delete cascade,
  theme jsonb,
  pinned boolean not null default false,
  archived boolean not null default false,
  muted boolean not null default false,
  created_at timestamptz not null default now(),
  unique (participant_a, participant_b),
  check (participant_a < participant_b)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null default '',
  image_url text,
  audio_url text,
  kind text not null default 'text',          -- text | image | voice | poll | call | deleted
  poll jsonb,                                  -- {question, options:[{id,text}]}
  reply_to_id uuid references public.messages(id) on delete set null,
  is_forwarded boolean not null default false,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists messages_conversation_idx
  on public.messages (conversation_id, created_at);

create table if not exists public.reactions (
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  emoji text not null,
  created_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

create table if not exists public.poll_votes (
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  option_id text not null,
  created_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

create table if not exists public.statuses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null default 'text',           -- text | image
  body text not null default '',
  image_url text,
  bg text,
  created_at timestamptz not null default now()
);

create table if not exists public.status_views (
  status_id uuid not null references public.statuses(id) on delete cascade,
  viewer_id uuid not null references public.profiles(id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (status_id, viewer_id)
);

create table if not exists public.blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

-- --------------------------------------------------------------------------
-- PART 2: HELPER FUNCTIONS (security definer = they can see past RLS safely)
-- --------------------------------------------------------------------------

create or replace function public.is_participant(conv_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.conversations
    where id = conv_id
    and (participant_a = auth.uid() or participant_b = auth.uid()));
$$;

-- True when the *other* person in this conversation has blocked the caller.
-- Used by the restrictive block policy. SECURITY DEFINER because the blocks
-- table is private (you can't see who blocked you).
create or replace function public.is_blocked_by_other(conv_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.blocks b
    join public.conversations c on c.id = conv_id
    where b.blocked_id = auth.uid()
      and b.blocker_id = (
        case when c.participant_a = auth.uid()
             then c.participant_b
             else c.participant_a end
      )
  );
$$;

-- --------------------------------------------------------------------------
-- PART 3: ROW LEVEL SECURITY
-- --------------------------------------------------------------------------

alter table public.profiles      enable row level security;
alter table public.conversations enable row level security;
alter table public.messages      enable row level security;
alter table public.reactions     enable row level security;
alter table public.poll_votes    enable row level security;
alter table public.statuses      enable row level security;
alter table public.status_views  enable row level security;
alter table public.blocks        enable row level security;

-- profiles --
drop policy if exists "profiles readable" on public.profiles;
create policy "profiles readable" on public.profiles
  for select to authenticated using (true);
drop policy if exists "users insert own profile" on public.profiles;
create policy "users insert own profile" on public.profiles
  for insert to authenticated with check (id = auth.uid());
drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile" on public.profiles
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- conversations --
drop policy if exists "participants read conversations" on public.conversations;
create policy "participants read conversations" on public.conversations
  for select to authenticated
  using (participant_a = auth.uid() or participant_b = auth.uid());
drop policy if exists "users create own conversations" on public.conversations;
create policy "users create own conversations" on public.conversations
  for insert to authenticated
  with check (participant_a = auth.uid() or participant_b = auth.uid());
drop policy if exists "participants update conversation" on public.conversations;
create policy "participants update conversation" on public.conversations
  for update to authenticated
  using (participant_a = auth.uid() or participant_b = auth.uid())
  with check (participant_a = auth.uid() or participant_b = auth.uid());

-- messages --
drop policy if exists "participants read messages" on public.messages;
create policy "participants read messages" on public.messages
  for select to authenticated using (public.is_participant(conversation_id));
drop policy if exists "participants send messages" on public.messages;
create policy "participants send messages" on public.messages
  for insert to authenticated
  with check (public.is_participant(conversation_id) and sender_id = auth.uid());
-- RESTRICTIVE: denied even if every permissive policy above allows it.
drop policy if exists "no send when blocked" on public.messages;
create policy "no send when blocked" on public.messages
  as restrictive for insert to authenticated
  with check (not public.is_blocked_by_other(conversation_id));
drop policy if exists "recipients mark read" on public.messages;
create policy "recipients mark read" on public.messages
  for update to authenticated
  using (public.is_participant(conversation_id) and sender_id <> auth.uid())
  with check (public.is_participant(conversation_id));
drop policy if exists "senders edit own messages" on public.messages;
create policy "senders edit own messages" on public.messages
  for update to authenticated
  using (public.is_participant(conversation_id) and sender_id = auth.uid())
  with check (public.is_participant(conversation_id) and sender_id = auth.uid());
drop policy if exists "senders delete own messages" on public.messages;
create policy "senders delete own messages" on public.messages
  for delete to authenticated
  using (public.is_participant(conversation_id) and sender_id = auth.uid());

-- reactions --
drop policy if exists "participants read reactions" on public.reactions;
create policy "participants read reactions" on public.reactions for select to authenticated
  using (exists (select 1 from public.messages m where m.id = reactions.message_id and public.is_participant(m.conversation_id)));
drop policy if exists "participants manage own reactions" on public.reactions;
create policy "participants manage own reactions" on public.reactions for all to authenticated
  using (user_id = auth.uid() and exists (select 1 from public.messages m where m.id = reactions.message_id and public.is_participant(m.conversation_id)))
  with check (user_id = auth.uid() and exists (select 1 from public.messages m where m.id = reactions.message_id and public.is_participant(m.conversation_id)));

-- poll votes --
drop policy if exists "participants read poll_votes" on public.poll_votes;
create policy "participants read poll_votes" on public.poll_votes for select to authenticated
  using (exists (select 1 from public.messages m where m.id = poll_votes.message_id and public.is_participant(m.conversation_id)));
drop policy if exists "participants vote" on public.poll_votes;
create policy "participants vote" on public.poll_votes for insert to authenticated
  with check (user_id = auth.uid() and exists (select 1 from public.messages m where m.id = poll_votes.message_id and public.is_participant(m.conversation_id)));
drop policy if exists "participants change vote" on public.poll_votes;
create policy "participants change vote" on public.poll_votes for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "participants unvote" on public.poll_votes;
create policy "participants unvote" on public.poll_votes for delete to authenticated using (user_id = auth.uid());

-- statuses (visible to you + people you chat with) --
drop policy if exists "visible statuses" on public.statuses;
create policy "visible statuses" on public.statuses for select to authenticated
  using (user_id = auth.uid() or exists (
    select 1 from public.conversations c
    where (c.participant_a = auth.uid() and c.participant_b = statuses.user_id)
       or (c.participant_b = auth.uid() and c.participant_a = statuses.user_id)));
drop policy if exists "post own status" on public.statuses;
create policy "post own status" on public.statuses for insert to authenticated
  with check (user_id = auth.uid());
drop policy if exists "delete own status" on public.statuses;
create policy "delete own status" on public.statuses for delete to authenticated
  using (user_id = auth.uid());

-- status views --
drop policy if exists "view receipts" on public.status_views;
create policy "view receipts" on public.status_views for select to authenticated
  using (viewer_id = auth.uid()
    or exists (select 1 from public.statuses s where s.id = status_views.status_id and s.user_id = auth.uid()));
drop policy if exists "mark viewed" on public.status_views;
create policy "mark viewed" on public.status_views for insert to authenticated
  with check (viewer_id = auth.uid());

-- blocks (private: you only ever see your own block list) --
drop policy if exists "own blocks" on public.blocks;
create policy "own blocks" on public.blocks for all to authenticated
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

-- --------------------------------------------------------------------------
-- PART 4: REALTIME (live updates pushed to the app)
-- --------------------------------------------------------------------------

do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages') then
    alter publication supabase_realtime add table public.messages; end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'reactions') then
    alter publication supabase_realtime add table public.reactions; end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'poll_votes') then
    alter publication supabase_realtime add table public.poll_votes; end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'statuses') then
    alter publication supabase_realtime add table public.statuses; end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'conversations') then
    alter publication supabase_realtime add table public.conversations; end if;
end $$;

-- --------------------------------------------------------------------------
-- PART 5: STORAGE (photo / voice-note / status uploads)
-- --------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('chat-images', 'chat-images', true)
on conflict (id) do nothing;

drop policy if exists "authenticated upload chat images" on storage.objects;
create policy "authenticated upload chat images" on storage.objects
  for insert to authenticated with check (bucket_id = 'chat-images');
drop policy if exists "read chat images" on storage.objects;
create policy "read chat images" on storage.objects
  for select to authenticated using (bucket_id = 'chat-images');

-- ============================================================================
-- DONE. Next: Supabase Dashboard → Authentication → Providers → enable Email,
-- and turn OFF "Confirm email" so users can log in instantly.
-- ============================================================================
