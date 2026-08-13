-- michri M0 — RLS 정책
--
-- 이 파일의 규칙 세 가지
--  1. 전 테이블 기본 차단. 정책으로 허용한 것만 열린다.
--  2. 조회 권한의 뿌리는 is_community_member() 하나다. 광장(type='open')도 여기서만 분기한다.
--  3. 멤버십을 참조하는 정책은 SECURITY DEFINER 함수를 통한다. 정책 안에서 같은 표를 직접 조회하면 무한 재귀가 난다.

-- ─────────────────────────────────────────── 권한 판정 함수

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select coalesce((select p.is_admin from profiles p where p.id = auth.uid()), false);
$$;

-- 선교사 인증이 여는 것: 광장 글쓰기 · 후원 계좌 등록 · 숙소 요청. 그 셋만 이 함수를 본다.
create or replace function public.is_verified_missionary()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1 from profiles p
    where p.id = auth.uid() and p.is_missionary and p.verified_at is not null
  );
$$;

-- 권한의 뿌리. 광장은 로그인 회원 전원이 멤버이고, 프라이빗 방은 초대받은 사람만이다.
create or replace function public.is_community_member(cid uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select auth.uid() is not null and exists (
    select 1 from communities c
    where c.id = cid
      and (
        c.type = 'open'
        or exists (
          select 1 from community_members m
          where m.community_id = c.id and m.user_id = auth.uid()
        )
      )
  );
$$;

create or replace function public.is_community_owner(cid uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1 from community_members m
    where m.community_id = cid and m.user_id = auth.uid() and m.role = 'owner'
  );
$$;

create or replace function public.can_invite_to(cid uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1
    from communities c
    join community_members m on m.community_id = c.id and m.user_id = auth.uid()
    where c.id = cid
      and (m.role = 'owner' or c.invite_policy = 'member')
  );
$$;

-- 글은 여러 방에 걸리므로 "이 글의 대상 방 중 내가 멤버인 방이 하나라도 있는가"로 판정한다.
create or replace function public.can_view_post(pid uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1 from post_targets t
    where t.post_id = pid and public.is_community_member(t.community_id)
  );
$$;

create or replace function public.can_view_stay(sid uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1 from stays s
    where s.id = sid
      and auth.uid() is not null
      and (
        s.host_id = auth.uid()
        or exists (select 1 from stay_requests r where r.stay_id = s.id and r.guest_id = auth.uid())
        or (
          s.status = 'open'
          and case s.visibility
            when 'members'   then true
            when 'community' then exists (
              select 1 from stay_audience a
              where a.stay_id = s.id and a.community_id is not null
                and public.is_community_member(a.community_id)
            )
            when 'targeted'  then exists (
              select 1 from stay_audience a
              where a.stay_id = s.id and a.missionary_id = auth.uid()
            )
          end
        )
      )
  );
$$;

create or replace function public.has_accepted_stay_request(sid uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1 from stay_requests r
    where r.stay_id = sid and r.guest_id = auth.uid() and r.status = 'accepted'
  );
$$;

-- ─────────────────────────────────────────── RLS 켜기 (전 테이블)

do $$
declare t text;
begin
  for t in select tablename from pg_tables where schemaname = 'public'
  loop
    -- force는 쓰지 않는다. 정책 판정에 쓰는 SECURITY DEFINER 함수들이 테이블 소유자 권한으로
    -- 멤버십을 조회해야 하는데, force를 걸면 그 조회까지 정책을 타서 재귀가 난다.
    execute format('alter table public.%I enable row level security', t);
  end loop;
end;
$$;

-- 익명(anon)에게는 어떤 표도 열지 않는다. 익명 가입 자체가 없는 제품이다.
grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
revoke all on all tables in schema public from anon;

-- ─────────────────────────────────────────── profiles

create policy profiles_select on profiles for select to authenticated using (true);
create policy profiles_insert on profiles for insert to authenticated with check (id = auth.uid());
create policy profiles_update_self  on profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy profiles_update_admin on profiles for update to authenticated using (public.is_admin()) with check (true);

-- 본인이 자기 인증·관리자 권한을 켜지 못하게 막는다. 정책만으로는 컬럼 단위를 못 막으므로 트리거로 잡는다.
create or replace function public.guard_profile_privileges()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if public.is_admin() then
    return new;
  end if;
  if new.is_admin is distinct from old.is_admin
     or new.verified_at is distinct from old.verified_at
     or new.verified_by is distinct from old.verified_by then
    raise exception '인증·관리자 권한은 본인이 변경할 수 없습니다';
  end if;
  return new;
end;
$$;

create trigger guard_profile_privileges
  before update on profiles
  for each row execute function public.guard_profile_privileges();

-- ─────────────────────────────────────────── missionary_info

create policy missionary_info_select on missionary_info for select to authenticated using (true);
create policy missionary_info_write  on missionary_info for all to authenticated
  using (profile_id = auth.uid() or public.is_admin())
  with check (profile_id = auth.uid());

-- ─────────────────────────────────────────── churches (자동완성 사전)

create policy churches_select on churches for select to authenticated using (true);
-- 쓰기는 record_church() RPC로만. 직접 insert 정책은 두지 않는다.

create or replace function public.record_church(p_name text, p_region text default null)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception '로그인이 필요합니다'; end if;
  p_name := trim(p_name);
  if coalesce(char_length(p_name), 0) = 0 then raise exception '교회명이 비어 있습니다'; end if;

  insert into churches (name, region) values (p_name, nullif(trim(p_region), ''))
  on conflict (name, coalesce(region, '')) do update set use_count = churches.use_count + 1
  returning id into v_id;
  return v_id;
end;
$$;

-- ─────────────────────────────────────────── 후원

create policy support_accounts_select on support_accounts for select to authenticated using (true);
create policy support_accounts_write  on support_accounts for all to authenticated
  using (missionary_id = auth.uid() or public.is_admin())
  with check (missionary_id = auth.uid() and public.is_verified_missionary());

create policy support_logs_select on support_logs for select to authenticated
  using (supporter_id = auth.uid() or missionary_id = auth.uid());
create policy support_logs_insert on support_logs for insert to authenticated
  with check (supporter_id = auth.uid());

-- ─────────────────────────────────────────── 커뮤니티

-- 방은 멤버에게만 보인다. 초대 링크로 들어온 사람에게 보여줄 정보는 preview_invite() RPC가 따로 낸다.
create policy communities_select on communities for select to authenticated
  using (public.is_community_member(id) or public.is_admin());

-- 개설은 회원 누구나. 단 광장(type='open')은 관리자만 만든다.
create policy communities_insert on communities for insert to authenticated
  with check (
    created_by = auth.uid()
    and (type = 'private' or public.is_admin())
  );

create policy communities_update on communities for update to authenticated
  using (public.is_community_owner(id) or public.is_admin())
  with check (type = 'private' or public.is_admin());

create policy communities_delete on communities for delete to authenticated
  using (public.is_community_owner(id) or public.is_admin());

-- 개설자를 owner 멤버로 자동 등록한다. 클라이언트가 두 번 쓰게 하면 중간에 끊겼을 때 주인 없는 방이 남는다.
create or replace function public.add_creator_as_owner()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if new.type = 'private' and new.created_by is not null then
    insert into community_members (community_id, user_id, role)
    values (new.id, new.created_by, 'owner')
    on conflict do nothing;
  end if;
  return new;
end;
$$;

create trigger add_creator_as_owner
  after insert on communities
  for each row execute function public.add_creator_as_owner();

create policy community_members_select on community_members for select to authenticated
  using (public.is_community_member(community_id) or public.is_admin());

create policy community_members_insert on community_members for insert to authenticated
  with check (public.is_community_owner(community_id) or public.is_admin());

create policy community_members_update on community_members for update to authenticated
  using (public.is_community_owner(community_id) or public.is_admin());

-- 본인 탈퇴 또는 방장 강퇴
create policy community_members_delete on community_members for delete to authenticated
  using (user_id = auth.uid() or public.is_community_owner(community_id) or public.is_admin());

-- 마지막 방장이 빠져 주인 없는 방이 되는 것을 막는다.
create or replace function public.guard_last_owner()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if old.role = 'owner' and not exists (
    select 1 from community_members m
    where m.community_id = old.community_id and m.role = 'owner' and m.user_id <> old.user_id
  ) then
    raise exception '마지막 방장은 나갈 수 없습니다. 다른 멤버에게 방장을 넘기세요';
  end if;
  return old;
end;
$$;

create trigger guard_last_owner
  before delete on community_members
  for each row execute function public.guard_last_owner();

create policy community_invites_select on community_invites for select to authenticated
  using (public.can_invite_to(community_id) or public.is_admin());
create policy community_invites_insert on community_invites for insert to authenticated
  with check (created_by = auth.uid() and public.can_invite_to(community_id));
create policy community_invites_update on community_invites for update to authenticated
  using (created_by = auth.uid() or public.is_community_owner(community_id) or public.is_admin());

-- 초대 코드로 방 정보 미리보기 (아직 멤버가 아니므로 select 정책으로는 못 본다)
create or replace function public.preview_invite(p_code text)
returns table (community_id uuid, name text, kind community_kind, description text, member_count bigint)
language sql stable security definer set search_path = public, pg_temp as $$
  select c.id, c.name, c.kind, c.description,
         (select count(*) from community_members m where m.community_id = c.id)
  from community_invites i
  join communities c on c.id = i.community_id
  where i.code = p_code
    and i.revoked_at is null
    and (i.expires_at is null or i.expires_at > now())
    and (i.max_uses is null or i.used_count < i.max_uses)
    and auth.uid() is not null;
$$;

create or replace function public.join_community_by_code(p_code text)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_invite community_invites; v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception '로그인이 필요합니다'; end if;

  select * into v_invite from community_invites where code = p_code for update;

  if v_invite is null then raise exception '초대 코드를 찾을 수 없습니다'; end if;
  if v_invite.revoked_at is not null then raise exception '취소된 초대입니다'; end if;
  if v_invite.expires_at is not null and v_invite.expires_at <= now() then raise exception '만료된 초대입니다'; end if;
  if v_invite.max_uses is not null and v_invite.used_count >= v_invite.max_uses then
    raise exception '사용 횟수를 모두 쓴 초대입니다';
  end if;

  insert into community_members (community_id, user_id, role, invited_by)
  values (v_invite.community_id, v_uid, 'member', v_invite.created_by)
  on conflict (community_id, user_id) do nothing;

  update community_invites set used_count = used_count + 1 where id = v_invite.id;
  return v_invite.community_id;
end;
$$;

-- ─────────────────────────────────────────── 피드

create policy posts_select on posts for select to authenticated
  using (author_id = auth.uid() or public.can_view_post(id) or public.is_admin());
create policy posts_insert on posts for insert to authenticated with check (author_id = auth.uid());
create policy posts_update on posts for update to authenticated
  using (author_id = auth.uid()) with check (author_id = auth.uid());
create policy posts_delete on posts for delete to authenticated
  using (author_id = auth.uid() or public.is_admin());

-- 게시 대상 지정이 곧 공개 행위다. 광장에 올리는 것만 선교사 인증을 요구한다.
create policy post_targets_select on post_targets for select to authenticated
  using (
    public.is_community_member(community_id)
    or exists (select 1 from posts p where p.id = post_id and p.author_id = auth.uid())
    or public.is_admin()
  );

create policy post_targets_insert on post_targets for insert to authenticated
  with check (
    exists (select 1 from posts p where p.id = post_id and p.author_id = auth.uid())
    and public.is_community_member(community_id)
    and (
      exists (select 1 from communities c where c.id = community_id and c.type = 'private')
      or public.is_verified_missionary()
      or public.is_admin()
    )
  );

create policy post_targets_delete on post_targets for delete to authenticated
  using (
    exists (select 1 from posts p where p.id = post_id and p.author_id = auth.uid())
    or public.is_community_owner(community_id)
    or public.is_admin()
  );

create policy post_media_select on post_media for select to authenticated
  using (public.can_view_post(post_id) or public.is_admin());
create policy post_media_write on post_media for all to authenticated
  using (exists (select 1 from posts p where p.id = post_id and p.author_id = auth.uid()))
  with check (exists (select 1 from posts p where p.id = post_id and p.author_id = auth.uid()));

create policy comments_select on comments for select to authenticated
  using (public.is_community_member(community_id) or public.is_admin());
create policy comments_insert on comments for insert to authenticated
  with check (author_id = auth.uid() and public.is_community_member(community_id));
create policy comments_update on comments for update to authenticated
  using (author_id = auth.uid()) with check (author_id = auth.uid());
create policy comments_delete on comments for delete to authenticated
  using (author_id = auth.uid() or public.is_community_owner(community_id) or public.is_admin());

create policy reactions_select on reactions for select to authenticated
  using (public.is_community_member(community_id) or public.is_admin());
create policy reactions_write on reactions for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and public.is_community_member(community_id));

-- ─────────────────────────────────────────── 숙소

create policy stays_select on stays for select to authenticated
  using (public.can_view_stay(id) or public.is_admin());
create policy stays_insert on stays for insert to authenticated with check (host_id = auth.uid());
create policy stays_update on stays for update to authenticated
  using (host_id = auth.uid() or public.is_admin()) with check (host_id = auth.uid() or public.is_admin());
create policy stays_delete on stays for delete to authenticated
  using (host_id = auth.uid() or public.is_admin());

-- 상세 주소는 수락 전까지 게스트에게 열리지 않는다. 목록·상세 화면은 stays.region_label만 쓴다.
create policy stay_addresses_select on stay_addresses for select to authenticated
  using (
    exists (select 1 from stays s where s.id = stay_id and s.host_id = auth.uid())
    or public.has_accepted_stay_request(stay_id)
  );
create policy stay_addresses_write on stay_addresses for all to authenticated
  using (exists (select 1 from stays s where s.id = stay_id and s.host_id = auth.uid()))
  with check (exists (select 1 from stays s where s.id = stay_id and s.host_id = auth.uid()));

create policy stay_media_select on stay_media for select to authenticated
  using (public.can_view_stay(stay_id) or public.is_admin());
create policy stay_media_write on stay_media for all to authenticated
  using (exists (select 1 from stays s where s.id = stay_id and s.host_id = auth.uid()))
  with check (exists (select 1 from stays s where s.id = stay_id and s.host_id = auth.uid()));

create policy stay_audience_select on stay_audience for select to authenticated
  using (
    exists (select 1 from stays s where s.id = stay_id and s.host_id = auth.uid())
    or missionary_id = auth.uid()
    or (community_id is not null and public.is_community_member(community_id))
  );
create policy stay_audience_write on stay_audience for all to authenticated
  using (exists (select 1 from stays s where s.id = stay_id and s.host_id = auth.uid()))
  with check (exists (select 1 from stays s where s.id = stay_id and s.host_id = auth.uid()));

create policy stay_requests_select on stay_requests for select to authenticated
  using (
    guest_id = auth.uid()
    or exists (select 1 from stays s where s.id = stay_id and s.host_id = auth.uid())
    or public.is_admin()
  );

-- 숙소 요청은 선교사 인증이 여는 행동이다(남의 집 주소가 걸린다).
create policy stay_requests_insert on stay_requests for insert to authenticated
  with check (
    guest_id = auth.uid()
    and public.is_verified_missionary()
    and public.can_view_stay(stay_id)
  );

create policy stay_requests_update on stay_requests for update to authenticated
  using (
    guest_id = auth.uid()
    or exists (select 1 from stays s where s.id = stay_id and s.host_id = auth.uid())
  );

-- 게스트는 취소만, 호스트는 수락·거절만 할 수 있다.
create or replace function public.guard_stay_request_transition()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
declare v_is_host boolean;
begin
  if new.status = old.status then return new; end if;

  select exists (select 1 from stays s where s.id = old.stay_id and s.host_id = auth.uid())
    into v_is_host;

  if old.status <> 'pending' then
    raise exception '이미 처리된 요청입니다';
  end if;

  if v_is_host and new.status not in ('accepted', 'declined') then
    raise exception '호스트는 수락 또는 거절만 할 수 있습니다';
  end if;

  if not v_is_host and new.status <> 'cancelled' then
    raise exception '요청자는 취소만 할 수 있습니다';
  end if;

  return new;
end;
$$;

create trigger guard_stay_request_transition
  before update on stay_requests
  for each row execute function public.guard_stay_request_transition();

-- ─────────────────────────────────────────── 운영

create policy reports_select on reports for select to authenticated
  using (reporter_id = auth.uid() or public.is_admin());
create policy reports_insert on reports for insert to authenticated
  with check (reporter_id = auth.uid());
create policy reports_update on reports for update to authenticated
  using (public.is_admin());

create policy blocks_all on blocks for all to authenticated
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

create policy notifications_select on notifications for select to authenticated
  using (user_id = auth.uid());
create policy notifications_update on notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
-- insert 정책 없음: 알림은 서버(service_role)만 만든다.

-- ─────────────────────────────────────────── 함수 실행 권한

revoke execute on function public.record_church(text, text) from public;
revoke execute on function public.preview_invite(text) from public;
revoke execute on function public.join_community_by_code(text) from public;
grant execute on function public.record_church(text, text) to authenticated;
grant execute on function public.preview_invite(text) to authenticated;
grant execute on function public.join_community_by_code(text) to authenticated;
