-- movelet M0 — 초기 스키마
-- 설계 근거는 docs/product-plan.md 7장(데이터 모델)을 따른다.
-- 원칙: 모든 테이블 RLS 기본 차단(정책은 0002에서 부여), 권한 판정의 뿌리는 커뮤니티 멤버십 하나.

create extension if not exists "pgcrypto";

-- ─────────────────────────────────────────── enums

create type missionary_type as enum ('sent', 'self_supported', 'other');
create type community_kind  as enum ('church', 'agency', 'prayer', 'etc');
create type community_type  as enum ('private', 'open');
create type invite_policy   as enum ('owner', 'member');
create type member_role     as enum ('owner', 'member');
create type post_type       as enum ('prayer', 'testimony', 'share', 'photo');
create type reaction_kind   as enum ('prayed', 'amen');
create type cost_type       as enum ('free', 'actual_cost', 'paid');
create type stay_visibility as enum ('members', 'community', 'targeted');
create type stay_status     as enum ('draft', 'open', 'closed');
create type request_status  as enum ('pending', 'accepted', 'declined', 'cancelled');
create type report_status   as enum ('open', 'reviewing', 'resolved', 'dismissed');
create type report_target   as enum ('post', 'comment', 'profile', 'stay', 'community');

-- ─────────────────────────────────────────── 사람

-- 소속(출석) 교회는 전원 필수. 앱 화면에서만 막으면 우회 경로가 남으므로 DB에서 NOT NULL로 강제한다.
create table profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text        not null check (char_length(display_name) between 1 and 30),
  avatar_path  text,
  home_church  text        not null check (char_length(home_church) between 1 and 80),
  home_region  text,
  bio          text,
  is_missionary boolean    not null default false,
  is_admin      boolean    not null default false,
  verified_at   timestamptz,
  verified_by   uuid references profiles (id),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

comment on column profiles.is_admin is '선교사 인증 심사·광장 관리·신고 처리 권한. 사용자가 스스로 켤 수 없도록 0002의 트리거에서 잠근다.';
comment on column profiles.verified_at is '선교사 인증 승인 시각. 광장 글쓰기·후원 계좌 등록·숙소 요청을 여는 열쇠.';

create table missionary_info (
  profile_id       uuid primary key references profiles (id) on delete cascade,
  missionary_type  missionary_type not null,
  sending_church   text,
  agency           text,
  field_country    text,
  field_label      text,
  ministry_desc    text,
  is_location_hidden boolean not null default false,
  is_church_hidden   boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  -- 파송 선교사는 파송 교회가 필수다.
  constraint sending_church_required_when_sent
    check (missionary_type <> 'sent' or coalesce(char_length(trim(sending_church)), 0) > 0)
);

-- 사용자가 입력한 교회명을 누적하는 자동완성 사전. 마스터 데이터가 아니며 profiles.home_church는 이 표를 참조하지 않는다.
create table churches (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  region       text,
  denomination text,
  use_count    integer not null default 1,
  created_at   timestamptz not null default now()
);
create unique index churches_name_region_key on churches (name, coalesce(region, ''));

create table support_accounts (
  id             uuid primary key default gen_random_uuid(),
  missionary_id  uuid not null references profiles (id) on delete cascade,
  bank           text not null,
  holder         text not null,
  account_no     text not null,
  qr_path        text,
  note           text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index on support_accounts (missionary_id);

-- 후원 '사실'만 남기고 금액은 저장하지 않는다. 랭킹·목표 게이지를 만들지 않기 위한 의도적 제약.
create table support_logs (
  id            uuid primary key default gen_random_uuid(),
  missionary_id uuid not null references profiles (id) on delete cascade,
  supporter_id  uuid not null references profiles (id) on delete cascade,
  created_at    timestamptz not null default now()
);
create index on support_logs (missionary_id, created_at desc);

-- ─────────────────────────────────────────── 커뮤니티

create table communities (
  id            uuid primary key default gen_random_uuid(),
  name          text not null check (char_length(name) between 1 and 40),
  kind          community_kind not null default 'etc',
  description   text,
  cover_path    text,
  type          community_type not null default 'private',
  invite_policy invite_policy  not null default 'owner',
  created_by    uuid references profiles (id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

comment on table communities is '광장도 이 표의 한 행(type=open)이다. 특별 취급은 is_community_member() 한 곳에서만 분기한다.';

create table community_members (
  community_id uuid not null references communities (id) on delete cascade,
  user_id      uuid not null references profiles (id) on delete cascade,
  role         member_role not null default 'member',
  invited_by   uuid references profiles (id) on delete set null,
  joined_at    timestamptz not null default now(),
  primary key (community_id, user_id)
);
create index on community_members (user_id);

create table community_invites (
  id           uuid primary key default gen_random_uuid(),
  community_id uuid not null references communities (id) on delete cascade,
  code         text not null unique,
  created_by   uuid not null references profiles (id) on delete cascade,
  expires_at   timestamptz,
  max_uses     integer,
  used_count   integer not null default 0,
  revoked_at   timestamptz,
  created_at   timestamptz not null default now()
);
create index on community_invites (community_id);

-- ─────────────────────────────────────────── 피드

create table posts (
  id           uuid primary key default gen_random_uuid(),
  author_id    uuid not null references profiles (id) on delete cascade,
  type         post_type not null,
  body         text not null check (char_length(body) between 1 and 5000),
  is_answered  boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index on posts (author_id, created_at desc);

-- 한 글이 여러 방에 걸리므로 posts에 community_id를 두지 않는다.
create table post_targets (
  post_id      uuid not null references posts (id) on delete cascade,
  community_id uuid not null references communities (id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (post_id, community_id)
);
create index on post_targets (community_id, created_at desc);

create table post_media (
  id           uuid primary key default gen_random_uuid(),
  post_id      uuid not null references posts (id) on delete cascade,
  storage_path text not null,
  sort_order   integer not null default 0
);
create index on post_media (post_id, sort_order);

-- 댓글·반응에 community_id가 붙는 이유: 방마다 대화가 따로 쌓여야 한다. 없으면 A교회 댓글이 B교회에 보인다.
create table comments (
  id           uuid primary key default gen_random_uuid(),
  post_id      uuid not null references posts (id) on delete cascade,
  community_id uuid not null references communities (id) on delete cascade,
  author_id    uuid not null references profiles (id) on delete cascade,
  body         text not null check (char_length(body) between 1 and 2000),
  created_at   timestamptz not null default now(),
  -- 글이 실제로 그 방에 게시됐을 때만 그 방에 댓글이 달릴 수 있다.
  foreign key (post_id, community_id) references post_targets (post_id, community_id) on delete cascade
);
create index on comments (post_id, community_id, created_at);

create table reactions (
  post_id      uuid not null references posts (id) on delete cascade,
  community_id uuid not null references communities (id) on delete cascade,
  user_id      uuid not null references profiles (id) on delete cascade,
  kind         reaction_kind not null default 'prayed',
  created_at   timestamptz not null default now(),
  primary key (post_id, community_id, user_id),
  foreign key (post_id, community_id) references post_targets (post_id, community_id) on delete cascade
);

-- ─────────────────────────────────────────── 숙소 (커뮤니티가 아니라 앱 전역)

create table stays (
  id             uuid primary key default gen_random_uuid(),
  host_id        uuid not null references profiles (id) on delete cascade,
  title          text not null check (char_length(title) between 1 and 60),
  description    text,
  region_label   text not null,          -- 시·구 단위. 수락 전까지 게스트에게 보이는 유일한 위치 정보
  capacity       integer not null default 1 check (capacity between 1 and 20),
  available_from date,
  available_to   date,
  cost_type      cost_type not null default 'free',
  cost_amount    integer,
  house_rules    text,
  visibility     stay_visibility not null default 'members',
  status         stay_status not null default 'open',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  check (cost_type <> 'free' or cost_amount is null)
);
create index on stays (status, visibility);
create index on stays (host_id);

-- 상세 주소를 별도 표로 분리한 이유: RLS는 행 단위라 컬럼 하나만 가릴 수 없다.
-- 이 표는 호스트와 '수락된' 게스트에게만 열린다(정책은 0002).
create table stay_addresses (
  stay_id        uuid primary key references stays (id) on delete cascade,
  address_line   text not null,
  address_detail text,
  contact        text,
  updated_at     timestamptz not null default now()
);

create table stay_media (
  id           uuid primary key default gen_random_uuid(),
  stay_id      uuid not null references stays (id) on delete cascade,
  storage_path text not null,
  sort_order   integer not null default 0
);
create index on stay_media (stay_id, sort_order);

-- visibility='community' 또는 'targeted'일 때의 지정 공개 대상
create table stay_audience (
  id            uuid primary key default gen_random_uuid(),
  stay_id       uuid not null references stays (id) on delete cascade,
  community_id  uuid references communities (id) on delete cascade,
  missionary_id uuid references profiles (id) on delete cascade,
  check (num_nonnulls(community_id, missionary_id) = 1)
);
create index on stay_audience (stay_id);
create unique index on stay_audience (stay_id, community_id) where community_id is not null;
create unique index on stay_audience (stay_id, missionary_id) where missionary_id is not null;

create table stay_requests (
  id         uuid primary key default gen_random_uuid(),
  stay_id    uuid not null references stays (id) on delete cascade,
  guest_id   uuid not null references profiles (id) on delete cascade,
  message    text,
  date_from  date not null,
  date_to    date not null,
  headcount  integer not null default 1 check (headcount between 1 and 20),
  status     request_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (date_to >= date_from)
);
create index on stay_requests (stay_id, status);
create index on stay_requests (guest_id, created_at desc);
-- 같은 숙소에 대기 중인 요청은 하나만
create unique index on stay_requests (stay_id, guest_id) where status = 'pending';

-- ─────────────────────────────────────────── 운영

create table reports (
  id           uuid primary key default gen_random_uuid(),
  reporter_id  uuid not null references profiles (id) on delete cascade,
  community_id uuid references communities (id) on delete set null,
  target_type  report_target not null,
  target_id    uuid not null,
  reason       text not null,
  status       report_status not null default 'open',
  created_at   timestamptz not null default now()
);
create index on reports (status, created_at desc);

create table blocks (
  blocker_id uuid not null references profiles (id) on delete cascade,
  blocked_id uuid not null references profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references profiles (id) on delete cascade,
  type       text not null,
  payload    jsonb not null default '{}'::jsonb,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);
create index on notifications (user_id, created_at desc);

-- ─────────────────────────────────────────── updated_at 트리거

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare t text;
begin
  foreach t in array array[
    'profiles', 'missionary_info', 'support_accounts', 'communities',
    'posts', 'stays', 'stay_addresses', 'stay_requests'
  ] loop
    execute format(
      'create trigger touch_%1$s before update on public.%1$s
         for each row execute function public.touch_updated_at()', t);
  end loop;
end;
$$;
