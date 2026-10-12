"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

export default function Home() {
  const router = useRouter();

  useEffect(() => {
    router.replace("/login");
  }, [router]);

  return <main className="flex min-h-screen items-center justify-center bg-[#f4f8fc] text-[#102a43]"><p className="text-sm text-[#55708c]">Redirigiendo al acceso…</p></main>;
  /*
  const [query, setQuery] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [organizations, setOrganizations] = useState(initialOrganizations);
  const [newName, setNewName] = useState("");
  const filtered = useMemo(() => organizations.filter((o) => `${o.name} ${o.slug}`.toLowerCase().includes(query.toLowerCase())), [organizations, query]);

  function createOrganization(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!newName.trim()) return;
    setOrganizations((current) => [{ name: newName.trim(), slug: newName.trim().toLowerCase().replace(/\s+/g, "-"), type: "Grupo scout", members: 0, status: "Activa", updated: "Ahora" }, ...current]);
    setNewName(""); setShowForm(false);
  }

  return <main className="min-h-screen bg-[#f4f8fc] text-[#102a43]"><div className="flex min-h-screen">
    <aside className="hidden w-64 flex-col border-r border-[#d8e3ef] bg-white px-5 py-6 lg:flex"><div className="mb-10 flex items-center gap-3 px-2"><div className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#1a73e8] text-lg text-white">✦</div><span className="text-xl font-semibold tracking-tight">gestcamp</span></div><p className="mb-3 px-3 text-xs font-semibold uppercase tracking-wider text-[#6f86a0]">Administración</p><nav className="space-y-1 text-sm"><a className="flex items-center gap-3 rounded-xl bg-[#eaf2fb] px-3 py-2.5 font-semibold text-[#1559a6]" href="#organizaciones">◈ Organizaciones</a><a className="flex items-center gap-3 rounded-xl px-3 py-2.5 text-[#55708c] hover:bg-[#f1f6fb]" href="#usuarios">♙ Usuarios</a><a className="flex items-center gap-3 rounded-xl px-3 py-2.5 text-[#55708c] hover:bg-[#f1f6fb]" href="#configuracion">⚙ Configuración</a></nav><div className="mt-auto rounded-2xl bg-[#eef5fc] p-4 text-sm"><p className="font-semibold">Tu espacio de trabajo</p><p className="mt-1 text-xs leading-5 text-[#55708c]">Gestiona tus organizaciones scout desde un único lugar.</p></div></aside>
    <section className="flex-1 px-5 py-6 sm:px-8 lg:px-12 lg:py-10"><header className="mb-10 flex items-start justify-between gap-4"><div><p className="mb-2 text-sm font-medium text-[#55708c]">Administración general</p><h1 className="text-3xl font-semibold tracking-tight sm:text-4xl">Organizaciones</h1><p className="mt-2 max-w-xl text-sm leading-6 text-[#55708c]">Crea y administra los grupos scout y asociaciones que forman parte de gestcamp.</p></div><button onClick={() => setShowForm(true)} className="rounded-xl bg-[#1a73e8] px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-[#1559a6]">+ Nueva organización</button></header>
      <div className="mb-8 grid gap-4 sm:grid-cols-3"><Stat label="Organizaciones" value={organizations.length.toString()} detail="en tu espacio" /><Stat label="Usuarios" value={organizations.reduce((total, item) => total + item.members, 0).toString()} detail="miembros activos" /><Stat label="Estado" value="100%" detail="servicio operativo" /></div>
      <div id="organizaciones" className="rounded-2xl border border-[#d8e3ef] bg-white shadow-[0_4px_20px_rgba(16,42,67,0.06)]"><div className="flex flex-col gap-4 border-b border-[#e7eef6] p-5 sm:flex-row sm:items-center sm:justify-between"><div><h2 className="font-semibold">Todas las organizaciones</h2><p className="mt-1 text-xs text-[#6f86a0]">Gestiona el acceso y la configuración de cada tenant.</p></div><label className="flex items-center gap-2 rounded-xl border border-[#d8e3ef] px-3 py-2 text-sm text-[#6f86a0] focus-within:border-[#1a73e8]">⌕ <input value={query} onChange={(event) => setQuery(event.target.value)} className="w-full bg-transparent outline-none placeholder:text-[#9db1c5] sm:w-52" placeholder="Buscar organización" /></label></div><div className="overflow-x-auto"><table className="w-full min-w-[680px] text-left text-sm"><thead className="bg-[#f8fbfe] text-xs uppercase tracking-wide text-[#6f86a0]"><tr><th className="px-5 py-3 font-medium">Organización</th><th className="px-5 py-3 font-medium">Tipo</th><th className="px-5 py-3 font-medium">Miembros</th><th className="px-5 py-3 font-medium">Estado</th><th className="px-5 py-3 font-medium">Última actividad</th><th className="px-5 py-3" /></tr></thead><tbody className="divide-y divide-[#e7eef6]">{filtered.map((o) => <tr key={o.slug} className="transition hover:bg-[#f8fbfe]"><td className="px-5 py-4"><p className="font-semibold">{o.name}</p><p className="mt-1 text-xs text-[#6f86a0]">{o.slug}.gestcamp.app</p></td><td className="px-5 py-4 text-[#55708c]">{o.type}</td><td className="px-5 py-4 text-[#55708c]">{o.members}</td><td className="px-5 py-4"><span className={`rounded-full px-2.5 py-1 text-xs font-semibold ${o.status === "Activa" ? "bg-[#e8f3ff] text-[#1559a6]" : "bg-[#fff5d9] text-[#9a721b]"}`}>{o.status}</span></td><td className="px-5 py-4 text-[#6f86a0]">{o.updated}</td><td className="px-5 py-4 text-right text-[#6f86a0]">•••</td></tr>)}</tbody></table>{filtered.length === 0 && <p className="p-10 text-center text-sm text-[#6f86a0]">No se han encontrado organizaciones.</p>}</div></div>
    </section></div>
    {showForm && <div className="fixed inset-0 z-10 flex items-center justify-center bg-[#102a43]/30 p-5"><form onSubmit={createOrganization} className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl"><div className="flex items-start justify-between"><div><h2 className="text-xl font-semibold">Nueva organización</h2><p className="mt-1 text-sm text-[#55708c]">Empezaremos con los datos básicos.</p></div><button type="button" onClick={() => setShowForm(false)} className="text-xl text-[#6f86a0]">×</button></div><label className="mt-6 block text-sm font-medium">Nombre de la organización<input autoFocus value={newName} onChange={(event) => setNewName(event.target.value)} className="mt-2 w-full rounded-xl border border-[#d8e3ef] px-3 py-2.5 outline-none focus:border-[#1a73e8]" placeholder="Ej. Grupo Scout Amanecer" /></label><div className="mt-6 flex justify-end gap-3"><button type="button" onClick={() => setShowForm(false)} className="rounded-xl px-4 py-2.5 text-sm font-semibold text-[#55708c] hover:bg-[#f1f6fb]">Cancelar</button><button type="submit" className="rounded-xl bg-[#1a73e8] px-4 py-2.5 text-sm font-semibold text-white hover:bg-[#1559a6]">Crear organización</button></div></form></div>}
  </main>;
  */
}

