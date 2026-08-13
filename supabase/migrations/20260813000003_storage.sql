-- michri M0 — Storage 버킷과 접근 정책
-- 전부 비공개 버킷이다. 앱은 RLS를 통과해 얻은 storage_path로 서명 URL을 만들어 쓴다.
-- 업로드 경로 규칙: '<auth.uid()>/<파일명>'. 첫 폴더가 업로더 본인이어야 한다.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars',    'avatars',    false, 5  * 1024 * 1024, array['image/jpeg','image/png','image/webp']),
  ('post-media', 'post-media', false, 15 * 1024 * 1024, array['image/jpeg','image/png','image/webp','image/heic']),
  ('stay-media', 'stay-media', false, 15 * 1024 * 1024, array['image/jpeg','image/png','image/webp','image/heic']),
  ('support-qr', 'support-qr', false, 3  * 1024 * 1024, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create or replace function public.owns_storage_path(object_name text)
returns boolean language sql stable as $$
  select auth.uid() is not null
     and (storage.foldername(object_name))[1] = auth.uid()::text;
$$;

-- 업로드·수정·삭제: 자기 폴더 안에서만
create policy "own folder write" on storage.objects for insert to authenticated
  with check (bucket_id in ('avatars','post-media','stay-media','support-qr') and public.owns_storage_path(name));

create policy "own folder update" on storage.objects for update to authenticated
  using (bucket_id in ('avatars','post-media','stay-media','support-qr') and public.owns_storage_path(name));

create policy "own folder delete" on storage.objects for delete to authenticated
  using (bucket_id in ('avatars','post-media','stay-media','support-qr') and public.owns_storage_path(name));

-- 읽기: 프로필 사진·후원 QR은 로그인 회원 전체(본체 데이터의 열람 범위와 같다),
-- 글·숙소 사진은 본체 행의 열람 권한을 그대로 따른다.
create policy "avatars read" on storage.objects for select to authenticated
  using (bucket_id = 'avatars');

create policy "support qr read" on storage.objects for select to authenticated
  using (bucket_id = 'support-qr');

create policy "post media read" on storage.objects for select to authenticated
  using (
    bucket_id = 'post-media'
    and (
      public.owns_storage_path(name)
      or exists (
        select 1 from public.post_media pm
        where pm.storage_path = storage.objects.name and public.can_view_post(pm.post_id)
      )
    )
  );

create policy "stay media read" on storage.objects for select to authenticated
  using (
    bucket_id = 'stay-media'
    and (
      public.owns_storage_path(name)
      or exists (
        select 1 from public.stay_media sm
        where sm.storage_path = storage.objects.name and public.can_view_stay(sm.stay_id)
      )
    )
  );
