-- VYRO initial Supabase schema. Run in Supabase SQL Editor on a NEW project.
-- Never put the service_role key in browser code. This schema does not implement payouts.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[a-zA-Z0-9_.]{3,24}$'),
  display_name text not null default '' check (char_length(display_name) <= 40),
  bio text not null default '' check (char_length(bio) <= 160),
  locale text not null default 'de' check (locale in ('de','en','it')),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.videos (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles(id) on delete cascade,
  caption text not null default '' check (char_length(caption) <= 180),
  category text not null default 'other' check (category in ('comedy','music','sports','gaming','travel','food','education','beauty','business','news','art','other')),
  content_language text not null default 'en' check (content_language in ('de','en','it','und')),
  video_path text not null,
  thumbnail_path text,
  visibility text not null default 'public' check (visibility in ('public','unlisted','private')),
  moderation_status text not null default 'pending' check (moderation_status in ('pending','approved','rejected')),
  locale text not null default 'de' check (locale in ('de','en','it')),
  created_at timestamptz not null default now()
);

create table if not exists public.video_likes (
  user_id uuid not null references public.profiles(id) on delete cascade,
  video_id uuid not null references public.videos(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, video_id)
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  video_id uuid not null references public.videos(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 500),
  moderation_status text not null default 'pending' check (moderation_status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  followed_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followed_id),
  check (follower_id <> followed_id)
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  video_id uuid references public.videos(id) on delete cascade,
  comment_id uuid references public.comments(id) on delete cascade,
  reason text not null check (char_length(reason) between 3 and 500),
  status text not null default 'open' check (status in ('open','reviewing','resolved','dismissed')),
  created_at timestamptz not null default now(),
  check ((video_id is not null)::int + (comment_id is not null)::int = 1)
);

create index if not exists videos_feed_idx on public.videos (created_at desc) where moderation_status = 'approved' and visibility = 'public';
create index if not exists comments_video_idx on public.comments (video_id, created_at asc);
create index if not exists reports_status_idx on public.reports (status, created_at desc);

alter table public.profiles enable row level security;
alter table public.videos enable row level security;
alter table public.video_likes enable row level security;
alter table public.comments enable row level security;
alter table public.follows enable row level security;
alter table public.user_blocks enable row level security;
alter table public.reports enable row level security;

-- Profiles are public, but only the owner can modify their profile.
drop policy if exists "Profiles readable" on public.profiles;
create policy "Profiles readable" on public.profiles for select using (true);
drop policy if exists "Owner creates profile" on public.profiles;
create policy "Owner creates profile" on public.profiles for insert to authenticated with check (auth.uid() = id);
drop policy if exists "Owner updates profile" on public.profiles;
create policy "Owner updates profile" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Public feed exposes only approved public videos. Owners can see their own pending/rejected rows.
drop policy if exists "Approved public videos or own videos" on public.videos;
create policy "Approved public videos or own videos" on public.videos for select using ((visibility = 'public' and moderation_status = 'approved') or creator_id = auth.uid());
drop policy if exists "Creator inserts own videos" on public.videos;
create policy "Creator inserts own videos" on public.videos for insert to authenticated with check (creator_id = auth.uid() and moderation_status = 'pending');
drop policy if exists "Creator deletes own videos" on public.videos;
create policy "Creator deletes own videos" on public.videos for delete to authenticated using (creator_id = auth.uid());
-- No client update policy for moderation_status: moderation should run server-side only.

-- Likes are readable for counts, and users may only add/remove their own likes.
drop policy if exists "Likes readable" on public.video_likes;
create policy "Likes readable" on public.video_likes for select using (true);
drop policy if exists "Users add own likes" on public.video_likes;
create policy "Users add own likes" on public.video_likes for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "Users remove own likes" on public.video_likes;
create policy "Users remove own likes" on public.video_likes for delete to authenticated using (user_id = auth.uid());

-- Approved comments are public; owners can see their own pending comments.
drop policy if exists "Approved comments or own comments" on public.comments;
create policy "Approved comments or own comments" on public.comments for select using (moderation_status = 'approved' or author_id = auth.uid());
drop policy if exists "Users create own pending comments" on public.comments;
create policy "Users create own pending comments" on public.comments for insert to authenticated with check (author_id = auth.uid() and moderation_status = 'pending');
drop policy if exists "Authors delete own comments" on public.comments;
create policy "Authors delete own comments" on public.comments for delete to authenticated using (author_id = auth.uid());

-- Follow relationships can be read; each user manages only their own outgoing follows.
drop policy if exists "Follows readable" on public.follows;
create policy "Follows readable" on public.follows for select using (true);
drop policy if exists "Users follow as themselves" on public.follows;
create policy "Users follow as themselves" on public.follows for insert to authenticated with check (follower_id = auth.uid());
drop policy if exists "Users unfollow as themselves" on public.follows;
create policy "Users unfollow as themselves" on public.follows for delete to authenticated using (follower_id = auth.uid());

-- Users can manage only blocks they create; block lists are private to the blocker.
drop policy if exists "Users read own blocks" on public.user_blocks;
create policy "Users read own blocks" on public.user_blocks for select to authenticated using (blocker_id = auth.uid());
drop policy if exists "Users create own blocks" on public.user_blocks;
create policy "Users create own blocks" on public.user_blocks for insert to authenticated with check (blocker_id = auth.uid());
drop policy if exists "Users remove own blocks" on public.user_blocks;
create policy "Users remove own blocks" on public.user_blocks for delete to authenticated using (blocker_id = auth.uid());

-- Reports are private to their reporter. Admin review must use a trusted server/admin role.
drop policy if exists "Users create own reports" on public.reports;
create policy "Users create own reports" on public.reports for insert to authenticated with check (reporter_id = auth.uid());
drop policy if exists "Reporters read own reports" on public.reports;
create policy "Reporters read own reports" on public.reports for select to authenticated using (reporter_id = auth.uid());

-- Global launch notes: serve media through an appropriate CDN, apply regional privacy/legal review,
-- age safeguards, copyright/takedown workflows, rate limits, anti-spam and server-side moderation.
-- Never publish pending uploads. Do not use demo/local likes as payment or reward evidence.

-- Create a private storage bucket named "videos" in the Supabase dashboard.
-- Suggested object path: <auth.uid()>/<random-uuid>.mp4
-- Storage policies should restrict upload/delete to the authenticated owner's folder.
-- Do not enable public uploads or store payment credentials / service keys in the client.
