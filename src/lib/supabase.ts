import 'react-native-url-polyfill/auto';

import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient } from '@supabase/supabase-js';
import { AppState } from 'react-native';

import { env } from './env';
import type { Database } from '@/types/database';

export const supabase = createClient<Database>(env.supabaseUrl, env.supabaseAnonKey, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    // 딥링크로 열리는 앱이라 URL에서 세션을 줍지 않는다(초대 링크 처리와 충돌한다).
    detectSessionInUrl: false,
  },
});

// 앱이 포그라운드일 때만 토큰을 갱신한다. 백그라운드에서 돌리면 배터리만 먹는다.
AppState.addEventListener('change', (state) => {
  if (state === 'active') {
    supabase.auth.startAutoRefresh();
  } else {
    supabase.auth.stopAutoRefresh();
  }
});
