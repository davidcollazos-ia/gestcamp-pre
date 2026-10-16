"use client";
import { ReactNode } from "react";
export const catalogInput="mt-1 w-full rounded-xl border border-[#d7e3ef] bg-white px-3 py-2.5 outline-none focus:border-[#1769e8]";
export const catalogPrimary="rounded-xl bg-[#1769e8] px-5 py-3 font-semibold text-white hover:bg-[#125dcc]";
export const catalogSecondary="rounded-xl border border-[#b9cde3] bg-white px-5 py-2 font-semibold text-[#062b52] hover:bg-[#f4f8fc]";
export const catalogDanger="rounded-xl border border-[#efb4b4] bg-white px-5 py-2 font-semibold text-[#b42318] hover:bg-[#fff5f5]";
export function CatalogShell({children}:{children:ReactNode}){return <main className="min-h-screen bg-[#f4f8fc] px-5 py-8 text-[#062b52]"><div className="mx-auto max-w-7xl">{children}</div></main>}
export function CatalogBreadcrumbs({back="/admin",label="Panel de administración",current}:{back?:string;label?:string;current:string}){return <div className="flex flex-wrap items-center gap-2 text-sm font-semibold"><a href={back} className="text-[#1769e8]">← {label}</a><span className="text-[#8aa0b5]">/</span><span className="text-[#5a7693]">{current}</span></div>}
export function CatalogNotice({children}:{children:ReactNode}){return <div className="mt-6 rounded-xl border border-[#b9d2ee] bg-[#e9f3ff] p-4 text-[#174a80]">{children}</div>}
export function CatalogTabs<T extends string>({items,active,onChange}:{items:Array<{key:T;label:string}>;active:T;onChange:(key:T)=>void}){return <nav className="mt-7 flex flex-wrap gap-2 rounded-2xl border border-[#d7e3ef] bg-white p-2">{items.map(item=><button type="button" key={item.key} onClick={()=>onChange(item.key)} className={`rounded-xl px-4 py-2 font-semibold ${active===item.key?"bg-[#1769e8] text-white":"text-[#1769e8] hover:bg-[#eef5ff]"}`}>{item.label}</button>)}</nav>}
