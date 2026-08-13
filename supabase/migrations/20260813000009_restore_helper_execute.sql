-- michri M0 — 판정 헬퍼의 EXECUTE 를 authenticated 에 되돌린다
--
-- 0008에서 헬퍼까지 회수했더니 정책이 통째로 막혔다. RLS 정책 표현식은 질의를 던진 사용자의
-- 권한으로 평가되므로, 정책이 부르는 함수에도 그 사용자의 EXECUTE 가 필요하다.
--
-- 그래서 anon 차단(0008)은 유지하고 authenticated 에게만 돌려준다.
-- 남는 노출: 로그인 회원이 /rest/v1/rpc/is_community_member 같은 걸 직접 부를 수 있다. 다만 이 함수들은
-- 전부 auth.uid() 기준으로 '나에 대한' 불리언만 돌려주므로, 회원이 이미 아는 사실 이상을 주지 않는다.
--
-- 완전히 가리려면 헬퍼를 노출되지 않는 스키마(private 등)로 옮겨야 하는데, 함수들이 서로를
-- public. 접두사로 부르고 정책 38개가 이들을 참조해서 전면 재작성이 필요하다. 지금 얻는 것에 비해
-- 손대는 범위가 커서 미뤄둔다.

grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_verified_missionary() to authenticated;
grant execute on function public.is_community_member(uuid) to authenticated;
grant execute on function public.is_community_owner(uuid) to authenticated;
grant execute on function public.can_invite_to(uuid) to authenticated;
grant execute on function public.can_view_post(uuid) to authenticated;
grant execute on function public.can_view_stay(uuid) to authenticated;
grant execute on function public.has_accepted_stay_request(uuid) to authenticated;
grant execute on function public.stay_visible_to_me(uuid, uuid, stay_status, stay_visibility) to authenticated;
