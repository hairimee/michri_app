-- michri M0 — 숙소 열람 판정을 함수 하나로 모은다
--
-- 0006에서 정책을 인라인으로 펴자 이번엔 재귀가 났다. stays 정책이 stay_requests·stay_audience 를
-- 조회하는데, 그 두 표의 정책이 다시 stays 를 조회하기 때문이다.
--
-- 해법: 판정을 SECURITY DEFINER 함수로 옮기되, **행의 컬럼을 인자로 받는다.**
--   · 함수 안에서는 정책이 돌지 않으므로 재귀가 끊긴다
--   · stays 를 다시 읽지 않으므로 insert ... returning 의 스냅샷 문제도 없다
-- 커뮤니티 멤버십 판정(is_community_member)을 그대로 재사용하므로 권한의 뿌리는 여전히 하나다.

create or replace function public.stay_visible_to_me(
  p_stay_id    uuid,
  p_host_id    uuid,
  p_status     stay_status,
  p_visibility stay_visibility
)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select auth.uid() is not null and (
    p_host_id = auth.uid()
    or public.is_admin()
    -- 요청을 넣은 게스트는 처리 결과와 무관하게 그 숙소를 계속 본다
    or exists (
      select 1 from stay_requests r
      where r.stay_id = p_stay_id and r.guest_id = auth.uid()
    )
    or (
      p_status = 'open'
      and (
        p_visibility = 'members'
        or (
          p_visibility = 'community'
          and exists (
            select 1 from stay_audience a
            where a.stay_id = p_stay_id and a.community_id is not null
              and public.is_community_member(a.community_id)
          )
        )
        or (
          p_visibility = 'targeted'
          and exists (
            select 1 from stay_audience a
            where a.stay_id = p_stay_id and a.missionary_id = auth.uid()
          )
        )
      )
    )
  );
$$;

-- 다른 표(stay_media·stay_addresses·stay_requests)의 정책에서 쓰는 형태. stays 한 행을 읽어 위 함수에 넘긴다.
create or replace function public.can_view_stay(sid uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select coalesce(
    (select public.stay_visible_to_me(s.id, s.host_id, s.status, s.visibility) from stays s where s.id = sid),
    false
  );
$$;

drop policy stays_select on stays;

create policy stays_select on stays for select to authenticated
  using (public.stay_visible_to_me(id, host_id, status, visibility));
