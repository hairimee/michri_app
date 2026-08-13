/**
 * 환경 변수. EXPO_PUBLIC_ 접두사가 붙은 값은 앱 번들에 그대로 들어간다.
 * 그러므로 여기에는 anon key까지만 둔다. service_role key는 절대 앱에 넣지 않는다
 * (RLS를 통째로 우회하는 열쇠다).
 */

function required(name: string, value: string | undefined): string {
  if (!value) {
    throw new Error(
      `환경 변수 ${name} 가 없습니다. .env.example 을 복사해 .env 를 만들고 값을 채우세요.`,
    );
  }
  return value;
}

export const env = {
  supabaseUrl: required('EXPO_PUBLIC_SUPABASE_URL', process.env.EXPO_PUBLIC_SUPABASE_URL),
  supabaseAnonKey: required(
    'EXPO_PUBLIC_SUPABASE_ANON_KEY',
    process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY,
  ),
};
