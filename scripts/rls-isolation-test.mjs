/**
 * 방 간 데이터 격리 회귀 테스트.
 *
 * 기획안의 위험 항목("커뮤니티 간 데이터 누출")을 코드로 붙잡아두는 게 목적이다.
 * 앱과 똑같이 publishable key + 로그인 세션으로만 접근한다. 서비스 키는 쓰지 않는다.
 * 즉 여기서 통과한다는 건 실제 앱 경로에서 막힌다는 뜻이다.
 *
 * 실행:  node scripts/rls-isolation-test.mjs
 * 준비:  .env 에 EXPO_PUBLIC_SUPABASE_URL / EXPO_PUBLIC_SUPABASE_ANON_KEY,
 *        그리고 RLS_TEST_EMAIL_BASE=you@your-domain.com (플러스 별칭으로 계정 3개를 만든다)
 *        Supabase 대시보드에서 Authentication > Email 의 "Confirm email" 이 꺼져 있어야 한다.
 */

import { readFileSync } from 'node:fs';
import { createClient } from '@supabase/supabase-js';

// ── .env 읽기 (Expo가 아니라 순수 node로 도는 스크립트라 직접 읽는다)
const env = Object.fromEntries(
  readFileSync(new URL('../.env', import.meta.url), 'utf8')
    .split('\n')
    .filter((l) => l.trim() && !l.startsWith('#'))
    .map((l) => {
      const i = l.indexOf('=');
      return [l.slice(0, i).trim(), l.slice(i + 1).trim()];
    }),
);

const URL_ = env.EXPO_PUBLIC_SUPABASE_URL;
const KEY = env.EXPO_PUBLIC_SUPABASE_ANON_KEY;
const BASE = process.env.RLS_TEST_EMAIL_BASE ?? env.RLS_TEST_EMAIL_BASE;
const PASSWORD = 'michri-Rls-Test-9!';

if (!URL_ || !KEY) throw new Error('.env 에 EXPO_PUBLIC_SUPABASE_URL / ANON_KEY 가 필요합니다');
if (!BASE || !BASE.includes('@')) {
  throw new Error('RLS_TEST_EMAIL_BASE 가 필요합니다. 예: RLS_TEST_EMAIL_BASE=you@your-domain.com');
}

const [local, domain] = BASE.split('@');
const emailFor = (tag) => `${local}+michri-rls-${tag}@${domain}`;

// ── 결과 집계
const results = [];
function check(name, passed, detail = '') {
  results.push({ name, passed, detail });
  console.log(`${passed ? '  ✓' : '  ✗'} ${name}${detail ? `  — ${detail}` : ''}`);
}

/** 이 호출은 막혀야 한다. 에러가 나거나 0행이 오면 통과. */
function blocked(name, { data, error }) {
  const rows = Array.isArray(data) ? data.length : data ? 1 : 0;
  check(name, !!error || rows === 0, error ? `거부됨 (${error.code})` : rows > 0 ? `${rows}행 새어나옴!` : '0행');
}

/** 이 호출은 되어야 한다. */
function allowed(name, { data, error }) {
  const rows = Array.isArray(data) ? data.length : data ? 1 : 0;
  check(name, !error && rows > 0, error ? `거부됨 (${error.code}) ${error.message}` : `${rows}행`);
}

// ── 로그인 (없으면 가입)
async function actor(tag, displayName, church) {
  const sb = createClient(URL_, KEY, { auth: { persistSession: false, autoRefreshToken: false } });
  const email = emailFor(tag);

  let { data, error } = await sb.auth.signInWithPassword({ email, password: PASSWORD });
  if (error) {
    ({ data, error } = await sb.auth.signUp({ email, password: PASSWORD }));
    if (error) throw new Error(`${tag} 가입 실패: ${error.message}`);
    if (!data.session) {
      throw new Error(
        `${tag} 가입은 됐지만 세션이 없습니다. 대시보드에서 Authentication > Email 의 "Confirm email" 을 끄세요.`,
      );
    }
  }

  const uid = data.user.id;
  // 프로필은 온보딩에서 앱이 만든다. 여기서도 같은 경로로 만든다(소속 교회 필수).
  await sb.from('profiles').upsert({ id: uid, display_name: displayName, home_church: church });
  return { sb, uid, email };
}

console.log('\n[준비] 테스트 계정 3개 로그인');
const A = await actor('a', '방장 A', 'A교회'); //  프라이빗 방 A의 방장
const B = await actor('b', '외부인 B', 'B교회'); // 아무 방에도 속하지 않음
const C = await actor('c', '멤버 C', 'C교회'); //  방 C에만 속함

const stamp = Number(process.env.RLS_TEST_STAMP ?? 0) || Math.floor(Date.now() / 1000);

console.log('\n[1] 프라이빗 방은 멤버 밖으로 새지 않는다');
const { data: roomA, error: roomAError } = await A.sb
  .rpc('create_community', { p_name: `A교회 기도방 ${stamp}`, p_kind: 'church' })
  .single();
if (roomAError) throw new Error(`방 생성 실패: ${roomAError.message}`);
check('방을 만들면 개설자가 owner 멤버로 자동 등록된다',
  !!(await A.sb.from('community_members').select('role').eq('community_id', roomA.id).eq('user_id', A.uid).maybeSingle()).data);
blocked('communities 직접 insert 경로는 열려 있지 않다 (RPC를 쓴다)',
  await A.sb.from('communities').insert({ name: `직접 ${stamp}`, kind: 'etc', type: 'private', created_by: A.uid }).select());
blocked('회원 누구나 방을 만들 수 있지만 광장(open)은 못 만든다',
  await A.sb.from('communities').insert({ name: `가짜 광장 ${stamp}`, kind: 'etc', type: 'open', created_by: A.uid }).select());
allowed('방장 A는 자기 방을 조회한다', await A.sb.from('communities').select('id').eq('id', roomA.id));
blocked('외부인 B에게는 그 방이 보이지 않는다', await B.sb.from('communities').select('id').eq('id', roomA.id));
blocked('외부인 B는 그 방의 멤버 목록을 볼 수 없다', await B.sb.from('community_members').select('user_id').eq('community_id', roomA.id));
blocked('외부인 B는 남의 방에 자기를 멤버로 넣을 수 없다',
  await B.sb.from('community_members').insert({ community_id: roomA.id, user_id: B.uid, role: 'member' }).select());

console.log('\n[2] 방 안의 글은 그 방 사람만 본다');
const { data: postA } = await A.sb
  .from('posts')
  .insert({ author_id: A.uid, type: 'prayer', body: `A방 전용 기도제목 ${stamp}` })
  .select()
  .single();
await A.sb.from('post_targets').insert({ post_id: postA.id, community_id: roomA.id });
allowed('방장 A는 자기 글을 본다', await A.sb.from('posts').select('id').eq('id', postA.id));
blocked('외부인 B에게는 그 글이 보이지 않는다', await B.sb.from('posts').select('id').eq('id', postA.id));
blocked('외부인 B는 그 글의 게시 대상(어느 방인지)도 볼 수 없다',
  await B.sb.from('post_targets').select('community_id').eq('post_id', postA.id));
blocked('외부인 B는 남의 방 글에 댓글을 달 수 없다',
  await B.sb.from('comments').insert({ post_id: postA.id, community_id: roomA.id, author_id: B.uid, body: '침입' }).select());
blocked('외부인 B는 남의 방 글에 기도 반응을 남길 수 없다',
  await B.sb.from('reactions').insert({ post_id: postA.id, community_id: roomA.id, user_id: B.uid, kind: 'prayed' }).select());

console.log('\n[3] 한 글을 두 방에 올려도 댓글은 방마다 따로 쌓인다');
const { data: roomC } = await C.sb
  .rpc('create_community', { p_name: `C선교회 ${stamp}`, p_kind: 'agency' })
  .single();
// A를 C방에 넣고, A가 같은 글을 두 방에 동시 게시한다
await C.sb.from('community_members').insert({ community_id: roomC.id, user_id: A.uid, role: 'member' });
await A.sb.from('post_targets').insert({ post_id: postA.id, community_id: roomC.id });
await C.sb.from('comments').insert({ post_id: postA.id, community_id: roomC.id, author_id: C.uid, body: `C방 댓글 ${stamp}` });
await A.sb.from('comments').insert({ post_id: postA.id, community_id: roomA.id, author_id: A.uid, body: `A방 댓글 ${stamp}` });

const { data: cSeesComments } = await C.sb.from('comments').select('community_id').eq('post_id', postA.id);
check(
  'C방 멤버는 같은 글의 A방 댓글을 볼 수 없다',
  (cSeesComments ?? []).every((r) => r.community_id === roomC.id),
  `C가 본 댓글의 방: ${[...new Set((cSeesComments ?? []).map((r) => r.community_id === roomC.id ? 'C방' : 'A방!'))].join(', ') || '없음'}`,
);
const { data: aSeesComments } = await A.sb.from('comments').select('community_id').eq('post_id', postA.id);
check('두 방 모두에 속한 A는 양쪽 댓글을 다 본다', new Set((aSeesComments ?? []).map((r) => r.community_id)).size === 2,
  `${new Set((aSeesComments ?? []).map((r) => r.community_id)).size}개 방`);

console.log('\n[4] 선교사 인증이 없으면 열리지 않는 것들');
const { data: openRoom } = await A.sb.from('communities').select('id').eq('type', 'open').maybeSingle();
check('광장(type=open)은 모든 로그인 회원에게 보인다', !!openRoom, openRoom ? '' : '광장 행이 없음');
if (openRoom) {
  const { data: postForPlaza } = await B.sb
    .from('posts').insert({ author_id: B.uid, type: 'share', body: `광장 시도 ${stamp}` }).select().single();
  blocked('미인증 회원은 광장에 글을 올릴 수 없다',
    await B.sb.from('post_targets').insert({ post_id: postForPlaza.id, community_id: openRoom.id }).select());
  await B.sb.from('posts').delete().eq('id', postForPlaza.id);
}
blocked('미인증 회원은 후원 계좌를 등록할 수 없다',
  await B.sb.from('support_accounts').insert({ missionary_id: B.uid, bank: '국민', holder: 'B', account_no: '000' }).select());

console.log('\n[5] 스스로 권한을 올릴 수 없다');
blocked('본인이 자기 선교사 인증을 켤 수 없다',
  await B.sb.from('profiles').update({ verified_at: new Date().toISOString() }).eq('id', B.uid).select());
blocked('본인이 자기를 관리자로 만들 수 없다',
  await B.sb.from('profiles').update({ is_admin: true }).eq('id', B.uid).select());

console.log('\n[6] 숙소 상세 주소는 수락 전에 열리지 않는다');
const { data: stay } = await A.sb
  .from('stays')
  .insert({ host_id: A.uid, title: `서울 게스트룸 ${stamp}`, region_label: '서울 은평구', visibility: 'members', status: 'open' })
  .select()
  .single();
await A.sb.from('stay_addresses').insert({ stay_id: stay.id, address_line: '은평구 진관동 123-45', contact: '010-0000-0000' });
allowed('숙소 목록은 로그인 회원에게 보인다 (시·구까지)', await B.sb.from('stays').select('region_label').eq('id', stay.id));
blocked('요청 수락 전에는 상세 주소가 보이지 않는다', await B.sb.from('stay_addresses').select('address_line').eq('stay_id', stay.id));
blocked('미인증 회원은 숙소 요청 자체를 넣을 수 없다',
  await B.sb.from('stay_requests').insert({ stay_id: stay.id, guest_id: B.uid, date_from: '2026-09-01', date_to: '2026-09-03' }).select());

console.log('\n[7] 초대를 받으면 그때부터 보인다');
const code = `test-${stamp}`;
await A.sb.from('community_invites').insert({ community_id: roomA.id, code, created_by: A.uid });
const { data: preview } = await B.sb.rpc('preview_invite', { p_code: code });
check('아직 멤버가 아니어도 초대 코드로 방 이름은 미리 볼 수 있다', (preview ?? []).length === 1,
  (preview ?? [])[0]?.name ?? '조회 실패');
const { error: joinError } = await B.sb.rpc('join_community_by_code', { p_code: code });
check('초대 코드로 참여한다', !joinError, joinError?.message ?? '');
allowed('참여 후에는 방이 보인다', await B.sb.from('communities').select('id').eq('id', roomA.id));
allowed('참여 후에는 그 방의 글도 보인다', await B.sb.from('posts').select('id').eq('id', postA.id));

// ── 뒷정리 (테스트 계정 자체는 남는다. 지우려면 대시보드에서)
console.log('\n[정리]');
await A.sb.from('stays').delete().eq('id', stay.id);
await A.sb.from('posts').delete().eq('id', postA.id);
await C.sb.from('communities').delete().eq('id', roomC.id);
await A.sb.from('communities').delete().eq('id', roomA.id);
console.log('  테스트로 만든 방·글·숙소 삭제 완료');

const failed = results.filter((r) => !r.passed);
console.log(`\n${results.length - failed.length}/${results.length} 통과`);
if (failed.length) {
  console.log('\n실패:');
  failed.forEach((f) => console.log(`  - ${f.name} (${f.detail})`));
}
process.exit(failed.length ? 1 : 0);
