"use client";

import { FormEvent, useEffect, useState } from "react";
import { googleSignInUrl, resetPasswordForEmail, signInWithPassword } from "@/lib/supabase-rest";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [recoverySent, setRecoverySent] = useState(false);

  useEffect(() => {
    const params = new URLSearchParams(window.location.hash.replace(/^#/, ""));
    const accessToken = params.get("access_token");
    const refreshToken = params.get("refresh_token");
    const userId = params.get("user");
    if (accessToken && refreshToken) {
      const session = { access_token: accessToken, refresh_token: refreshToken, user: { id: userId ?? "", email: "" } };
      localStorage.setItem("gestcamp_session", JSON.stringify(session));
      window.history.replaceState(null, "", "/login");
      window.location.href = "/admin";
    }
  }, []);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setError(""); setLoading(true);
    try {
      const session = await signInWithPassword(email, password);
      localStorage.setItem("gestcamp_session", JSON.stringify(session));
      window.location.href = "/admin";
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "No se pudo iniciar sesión.");
    } finally { setLoading(false); }
  }

  async function recoverPassword() {
    if (!email.trim()) { setError("Introduce primero tu email."); return; }
    setError(""); setLoading(true);
    try { await resetPasswordForEmail(email.trim()); setRecoverySent(true); }
    catch (reason) { setError(reason instanceof Error ? reason.message : "No se pudo enviar el correo."); }
    finally { setLoading(false); }
  }

  return <main className="flex min-h-screen items-center justify-center bg-[#f4f8fc] px-5 text-[#102a43]"><section className="w-full max-w-md rounded-3xl border border-[#d8e3ef] bg-white p-8 shadow-[0_12px_40px_rgba(16,42,67,0.08)]"><div className="mb-8 text-center"><div className="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-[#1a73e8] text-xl text-white">✦</div><h1 className="mt-5 text-2xl font-semibold">Accede a gestcamp</h1><p className="mt-2 text-sm text-[#55708c]">Gestiona tus organizaciones scout.</p></div>{recoverySent ? <p className="rounded-xl bg-[#eaf2fb] p-4 text-sm text-[#1559a6]">Te hemos enviado un correo para restablecer la contraseña.</p> : <form onSubmit={submit} className="space-y-4"><label className="block text-sm font-medium">Email<input type="email" required value={email} onChange={(event) => setEmail(event.target.value)} className="mt-2 w-full rounded-xl border border-[#d8e3ef] px-3 py-2.5 outline-none focus:border-[#1a73e8]" placeholder="tu@email.com" /></label><label className="block text-sm font-medium">Contraseña<input type="password" required value={password} onChange={(event) => setPassword(event.target.value)} className="mt-2 w-full rounded-xl border border-[#d8e3ef] px-3 py-2.5 outline-none focus:border-[#1a73e8]" /></label>{error && <p className="rounded-xl bg-[#fff0ee] p-3 text-sm text-[#a33d31]">{error}</p>}<button disabled={loading} className="w-full rounded-xl bg-[#1a73e8] px-4 py-3 text-sm font-semibold text-white hover:bg-[#1559a6] disabled:opacity-60">{loading ? "Accediendo…" : "Iniciar sesión"}</button><button type="button" onClick={recoverPassword} className="w-full text-sm font-medium text-[#1a73e8] hover:underline">He olvidado mi contraseña</button></form>}<div className="my-6 flex items-center gap-3 text-xs text-[#6f86a0]"><span className="h-px flex-1 bg-[#e2ebf4]" />o<span className="h-px flex-1 bg-[#e2ebf4]" /></div><button onClick={() => { window.location.href = googleSignInUrl(); }} className="w-full rounded-xl border border-[#d8e3ef] px-4 py-3 text-sm font-semibold hover:bg-[#f1f6fb]">Continuar con Google</button></section></main>;
}
