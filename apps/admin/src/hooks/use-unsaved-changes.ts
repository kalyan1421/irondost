"use client";

import { useEffect, useState } from "react";

/** Guard links and browser exits. Forms with saved drafts also survive history navigation. */
export function useUnsavedChanges(dirty: boolean) {
  useEffect(() => {
    if (!dirty) return;
    const unload = (event: BeforeUnloadEvent) => { event.preventDefault(); event.returnValue = ""; };
    const navigate = (event: MouseEvent) => {
      if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      const link = (event.target as Element).closest?.("a[href]");
      if (!(link instanceof HTMLAnchorElement) || link.target === "_blank" || link.hasAttribute("download")) return;
      const next = new URL(link.href);
      if (next.pathname === location.pathname && next.search === location.search) return;
      if (!window.confirm("Leave this form? You have unsaved changes.")) { event.preventDefault(); event.stopPropagation(); }
    };
    window.addEventListener("beforeunload", unload);
    document.addEventListener("click", navigate, true);
    return () => { window.removeEventListener("beforeunload", unload); document.removeEventListener("click", navigate, true); };
  }, [dirty]);
}

export function useGuardedClose(dirty: boolean, busy: boolean, close: () => void) {
  useUnsavedChanges(dirty || busy);
  return () => { if (!busy && (!dirty || window.confirm("Discard your unsaved changes?"))) close(); };
}

export function useDraftText(key: string) {
  const [text, setText] = useState("");
  useEffect(() => {
    let active = true;
    void Promise.resolve().then(() => { if (active) { try { setText(sessionStorage.getItem(key) ?? ""); } catch {} } });
    return () => { active = false; };
  }, [key]);
  return [text, (next: string) => {
    setText(next);
    try { if (next) sessionStorage.setItem(key, next); else sessionStorage.removeItem(key); } catch {}
  }] as const;
}
