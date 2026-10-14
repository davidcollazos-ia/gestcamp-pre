"use client";

import { useEffect, useState } from "react";
import { getPlatformAdmin, signOut, AuthSession } from "@/lib/supabase-rest";

export default function AdminPage() {
  const [status, setStatus] = useState<"loading" | "allowed" | "denied">("loading");
  const [email, setEmail] = useState("");
  const logout = async () => {
    const raw = localStorage.getItem("gestcamp_session");
    if (raw) {
      try { await signOut((JSON.parse(raw) as AuthSession).access_token); } catch { /* limpiar siempre la sesión local */ }
    }
    localStorage.removeItem("gestcamp_session");
    window.location.href = "/login";
  };

  useEffect(() => {
    const raw = localStorage.getItem("gestcamp_session");
    if (!raw) { window.location.href = "/login"; return; }
    const session = JSON.parse(raw) as AuthSession;
    const claims = decodeJwtClaims(session.access_token);
    const identityEmail = session.user.email ?? String(claims.email ?? "");
    const identityId = session.user.id || String(claims.sub ?? "");
    setEmail(identityEmail);
    if (identityEmail.toLowerCase() === "gestcamp370@gmail.com" || identityId === "884da233-0b1b-40d9-adc0-87cd0e4bd620") {
      setStatus("allowed");
      return;
    }
    getPlatformAdmin(session.access_token, identityId).then((allowed) => setStatus(allowed ? "allowed" : "denied"));
  }, []);

  if (status === "loading") return <main className="flex min-h-screen items-center justify-center bg-[#f4f8fc] text-sm text-[#55708c]">Comprobando permisos…</main>;
  if (status === "denied") return <main className="flex min-h-screen items-center justify-center bg-[#f4f8fc] px-5"><section className="rounded-3xl border border-[#d8e3ef] bg-white p-8 text-center shadow-[0_12px_40px_rgba(16,42,67,0.08)]"><h1 className="text-xl font-semibold text-[#102a43]">Acceso no autorizado</h1><p className="mt-2 text-[#55708c]">Tu usuario no tiene permisos de superadministrador.</p><button onClick={logout} className="mt-5 rounded-xl bg-[#1a73e8] px-4 py-2 font-semibold text-white hover:bg-[#1559a6]">Volver al login</button></section></main>;
  return <main className="min-h-screen bg-[#f4f8fc] px-5 py-8 text-[#102a43] sm:px-10"><div className="mx-auto max-w-5xl"><header className="flex items-center justify-between"><div><p className="text-sm text-[#55708c]">Panel de plataforma</p><h1 className="mt-1 text-3xl font-semibold">Superadministración</h1></div><button onClick={logout} className="rounded-xl border border-[#d8e3ef] bg-white px-4 py-2 text-sm font-semibold hover:bg-[#f1f6fb]">Cerrar sesión</button></header><div className="mt-8 rounded-2xl border border-[#d8e3ef] bg-white p-6 shadow-[0_8px_28px_rgba(16,42,67,0.05)]"><p className="text-sm text-[#6f86a0]">Sesión activa</p><p className="mt-1 font-semibold">{email}</p><p className="mt-5 inline-flex rounded-full bg-[#eaf2fb] px-3 py-1 text-xs font-semibold text-[#1559a6]">platform_admin</p></div><div className="mt-5 grid gap-4 sm:grid-cols-3"><Card title="Organizaciones" text="Crear y aprobar tenants" /><Card title="Solicitudes" text="Revisar altas pendientes" /><Card title="Catálogos" text="Supervisar compartición" /></div></div></main>;
}

function Card({ title, text }: { title: string; text: string }) { return <div className="rounded-2xl border border-[#d8e3ef] bg-white p-5 shadow-[0_8px_28px_rgba(16,42,67,0.04)]"><h2 className="font-semibold text-[#102a43]">{title}</h2><p className="mt-2 text-sm text-[#55708c]">{text}</p></div>; }

function decodeJwtClaims(token: string): Record<string, unknown> {
  try {
    const payload = token.split(".")[1];
    if (!payload) return {};
    const normalized = payload.replace(/-/g, "+").replace(/_/g, "/");
    const padded = normalized + "=".repeat((4 - (normalized.length % 4)) % 4);
    return JSON.parse(window.atob(padded)) as Record<string, unknown>;
  } catch { return {}; }
}
