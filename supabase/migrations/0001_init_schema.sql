-- ============================================================================
-- BEATIL — Phase 1 schema
-- ============================================================================

create extension if not exists "uuid-ossp";

create type user_role as enum ('producer', 'artist', 'admin');

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  role user_role not null,
  username text unique not null,
  display_name text,
  avatar_url text,
  bio text,
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.genres (
  id uuid primary key default uuid_generate_v4(),
  name text unique not null,
  slug text unique not null,
  created_at timestamptz not null default now()
);

create table public.producer_profiles (
  user_id uuid primary key references public.users(id) on delete cascade,
  genres uuid[] default '{}',
  followers_count integer not null default 0,
  total_plays integer not null default 0,
  beats_count integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.artist_profiles (
  user_id uuid primary key references public.users(id) on delete cascade,
  genres uuid[] default '{}',
  social_links jsonb default '{}',
  followers_count integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.beats (
  id uuid primary key default uuid_generate_v4(),
  producer_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  cover_url text,
  audio_url text not null,
  genre_id uuid references public.genres(id),
  bpm integer,
  musical_key text,
  mood text,
  energy smallint check (energy between 1 and 5),
  tags text[] default '{}',
  description text,
  plays_count integer not null default 0,
  likes_count integer not null default 0,
  saves_count integer not null default 0,
  shares_count integer not null default 0,
  trending_score numeric not null default 0,
  is_removed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index beats_producer_id_idx on public.beats(producer_id);
create index beats_genre_id_idx on public.beats(genre_id);
create index beats_trending_idx on public.beats(trending_score desc);

create table public.follows (
  follower_id uuid not null references public.users(id) on delete cascade,
  producer_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, producer_id)
);

create table public.likes (
  user_id uuid not null references public.users(id) on delete cascade,
  beat_id uuid not null references public.beats(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, beat_id)
);

create table public.saves (
  user_id uuid not null references public.users(id) on delete cascade,
  beat_id uuid not null references public.beats(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, beat_id)
);

create table public.shares (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  beat_id uuid not null references public.beats(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.conversations (
  id uuid primary key default uuid_generate_v4(),
  user_a uuid not null references public.users(id) on delete cascade,
  user_b uuid not null references public.users(id) on delete cascade,
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_a, user_b)
);

create table public.messages (
  id uuid primary key default uuid_generate_v4(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  content text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index messages_conversation_id_idx on public.messages(conversation_id);

create type notification_type as enum ('new_follower', 'like', 'message', 'new_beat');

create table public.notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  actor_id uuid references public.users(id) on delete set null,
  type notification_type not null,
  beat_id uuid references public.beats(id) on delete cascade,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index notifications_user_id_idx on public.notifications(user_id, is_read);

create table public.ai_analysis (
  beat_id uuid primary key references public.beats(id) on delete cascade,
  detected_bpm integer,
  detected_key text,
  detected_genre_id uuid references public.genres(id),
  detected_mood text,
  detected_energy smallint,
  raw_result jsonb,
  created_at timestamptz not null default now()
);

create table public.recommendations (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  beat_id uuid not null references public.beats(id) on delete cascade,
  score numeric not null default 0,
  reason text,
  created_at timestamptz not null default now()
);

create type license_type as enum ('basic', 'premium', 'exclusive');

create table public.licenses (
  id uuid primary key default uuid_generate_v4(),
  beat_id uuid not null references public.beats(id) on delete cascade,
  type license_type not null,
  price_cents integer not null,
  currency text not null default 'ILS',
  created_at timestamptz not null default now()
);

create table public.orders (
  id uuid primary key default uuid_generate_v4(),
  buyer_id uuid not null references public.users(id) on delete cascade,
  license_id uuid not null references public.licenses(id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

create table public.payments (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid not null references public.orders(id) on delete cascade,
  provider text,
  provider_payment_id text,
  amount_cents integer not null,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

create table public.subscriptions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  plan text not null,
  status text not null default 'active',
  current_period_end timestamptz,
  created_at timestamptz not null default now()
);

alter table public.users enable row level security;
alter table public.producer_profiles enable row level security;
alter table public.artist_profiles enable row level security;
alter table public.beats enable row level security;
alter table public.genres enable row level security;
alter table public.follows enable row level security;
alter table public.likes enable row level security;
alter table public.saves enable row level security;
alter table public.shares enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;

create policy "public read users" on public.users for select using (true);
create policy "public read producer_profiles" on public.producer_profiles for select using (true);
create policy "public read artist_profiles" on public.artist_profiles for select using (true);
create policy "public read genres" on public.genres for select using (true);
create policy "public read beats" on public.beats for select using (is_removed = false);

create policy "users update own row" on public.users
  for update using (auth.uid() = id);

create policy "producer edits own profile" on public.producer_profiles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "artist edits own profile" on public.artist_profiles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "producer manag
