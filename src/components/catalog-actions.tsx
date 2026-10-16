"use client";

type Props = {
  label: string;
  onView: () => void;
  onEdit: () => void;
  onDelete: () => void;
  canManage: boolean;
};

export function CatalogActions({ label, onView, onEdit, onDelete, canManage }: Props) {
  const base = "inline-flex h-10 w-10 items-center justify-center rounded-lg border text-lg transition";
  return <div className="flex gap-2">
    <button type="button" onClick={onView} aria-label={`Ver ${label}`} title="Ver contenido" className={`${base} border-[#b8cbe0] text-[#1769e8] hover:bg-[#eef5ff]`}>👁️</button>
    <button type="button" onClick={onEdit} aria-label={`Editar ${label}`} title={canManage ? "Editar" : "No tienes permisos para editar"} disabled={!canManage} className={`${base} ${canManage ? "border-[#b8cbe0] text-[#1769e8] hover:bg-[#eef5ff]" : "cursor-not-allowed border-[#e3e8ef] text-[#aeb9c7]"}`}>✏️</button>
    <button type="button" onClick={onDelete} aria-label={`Borrar ${label}`} title={canManage ? "Borrar" : "No tienes permisos para borrar"} disabled={!canManage} className={`${base} ${canManage ? "border-[#efb4b4] text-[#b42318] hover:bg-[#fff3f3]" : "cursor-not-allowed border-[#e3e8ef] text-[#aeb9c7]"}`}>🗑️</button>
  </div>;
}

export function CatalogView({ title, item, onClose }: { title: string; item: Record<string, unknown> | null; onClose: () => void }) {
  if (!item) return null;
  const ignored = new Set(["id", "created_at", "updated_at", "version"]);
  return <div className="fixed inset-0 z-50 flex items-center justify-center bg-[#062b52]/30 p-4" role="dialog" aria-modal="true" aria-label={`Datos de ${title}`}>
    <div className="max-h-[85vh] w-full max-w-3xl overflow-auto rounded-2xl border border-[#d7e3ef] bg-white p-6 shadow-xl">
      <div className="flex items-start justify-between gap-4"><div><p className="text-sm font-semibold uppercase text-[#1769e8]">Consulta</p><h2 className="text-2xl font-bold">{title}</h2></div><button type="button" onClick={onClose} aria-label="Cerrar" title="Cerrar" className="rounded-lg border px-3 py-2 text-xl">×</button></div>
      <dl className="mt-6 grid gap-4 md:grid-cols-2">{Object.entries(item).filter(([key]) => !ignored.has(key)).map(([key, value]) => <div key={key} className="rounded-xl bg-[#f4f8fc] p-3"><dt className="text-xs font-semibold uppercase text-[#5a7693]">{key.replaceAll("_", " ")}</dt><dd className="mt-1 whitespace-pre-wrap break-words text-[#062b52]">{Array.isArray(value) ? value.join(", ") || "—" : value === null || value === "" ? "—" : String(value)}</dd></div>)}</dl>
      <div className="mt-6 flex justify-end"><button type="button" onClick={onClose} className="rounded-xl border px-5 py-2 font-semibold">Cerrar</button></div>
    </div>
  </div>;
}
