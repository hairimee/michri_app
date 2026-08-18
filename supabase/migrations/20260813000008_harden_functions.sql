-- movelet M0 — 함수 노출 조이기 (supabase db advisors 보안 경고 대응)
--
-- 두 가지를 고친다.
--  1. public 스키마의 함수는 기본적으로 /rest/v1/rpc/<이름> 으로 노출된다. 판정용 헬퍼와 트리거 함수까지
--     로그인 없이 부를 수 있는 상태였다. 앱이 실제로 부르는 RPC 넷만 남기고 전부 회수한다.
--  2. search_path 가 고정되지 않은 함수 둘을 고정한다. SECURITY DEFINER 함수에서 search_path 가
--     열려 있으면 같은 이름의 가짜 객체로 동작을 바꿔치기당할 수 있다.

alter function public.touch_updated_at() set search_path = public, pg_temp;
alter function public.owns_storage_path(text) set search_path = public, storage, pg_temp;

-- ── 트리거 함수: 누구도 직접 부를 일이 없다 (트리거는 EXECUTE 권한과 무관하게 동작한다)
revoke all on function public.touch_updated_at() from public, anon, authenticated;
revoke all on function public.add_creator_as_owner() from public, anon, authenticated;
revoke all on function public.guard_profile_privileges() from public, anon, authenticated;
revoke all on function public.guard_last_owner() from public, anon, authenticated;
revoke all on function public.guard_stay_request_transition() from public, anon, authenticated;

-- ── 판정 헬퍼: 정책 안에서만 쓰인다. 클라이언트가 직접 부를 이유가 없다
revoke all on function public.is_admin() from public, anon, authenticated;
revoke all on function public.is_verified_missionary() from public, anon, authenticated;
revoke all on function public.is_community_member(uuid) from public, anon, authenticated;
revoke all on function public.is_community_owner(uuid) from public, anon, authenticated;
revoke all on function public.can_invite_to(uuid) from public, anon, authenticated;
revoke all on function public.can_view_post(uuid) from public, anon, authenticated;
revoke all on function public.can_view_stay(uuid) from public, anon, authenticated;
revoke all on function public.has_accepted_stay_request(uuid) from public, anon, authenticated;
revoke all on function public.stay_visible_to_me(uuid, uuid, stay_status, stay_visibility) from public, anon, authenticated;

-- ── 앱이 부르는 RPC: 로그인한 회원에게만
revoke all on function public.record_church(text, text) from public, anon;
revoke all on function public.preview_invite(text) from public, anon;
revoke all on function public.join_community_by_code(text) from public, anon;
revoke all on function public.create_community(text, community_kind, text, invite_policy) from public, anon;

grant execute on function public.record_church(text, text) to authenticated;
grant execute on function public.preview_invite(text) to authenticated;
grant execute on function public.join_community_by_code(text) to authenticated;
grant execute on function public.create_community(text, community_kind, text, invite_policy) to authenticated;

-- storage 정책에서 쓰는 함수는 SECURITY INVOKER 라 호출자 권한이 필요하다
grant execute on function public.owns_storage_path(text) to authenticated;
