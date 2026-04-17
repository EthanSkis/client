import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

export const SUPABASE_URL      = 'https://qunobrixpnerocdntkio.supabase.co';
export const SUPABASE_ANON_KEY = 'sb_publishable_P-w2YUP5j2PcUPJrqZ3Xxg_Wk0BqSRu';
export const LOGIN_URL         = 'https://login.clearbot.io';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    flowType: 'pkce',
  },
});
