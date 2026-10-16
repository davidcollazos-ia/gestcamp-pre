"use client";

const catalogs = [
  { name: "Instalaciones", description: "Albergues, campings, refugios, polideportivos y zonas de acampada.", href: "/admin/catalogs/facilities", status: "Disponible-beta" },
  { name: "Cocina", description: "Recetas, menús, alergias, dietas y planificación de cocina.", href: "/admin/catalogs/kitchen", status: "Disponible-beta" },
  { name: "Actividades", description: "Actividades, dinámicas y propuestas para organizar el programa del campamento.", href: "/admin/catalogs/activities", status: "Disponible-beta" },
  { name: "Rutas", description: "Rutas, recorridos y propuestas de itinerarios para las salidas y excursiones.", href: "/admin/catalogs/routes", status: "Disponible-beta" },
];

export default function CatalogsIndexPage() {
  return <main className="min-h-screen bg-[#f4f8fc] px-5 py-8 text-[#062b52]"><div className="mx-auto max-w-6xl"><a href="/admin" className="font-semibold text-[#1769e8]">← Panel de administración</a><header className="mt-8"><p className="text-sm font-semibold uppercase tracking-wide text-[#1769e8]">Administración de catálogos</p><h1 className="mt-1 text-4xl font-bold">Catálogos de la aplicación</h1><p className="mt-2 text-[#5a7693]">Selecciona el catálogo que quieres gestionar.</p></header><section className="mt-8 grid gap-5 md:grid-cols-2">{catalogs.map(catalog=><a key={catalog.href} href={catalog.href} className="group rounded-2xl border border-[#d7e3ef] bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:border-[#1769e8] hover:shadow-md"><div className="flex items-start justify-between gap-4"><div><h2 className="text-2xl font-bold group-hover:text-[#1769e8]">{catalog.name}</h2><p className="mt-3 leading-6 text-[#5a7693]">{catalog.description}</p></div><span className="rounded-full bg-[#e8f7f0] px-3 py-1 text-sm font-semibold text-[#16805b]">{catalog.status}</span></div><p className="mt-6 font-semibold text-[#1769e8]">Acceder →</p></a>)}</section></div></main>;
}
