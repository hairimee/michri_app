-- movelet M0 — 방 개설 RPC
--
-- 왜 정책이 아니라 RPC인가.
-- `insert ... returning` 은 삽입된 행이 SELECT 정책까지 통과해야 값을 돌려준다. 그런데 방을 만든
-- 직후에는 아직 멤버 행이 없어서(멤버 등록은 AFTER 트리거) is_community_member()가 거짓이고,
-- 개설자가 자기가 만든 방을 못 돌려받는다.
--
-- 해법으로 communities의 SELECT 정책에 `created_by = auth.uid()` 를 더할 수도 있었지만,
-- 그러면 열람 권한의 뿌리가 '멤버십'과 '개설자' 둘로 갈라진다. 초대 코드 처리와 같은 방식으로
-- RPC 하나에 묶어, 방 생성과 방장 등록이 한 트랜잭션에서 끝나게 한다.

create or replace function public.create_community(
  p_name          text,
  p_kind          community_kind default 'etc',
  p_description   text default null,
  p_invite_policy invite_policy default 'owner'
)
returns communities
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_uid uuid := auth.uid(); v_row communities;
begin
  if v_uid is null then raise exception '로그인이 필요합니다'; end if;

  p_name := trim(p_name);
  if coalesce(char_length(p_name), 0) = 0 then raise exception '방 이름이 비어 있습니다'; end if;

  -- 소속 교회를 적은 사람만 방을 만들 수 있다(온보딩을 마쳐야 한다는 뜻).
  if not exists (select 1 from profiles where id = v_uid) then
    raise exception '프로필을 먼저 만들어야 합니다';
  end if;

  -- 광장(type='open')은 이 함수로 만들지 않는다. 관리자가 마이그레이션으로만 만든다.
  insert into communities (name, kind, description, type, invite_policy, created_by)
  values (p_name, p_kind, nullif(trim(p_description), ''), 'private', p_invite_policy, v_uid)
  returning * into v_row;

  -- add_creator_as_owner 트리거가 이미 넣었겠지만, 트리거가 사라져도 방이 주인 없이 남지 않도록 한 번 더 보장한다.
  insert into community_members (community_id, user_id, role)
  values (v_row.id, v_uid, 'owner')
  on conflict (community_id, user_id) do nothing;

  return v_row;
end;
$$;

revoke execute on function public.create_community(text, community_kind, text, invite_policy) from public;
grant execute on function public.create_community(text, community_kind, text, invite_policy) to authenticated;
