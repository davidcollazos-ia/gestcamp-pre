"use client";

import { FormEvent, useState } from "react";
import { updatePassword } from "@/lib/supabase-rest";

export default function ResetPasswordPage() {
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setError("");
    const accessToken = new URLSearchParams(window.location.hash.replace(/^#/, "")).get("access_token");
    if (!accessToken) { setError("El enlace de recuperación no es válido o ha caducado."); return; }
    try { await updatePassword(accessToken, password); setMessage("Contraseña actualizada. Ya puedes iniciar sesión."); }
    catch (reason) { setError(reason instanceof Error ? reason.message : "No se pudo actualizar la contraseña."); }
  }

  return <main className="flex min-h-screen items-center justify-center bg-[#f4f8fc] px-5 text-[#102a43]"><form onSubmit={submit} className="w-full max-w-md rounded-3xl border border-[#d8e3ef] bg-white p-8 shadow-[0_12px_40px_rgba(16,42,67,0.08)]"><h1 className="text-2xl font-semibold">Nueva contraseña</h1><p className="mt-2 text-sm text-[#55708c]">Elige una contraseña para tu cuenta de gestcamp.</p><input required minLength={6} type="password" value={password} onChange={(event) => setPassword(event.target.value)} className="mt-6 w-full rounded-xl border border-[#d8e3ef] px-3 py-2.5 outline-none focus:border-[#1a73e8]" placeholder="Nueva contraseña" />{error && <p className="mt-4 rounded-xl bg-[#fff0ee] p-3 text-sm text-[#a33d31]">{error}</p>}{message && <p className="mt-4 rounded-xl bg-[#eaf2fb] p-3 text-sm text-[#1559a6]">{message}</p>}<button className="mt-6 w-full rounded-xl bg-[#1a73e8] px-4 py-3 text-sm font-semibold text-white hover:bg-[#1559a6]">Actualizar contraseña</button></form></main>;
}
