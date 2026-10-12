const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

export type AuthSession = {
  access_token: string;
  refresh_token: string;
  user: { id: string; email?: string };
};

function headers(accessToken?: string) {
  if (!supabaseUrl || !supabaseKey) throw new Error("Falta la configuración de Supabase en este despliegue.");
  return { apikey: supabaseKey, Authorization: `Bearer ${accessToken ?? supabaseKey}`, "Content-Type": "application/json" };
}

export async function signInWithPassword(email: string, password: string): Promise<AuthSession> {
  if (!supabaseUrl || !supabaseKey) throw new Error("Falta la configuración de Supabase en este despliegue.");
  const response = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, { method: "POST", headers: headers(), body: JSON.stringify({ email, password }) });
  const body = await response.text();
  let data: Record<string, unknown> = {};
  try { data = JSON.parse(body) as Record<string, unknown>; } catch { throw new Error(`Supabase no respondió correctamente (${response.status}).`); }
  if (!response.ok) throw new Error(String(data.error_description ?? data.msg ?? "No se pudo iniciar sesión."));
  return data as AuthSession;
}

export async function resetPasswordForEmail(email: string) {
  if (!supabaseUrl || !supabaseKey) throw new Error("Falta la configuración de Supabase en este despliegue. Revisa las variables de Vercel.");
  const response = await fetch(`${supabaseUrl}/auth/v1/recover`, { method: "POST", headers: headers(), body: JSON.stringify({ email, redirect_to: `${window.location.origin}/reset-password` }) });
  if (!response.ok) {
    const body = await response.text();
    let message = "No se pudo enviar el correo de recuperación.";
    try { const data = JSON.parse(body) as Record<string, unknown>; message = String(data.error_description ?? data.msg ?? data.message ?? message); } catch {}
    throw new Error(`${message} (HTTP ${response.status})`);
  }
}

export async function updatePassword(accessToken: string, password: string) {
  const response = await fetch(`${supabaseUrl}/auth/v1/user`, { method: "PUT", headers: headers(accessToken), body: JSON.stringify({ password }) });
  if (!response.ok) throw new Error("No se pudo actualizar la contraseña.");
}

export async function getPlatformAdmin(accessToken: string, userId: string) {
  const response = await fetch(`${supabaseUrl}/rest/v1/platform_admins?user_id=eq.${userId}&select=user_id`, { headers: headers(accessToken) });
  if (!response.ok) return false;
  const data = await response.json();
  return Array.isArray(data) && data.length > 0;
}

export function googleSignInUrl() {
  return `${supabaseUrl}/auth/v1/authorize?provider=google&redirect_to=${encodeURIComponent(`${window.location.origin}/login`)}`;
}
