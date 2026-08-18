-- movelet M0 — 정책 성능 정리 (supabase db advisors 성능 경고 대응)
--
-- 판정 로직은 한 줄도 바꾸지 않는다. 같은 결과를 더 싸게 계산하도록 형태만 고친다.
--
-- 1. auth_rls_initplan (38건)
--    정책 안의 `auth.uid()` 는 행마다 다시 평가된다. `(select auth.uid())` 로 감싸면 플래너가
--    InitPlan 으로 빼내 질의당 한 번만 평가한다. 피드가 수천 행이 되면 차이가 그대로 드러난다.
--
-- 2. multiple_permissive_policies (8건)
--    `for all` 정책은 SELECT 에도 걸린다. 그래서 select 정책이 따로 있는 표는 조회 때마다
--    정책 두 개를 모두 평가하고 OR 로 합쳤다. `for all` 을 insert·update·delete 로 쪼개
--    조회 경로에서 쓰기 정책이 빠지게 한다. profiles 는 update 정책 둘을 하나로 합친다.
--
--    쪼갠 뒤에도 읽기 권한은 그대로다. 여덟 표 모두 이미 전용 select 정책을 갖고 있다.
--
-- SECURITY DEFINER 헬퍼(is_community_member 등) 안의 auth.uid() 는 그대로 둔다.
-- 함수 본문은 호출당 한 번 평가되므로 같은 문제가 없다.

-- ─────────────────────────────────────────── profiles

drop policy profiles_insert       on profiles;
drop policy profiles_update_self  on profiles;
drop policy profiles_update_admin on profiles;

create policy profiles_insert on profiles for insert to authenticated
  with check (id = (select auth.uid()));

-- 본인 또는 관리자. 컬럼 단위 제한(인증·관리자 플래그)은 guard_profile_privileges 트리거가 계속 맡는다.
create policy profiles_update on profiles for update to authenticated
  using (id = (select auth.uid()) or public.is_admin())
  with check (id = (select auth.uid()) or public.is_admin());

-- ─────────────────────────────────────────── missionary_info

drop policy missionary_info_write on missionary_info;

create policy missionary_info_insert on missionary_info for insert to authenticated
  with check (profile_id = (select auth.uid()));
create policy missionary_info_update on missionary_info for update to authenticated
  using (profile_id = (select auth.uid()) or public.is_admin())
  with check (profile_id = (select auth.uid()));
create policy missionary_info_delete on missionary_info for delete to authenticated
  using (profile_id = (select auth.uid()) or public.is_admin());

-- ─────────────────────────────────────────── 후원

drop policy support_accounts_write on support_accounts;

create policy support_accounts_insert on support_accounts for insert to authenticated
  with check (missionary_id = (select auth.uid()) and public.is_verified_missionary());
create policy support_accounts_update on support_accounts for update to authenticated
  using (missionary_id = (select auth.uid()) or public.is_admin())
  with check (missionary_id = (select auth.uid()) and public.is_verified_missionary());
create policy support_accounts_delete on support_accounts for delete to authenticated
  using (missionary_id = (select auth.uid()) or public.is_admin());

drop policy support_logs_select on support_logs;
drop policy support_logs_insert on support_logs;

create policy support_logs_select on support_logs for select to authenticated
  using (supporter_id = (select auth.uid()) or missionary_id = (select auth.uid()));
create policy support_logs_insert on support_logs for insert to authenticated
  with check (supporter_id = (select auth.uid()));

-- ─────────────────────────────────────────── 커뮤니티

drop policy communities_insert on communities;

create policy communities_insert on communities for insert to authenticated
  with check (
    created_by = (select auth.uid())
    and (type = 'private' or public.is_admin())
  );

drop policy community_members_delete on community_members;

create policy community_members_delete on community_members for delete to authenticated
  using (
    user_id = (select auth.uid())
    or public.is_community_owner(community_id)
    or public.is_admin()
  );

drop policy community_invites_insert on community_invites;
drop policy community_invites_update on community_invites;

create policy community_invites_insert on community_invites for insert to authenticated
  with check (created_by = (select auth.uid()) and public.can_invite_to(community_id));
create policy community_invites_update on community_invites for update to authenticated
  using (
    created_by = (select auth.uid())
    or public.is_community_owner(community_id)
    or public.is_admin()
  );

-- ─────────────────────────────────────────── 피드

drop policy posts_select on posts;
drop policy posts_insert on posts;
drop policy posts_update on posts;
drop policy posts_delete on posts;

create policy posts_select on posts for select to authenticated
  using (author_id = (select auth.uid()) or public.can_view_post(id) or public.is_admin());
create policy posts_insert on posts for insert to authenticated
  with check (author_id = (select auth.uid()));
create policy posts_update on posts for update to authenticated
  using (author_id = (select auth.uid())) with check (author_id = (select auth.uid()));
create policy posts_delete on posts for delete to authenticated
  using (author_id = (select auth.uid()) or public.is_admin());

drop policy post_targets_select on post_targets;
drop policy post_targets_insert on post_targets;
drop policy post_targets_delete on post_targets;

create policy post_targets_select on post_targets for select to authenticated
  using (
    public.is_community_member(community_id)
    or exists (select 1 from posts p where p.id = post_id and p.author_id = (select auth.uid()))
    or public.is_admin()
  );

create policy post_targets_insert on post_targets for insert to authenticated
  with check (
    exists (select 1 from posts p where p.id = post_id and p.author_id = (select auth.uid()))
    and public.is_community_member(community_id)
    and (
      exists (select 1 from communities c where c.id = community_id and c.type = 'private')
      or public.is_verified_missionary()
      or public.is_admin()
    )
  );

create policy post_targets_delete on post_targets for delete to authenticated
  using (
    exists (select 1 from posts p where p.id = post_id and p.author_id = (select auth.uid()))
    or public.is_community_owner(community_id)
    or public.is_admin()
  );

drop policy post_media_write on post_media;

create policy post_media_insert on post_media for insert to authenticated
  with check (exists (select 1 from posts p where p.id = post_id and p.author_id = (select auth.uid())));
create policy post_media_update on post_media for update to authenticated
  using (exists (select 1 from posts p where p.id = post_id and p.author_id = (select auth.uid())))
  with check (exists (select 1 from posts p where p.id = post_id and p.author_id = (select auth.uid())));
create policy post_media_delete on post_media for delete to authenticated
  using (exists (select 1 from posts p where p.id = post_id and p.author_id = (select auth.uid())));

drop policy comments_insert on comments;
drop policy comments_update on comments;
drop policy comments_delete on comments;

create policy comments_insert on comments for insert to authenticated
  with check (author_id = (select auth.uid()) and public.is_community_member(community_id));
create policy comments_update on comments for update to authenticated
  using (author_id = (select auth.uid())) with check (author_id = (select auth.uid()));
create policy comments_delete on comments for delete to authenticated
  using (
    author_id = (select auth.uid())
    or public.is_community_owner(community_id)
    or public.is_admin()
  );

drop policy reactions_write on reactions;

create policy reactions_insert on reactions for insert to authenticated
  with check (user_id = (select auth.uid()) and public.is_community_member(community_id));
create policy reactions_update on reactions for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and public.is_community_member(community_id));
create policy reactions_delete on reactions for delete to authenticated
  using (user_id = (select auth.uid()));

-- ─────────────────────────────────────────── 숙소

drop policy stays_insert on stays;
drop policy stays_update on stays;
drop policy stays_delete on stays;

create policy stays_insert on stays for insert to authenticated
  with check (host_id = (select auth.uid()));
create policy stays_update on stays for update to authenticated
  using (host_id = (select auth.uid()) or public.is_admin())
  with check (host_id = (select auth.uid()) or public.is_admin());
create policy stays_delete on stays for delete to authenticated
  using (host_id = (select auth.uid()) or public.is_admin());

drop policy stay_addresses_select on stay_addresses;
drop policy stay_addresses_write  on stay_addresses;

-- 상세 주소는 수락 전까지 게스트에게 열리지 않는다는 규칙은 그대로다.
create policy stay_addresses_select on stay_addresses for select to authenticated
  using (
    exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid()))
    or public.has_accepted_stay_request(stay_id)
  );
create policy stay_addresses_insert on stay_addresses for insert to authenticated
  with check (exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid())));
create policy stay_addresses_update on stay_addresses for update to authenticated
  using (exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid())))
  with check (exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid())));
create policy stay_addresses_delete on stay_addresses for delete to authenticated
  using (exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid())));

drop policy stay_media_write on stay_media;

create policy stay_media_insert on stay_media for insert to authenticated
  with check (exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid())));
create policy stay_media_update on stay_media for update to authenticated
  using (exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid())))
  with check (exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid())));
create policy stay_media_delete on stay_media for delete to authenticated
  using (exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid())));

drop policy stay_audience_select on stay_audience;
drop policy stay_audience_write  on stay_audience;

create policy stay_audience_select on stay_audience for select to authenticated
  using (
    exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid()))
    or missionary_id = (select auth.uid())
    or (community_id is not null and public.is_community_member(community_id))
  );
create policy stay_audience_insert on stay_audience for insert to authenticated
  with check (exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid())));
create policy stay_audience_update on stay_audience for update to authenticated
  using (exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid())))
  with check (exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid())));
create policy stay_audience_delete on stay_audience for delete to authenticated
  using (exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid())));

drop policy stay_requests_select on stay_requests;
drop policy stay_requests_insert on stay_requests;
drop policy stay_requests_update on stay_requests;

create policy stay_requests_select on stay_requests for select to authenticated
  using (
    guest_id = (select auth.uid())
    or exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid()))
    or public.is_admin()
  );

create policy stay_requests_insert on stay_requests for insert to authenticated
  with check (
    guest_id = (select auth.uid())
    and public.is_verified_missionary()
    and public.can_view_stay(stay_id)
  );

create policy stay_requests_update on stay_requests for update to authenticated
  using (
    guest_id = (select auth.uid())
    or exists (select 1 from stays s where s.id = stay_id and s.host_id = (select auth.uid()))
  );

-- ─────────────────────────────────────────── 운영

drop policy reports_select on reports;
drop policy reports_insert on reports;

create policy reports_select on reports for select to authenticated
  using (reporter_id = (select auth.uid()) or public.is_admin());
create policy reports_insert on reports for insert to authenticated
  with check (reporter_id = (select auth.uid()));

-- blocks 는 select 정책이 따로 없어 for all 이 중복을 만들지 않는다. 감싸기만 한다.
drop policy blocks_all on blocks;

create policy blocks_all on blocks for all to authenticated
  using (blocker_id = (select auth.uid()))
  with check (blocker_id = (select auth.uid()));

drop policy notifications_select on notifications;
drop policy notifications_update on notifications;

create policy notifications_select on notifications for select to authenticated
  using (user_id = (select auth.uid()));
create policy notifications_update on notifications for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
