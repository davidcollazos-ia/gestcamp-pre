"use client";

const modules = [
  { name: "Gestión de campamento", description: "Organiza campamentos, turnos, participantes, equipos y la operativa diaria.", href: "/admin/modules/camp-management", status: "Disponible-beta" },
  { name: "Programación anual", description: "Planifica la actividad anual y consulta su evolución por periodos.", status: "Próximamente" },
  { name: "Eventos deportivos", description: "Gestiona eventos, convocatorias, equipos y seguimiento deportivo.", status: "Próximamente" },
  { name: "Actividades multi-organización", description: "Coordina actividades compartidas entre varias organizaciones.", status: "Próximamente" },
  { name: "Wiki", description: "Construye y comparte conocimiento operativo de la organización.", status: "Próximamente" },
];

export default function ModulesPage() {
  return <main className="min-h-screen bg-[#f4f8fc] px-5 py-8 text-[#062b52]"><div className="mx-auto max-w-6xl"><a href="/admin" className="font-semibold text-[#1769e8]">← Panel de administración</a><header className="mt-8"><p className="text-sm font-semibold uppercase tracking-wide text-[#1769e8]">Administración de módulos</p><h1 className="mt-1 text-4xl font-bold">Módulos de la aplicación</h1><p className="mt-2 text-[#5a7693]">Accede a los módulos habilitados para tu organización.</p></header><section className="mt-8 grid gap-5 md:grid-cols-2">{modules.map(module=>module.href?<a key={module.name} href={module.href} className="group rounded-2xl border border-[#d7e3ef] bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:border-[#1769e8] hover:shadow-md"><ModuleContent module={module}/></a>:<article key={module.name} className="rounded-2xl border border-[#d7e3ef] bg-white p-6 shadow-sm"><ModuleContent module={module}/></article>)}</section></div></main>;
}

function ModuleContent({module}:{module:typeof modules[number]}) { return <><div className="flex items-start justify-between gap-4"><div><h2 className="text-2xl font-bold group-hover:text-[#1769e8]">{module.name}</h2><p className="mt-3 leading-6 text-[#5a7693]">{module.description}</p></div><span className={module.status==="Disponible-beta"?"rounded-full bg-[#e8f7f0] px-3 py-1 text-sm font-semibold text-[#16805b]":"rounded-full bg-[#fff4df] px-3 py-1 text-sm font-semibold text-[#9a6700]"}>{module.status}</span></div>{module.href&&<p className="mt-6 font-semibold text-[#1769e8]">Acceder →</p>}</> }
