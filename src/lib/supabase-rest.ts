const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

export type AuthSession = {
  access_token: string;
  refresh_token: string;
  user: { id: string; email?: string };
};

export type OrganizationMembership = {
  organization_id: string;
  role_id: string | null;
  status: string;
  organization?: { id: string; name: string; slug: string; organization_type: string; parent_organization_id: string | null; };
  role?: { id: string; name: string; permissions: Record<string, boolean> };
};

export type Organization = {
  [key: string]: any;
  id: string; name: string; display_name: string | null; slug: string;
  organization_type: string; tax_id: string | null; status: string;
  parent_organization_id: string | null; description: string | null;
  address: string | null; postal_code: string | null; city: string | null;
  region: string | null; country: string; contact_name: string | null;
  contact_role: string | null; contact_email: string | null; phone: string | null;
  website: string | null; created_at: string; updated_at: string;
};

export type OrganizationInput = Omit<Organization, "id" | "created_at" | "updated_at">;

function headers(accessToken?: string) {
  if (!supabaseUrl || !supabaseKey) {
    throw new Error("Falta la configuración de Supabase en este despliegue.");
  }
  return {
    apikey: supabaseKey,
    Authorization: `Bearer ${accessToken ?? supabaseKey}`,
    "Content-Type": "application/json",
  };
}

export async function signInWithPassword(email: string, password: string): Promise<AuthSession> {
  const response = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify({ email, password }),
  });
  const body = await response.text();
  let data: Record<string, unknown> = {};
  try { data = JSON.parse(body) as Record<string, unknown>; } catch { throw new Error(`Supabase no respondió correctamente (${response.status}). Comprueba la URL y la clave local.`); }
  if (!response.ok) throw new Error(String(data.error_description ?? data.msg ?? "No se pudo iniciar sesión."));
  return data as AuthSession;
}

export async function resetPasswordForEmail(email: string) {
  if (!supabaseUrl || !supabaseKey) {
    throw new Error("Falta la configuración de Supabase en este despliegue. Revisa las variables de Vercel.");
  }
  const response = await fetch(`${supabaseUrl}/auth/v1/recover`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify({ email, redirect_to: `${window.location.origin}/reset-password` }),
  });
  if (!response.ok) {
    const body = await response.text();
    let message = "No se pudo enviar el correo de recuperación.";
    try {
      const data = JSON.parse(body) as Record<string, unknown>;
      message = String(data.error_description ?? data.msg ?? data.message ?? message);
    } catch { /* Supabase puede devolver texto HTML en un error de proxy. */ }
    throw new Error(`${message} (HTTP ${response.status})`);
  }
}

export async function updatePassword(accessToken: string, password: string) {
  const response = await fetch(`${supabaseUrl}/auth/v1/user`, {
    method: "PUT",
    headers: headers(accessToken),
    body: JSON.stringify({ password }),
  });
  if (!response.ok) throw new Error("No se pudo actualizar la contraseña.");
}

export async function getPlatformAdmin(accessToken: string, userId: string) {
  const meResponse = await fetch(`${supabaseUrl}/auth/v1/user`, { headers: headers(accessToken) });
  if (meResponse.ok) {
    const me = await meResponse.json() as { id?: string };
    userId = me.id ?? userId;
  }
  const response = await fetch(`${supabaseUrl}/rest/v1/platform_admins?user_id=eq.${encodeURIComponent(userId)}&select=user_id`, {
    headers: headers(accessToken),
  });
  if (!response.ok) return false;
  const data = await response.json();
  return Array.isArray(data) && data.length > 0;
}

export function googleSignInUrl() {
  return `${supabaseUrl}/auth/v1/authorize?provider=google&redirect_to=${encodeURIComponent(`${window.location.origin}/login`)}&prompt=select_account`;
}

export async function signOut(accessToken: string) {
  await fetch(`${supabaseUrl}/auth/v1/logout`, {
    method: "POST",
    headers: headers(accessToken),
  });
}

export async function getMyOrganizations(accessToken: string): Promise<OrganizationMembership[]> {
  const me = await fetch(`${supabaseUrl}/auth/v1/user`, { headers: headers(accessToken) });
  if (!me.ok) return [];
  const user = await me.json() as { id: string };
  const membershipsResponse = await fetch(`${supabaseUrl}/rest/v1/organization_members?user_id=eq.${encodeURIComponent(user.id)}&status=eq.active&select=organization_id,role_id,status`, { headers: headers(accessToken) });
  if (!membershipsResponse.ok) return [];
  const memberships = await membershipsResponse.json() as OrganizationMembership[];
  if (!memberships.length) return [];
  const ids = memberships.map((item) => item.organization_id).join(",");
  const organizationsResponse = await fetch(`${supabaseUrl}/rest/v1/organizations?id=in.(${ids})&select=id,name,slug,organization_type,parent_organization_id`, { headers: headers(accessToken) });
  const organizations = organizationsResponse.ok ? await organizationsResponse.json() as OrganizationMembership["organization"][] : [];
  const roleIds = memberships.map((item) => item.role_id).filter(Boolean).join(",");
  const rolesResponse = roleIds ? await fetch(`${supabaseUrl}/rest/v1/roles?id=in.(${roleIds})&select=id,name,permissions`, { headers: headers(accessToken) }) : null;
  const roles = rolesResponse?.ok ? await rolesResponse.json() as OrganizationMembership["role"][] : [];
  return memberships.map((membership) => ({ ...membership, organization: organizations.find((item) => item?.id === membership.organization_id), role: roles.find((item) => item?.id === membership.role_id) }));
}

const organizationSelect = "id,name,display_name,slug,organization_type,tax_id,status,parent_organization_id,description,address,postal_code,city,region,country,contact_name,contact_role,contact_email,phone,website,created_at,updated_at";

async function restError(response: Response) {
  if (response.ok) return;
  const body = await response.text();
  let message = "No se pudo completar la operación.";
  try { const data = JSON.parse(body) as Record<string, unknown>; message = String(data.message ?? data.hint ?? data.details ?? message); } catch {}
  throw new Error(`${message} (HTTP ${response.status})`);
}

export async function listOrganizations(accessToken: string): Promise<Organization[]> {
  const response = await fetch(`${supabaseUrl}/rest/v1/organizations?select=${organizationSelect}&order=name.asc`, { headers: headers(accessToken) });
  await restError(response); return await response.json() as Organization[];
}

export async function createOrganization(accessToken: string, input: OrganizationInput): Promise<Organization> {
  const response = await fetch(`${supabaseUrl}/rest/v1/organizations`, { method: "POST", headers: { ...headers(accessToken), Prefer: "return=representation" }, body: JSON.stringify(input) });
  await restError(response); return (await response.json() as Organization[])[0];
}

export async function updateOrganization(accessToken: string, id: string, input: Partial<OrganizationInput>): Promise<Organization> {
  const response = await fetch(`${supabaseUrl}/rest/v1/organizations?id=eq.${encodeURIComponent(id)}`, { method: "PATCH", headers: { ...headers(accessToken), Prefer: "return=representation" }, body: JSON.stringify(input) });
  await restError(response); return (await response.json() as Organization[])[0];
}

export async function deleteOrganization(accessToken: string, id: string): Promise<void> {
  const response = await fetch(`${supabaseUrl}/rest/v1/organizations?id=eq.${encodeURIComponent(id)}`, { method: "DELETE", headers: headers(accessToken) });
  await restError(response);
}

export type OrganizationUser = {
  id: string;
  organization_id: string;
  user_id: string;
  role_id: string | null;
  status: string;
  created_at: string;
};

export type OrganizationInvitation = {
  id: string;
  organization_id: string;
  email: string;
  role_id: string | null;
  status: string;
  created_at: string;
};

export type Role = { id: string; organization_id: string | null; name: string; permissions: Record<string, boolean> };

export async function listOrganizationUsers(accessToken: string): Promise<OrganizationUser[]> {
  const response = await fetch(`${supabaseUrl}/rest/v1/organization_members?select=id,organization_id,user_id,role_id,status,created_at&order=created_at.desc`, { headers: headers(accessToken) });
  await restError(response);
  return await response.json() as OrganizationUser[];
}

export async function listRoles(accessToken: string): Promise<Role[]> {
  const response = await fetch(`${supabaseUrl}/rest/v1/roles?select=id,organization_id,name,permissions&order=name.asc`, { headers: headers(accessToken) });
  await restError(response);
  return await response.json() as Role[];
}

export async function inviteOrganizationUser(accessToken: string, input: { organization_id: string; email: string; role_id: string | null; invited_by_user_id: string }): Promise<OrganizationInvitation> {
  const response = await fetch(`${supabaseUrl}/rest/v1/organization_invitations`, { method: "POST", headers: { ...headers(accessToken), Prefer: "return=representation" }, body: JSON.stringify({ ...input, status: "pending" }) });
  await restError(response);
  return (await response.json() as OrganizationInvitation[])[0];
}

export async function deleteOrganizationUser(accessToken: string, id: string): Promise<void> {
  const response = await fetch(`${supabaseUrl}/rest/v1/organization_members?id=eq.${encodeURIComponent(id)}`, { method: "DELETE", headers: headers(accessToken) });
  await restError(response);
}
