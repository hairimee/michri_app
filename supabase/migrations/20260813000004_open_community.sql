-- michri M0 — 광장(열린 커뮤니티) 한 행
-- 광장은 특별한 테이블이 아니라 communities의 type='open' 한 행이다.
-- 앱 회원 전원이 이 방의 멤버로 취급되므로 community_members에는 행이 쌓이지 않는다.
-- 표시 명칭('광장')은 기획안 미결 항목이라 바뀔 수 있다. 코드는 이름이 아니라 type으로 찾는다.

insert into communities (name, kind, description, type, invite_policy, created_by)
select '광장', 'etc',
       '앱 회원 모두가 보는 방입니다. 널리 알리고 싶은 기도제목과 소식을 올립니다. 글쓰기는 인증 선교사만 할 수 있습니다.',
       'open', 'owner', null
where not exists (select 1 from communities where type = 'open');
