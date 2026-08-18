-- movelet M0 — stays SELECT 정책 수정
--
-- 문제: 정책이 can_view_stay(id) 를 부르고, 그 함수는 stays 를 다시 조회한다.
-- `insert ... returning` 은 삽입된 행이 SELECT 정책을 통과해야 값을 돌려주는데, 함수 안의 조회는
-- INSERT 명령 이전 스냅샷을 보므로 방금 넣은 행이 없다. 그래서 호스트 본인조차 등록 직후
-- 자기 숙소를 돌려받지 못했다.
--
-- 해법: 자기 테이블을 다시 읽지 말고 행의 컬럼(host_id·status·visibility)을 정책에서 직접 본다.
-- can_view_stay() 는 stay_media·stay_addresses·stay_requests 처럼 '다른 표'의 정책에서는 그대로 쓴다
-- (그쪽에서는 stays 행이 이미 이전 명령에서 커밋된 상태라 스냅샷 문제가 없다).

drop policy stays_select on stays;

create policy stays_select on stays for select to authenticated
  using (
    host_id = auth.uid()
    or public.is_admin()
    or exists (
      select 1 from stay_requests r
      where r.stay_id = stays.id and r.guest_id = auth.uid()
    )
    or (
      status = 'open'
      and (
        visibility = 'members'
        or (
          visibility = 'community'
          and exists (
            select 1 from stay_audience a
            where a.stay_id = stays.id and a.community_id is not null
              and public.is_community_member(a.community_id)
          )
        )
        or (
          visibility = 'targeted'
          and exists (
            select 1 from stay_audience a
            where a.stay_id = stays.id and a.missionary_id = auth.uid()
          )
        )
      )
    )
  );
