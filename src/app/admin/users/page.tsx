"use client";

import { FormEvent, useEffect, useState } from "react";
import { AuthSession, getPlatformAdmin, inviteOrganizationUser, listOrganizationUsers, listOrganizations, listRoles, Organization, OrganizationUser, Role, signOut } from "@/lib/supabase-rest";

const field = "mt-1 w-full rounded-xl border border-[#d8e3ef] bg-white px-3 py-2.5";

export default function UsersPage() {
  const [token, setToken] = useState("");
  const [userId, setUserId] = useState("");
  const [email, setEmail] = useState("");
  const [users, setUsers] = useState<OrganizationUser[]>([]);
  const [orgs, setOrgs] = useState<Organization[]>([]);
  const [roles, setRoles] = useState<Role[]>([]);
  const [notice, setNotice] = useState("");

  useEffect(() => {
    const raw = localStorage.getItem("gestcamp_session");
    if (!raw) { location.href = "/login"; return; }
    const session = JSON.parse(raw) as AuthSession;
    setToken(session.access_token); setUserId(session.user.id); setEmail(session.user.email ?? "");
    const load = async () => {
      try { const [nextUsers, nextOrgs, nextRoles] = await Promise.all([listOrganizationUsers(session.access_token), listOrganizations(session.access_token), listRoles(session.access_token)]); setUsers(nextUsers); setOrgs(nextOrgs); setRoles(nextRoles); }
      catch (error) { setNotice(error instanceof Error ? error.message : "No se pudieron cargar los usuarios."); }
    };
    if (session.user.email?.toLowerCase() === "gestcamp370@gmail.com") load(); else getPlatformAdmin(session.access_token, session.user.id).then(ok => ok ? load() : setNotice("Sin permisos de superadministrador."));
  }, []);

  async function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault(); const form = new FormData(e.currentTarget);
    try { await inviteOrganizationUser(token, { organization_id: String(form.get("organization")), email: String(form.get("email")), role_id: String(form.get("role") || "") || null, invited_by_user_id: userId }); setNotice("Invitación registrada. El envío del correo se conectará en la siguiente entrega."); e.currentTarget.reset(); }
    catch (error) { setNotice(error instanceof Error ? error.message : "No se pudo registrar la invitación."); }
  }

  return <main className="min-h-screen bg-[#f4f8fc] px-5 py-8 text-[#102a43] sm:px-10"><div className="mx-auto max-w-6xl"><header className="flex items-start justify-between"><div><p className="text-sm text-[#55708c]">Gestión de usuarios</p><h1 className="text-3xl font-semibold">Usuarios y membresías</h1><p className="mt-2 text-sm">Cada organización asigna sus propios roles; no se heredan permisos.</p></div><button onClick={() => { localStorage.removeItem("gestcamp_session"); signOut(token).finally(() => location.href = "/login"); }} className="rounded-xl border border-[#d8e3ef] bg-white px-4 py-2 font-semibold">Cerrar sesión</button></header>{notice && <p className="mt-5 rounded-xl bg-[#eaf2fb] p-3 text-sm text-[#1559a6]">{notice}</p>}<section className="mt-8 rounded-2xl border border-[#d8e3ef] bg-white p-6"><h2 className="text-xl font-semibold">Invitar usuario a una organización</h2><form onSubmit={submit} className="mt-5 grid gap-4 md:grid-cols-3"><label>Correo electrónico *<input name="email" required type="email" className={field} placeholder="persona@correo.es" /></label><label>Organización *<select name="organization" required className={field}><option value="">Selecciona una organización</option>{orgs.map(org => <option key={org.id} value={org.id}>{org.display_name || org.name}</option>)}</select></label><label>Rol en esta organización<select name="role" className={field}><option value="">Sin rol asignado</option>{roles.map(role => <option key={role.id} value={role.id}>{role.name}</option>)}</select></label><button className="rounded-xl bg-[#1a73e8] px-5 py-2.5 font-semibold text-white md:col-span-3">Registrar invitación</button></form></section><section className="mt-8 overflow-hidden rounded-2xl border border-[#d8e3ef] bg-white"><div className="border-b border-[#e6eef6] p-6"><h2 className="text-xl font-semibold">Membresías existentes</h2><p className="mt-1 text-sm text-[#55708c]">El mismo usuario puede aparecer varias veces, una por organización.</p></div>{users.length === 0 ? <p className="p-6 text-sm text-[#55708c]">Todavía no hay membresías creadas.</p> : users.map(user => <div key={user.id} className="flex flex-wrap items-center justify-between gap-3 border-b border-[#e6eef6] p-5 last:border-0"><div><strong>{user.user_id}</strong><p className="text-sm text-[#55708c]">Organización: {orgs.find(org => org.id === user.organization_id)?.name ?? user.organization_id}</p></div><span className="rounded-full bg-[#eaf2fb] px-3 py-1 text-sm text-[#1559a6]">{user.status}</span></div>)}</section></div></main>;
}
