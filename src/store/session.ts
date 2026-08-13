import type { Session } from '@supabase/supabase-js';
import { create } from 'zustand';

import { supabase } from '@/lib/supabase';

type SessionState = {
  session: Session | null;
  /** 저장된 세션을 아직 읽는 중인지. true 동안은 로그인 화면으로 튕기면 안 된다. */
  loading: boolean;
  signOut: () => Promise<void>;
};

export const useSessionStore = create<SessionState>((set) => ({
  session: null,
  loading: true,
  signOut: async () => {
    await supabase.auth.signOut();
  },
}));

/** 앱 시작 시 한 번 호출한다. 이후 세션 변화는 리스너가 스토어에 밀어 넣는다. */
export function initSessionListener() {
  supabase.auth.getSession().then(({ data }) => {
    useSessionStore.setState({ session: data.session, loading: false });
  });

  const { data } = supabase.auth.onAuthStateChange((_event, session) => {
    useSessionStore.setState({ session, loading: false });
  });

  return () => data.subscription.unsubscribe();
}
