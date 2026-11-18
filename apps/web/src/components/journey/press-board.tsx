"use client";

import { useEffect, useRef, useState } from "react";

/**
 * The signature move: a creased suit jacket that the visitor presses smooth by dragging across it.
 * The pressed photo is painted through a mask wherever the "iron" passes. A button does the same for
 * keyboard users and for reduced motion. Ported from scrollcraft/builds/irondost-draft-a.
 */
export function PressBoard({ creased, pressed, label }: { creased: string; pressed: string; label: string }) {
  const boardRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const ironRef = useRef<HTMLSpanElement>(null);
  const autoRef = useRef<() => void>(() => {});
  const [done, setDone] = useState(false);

  useEffect(() => {
    const board = boardRef.current!;
    const canvas = canvasRef.current!;
    const iron = ironRef.current!;
    const ctx = canvas.getContext("2d")!;
    const mask = document.createElement("canvas");
    const mctx = mask.getContext("2d")!;
    const img = new Image();
    img.src = pressed;
    const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
    let last: { x: number; y: number; cx: number; cy: number } | null = null;
    let strokes = 0;
    let finished = false;

    const render = () => {
      if (!img.complete || !canvas.width) return;
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.globalCompositeOperation = "source-over";
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
      ctx.globalCompositeOperation = "destination-in";
      ctx.drawImage(mask, 0, 0);
      ctx.globalCompositeOperation = "source-over";
    };
    const size = () => {
      const r = board.getBoundingClientRect();
      const d = Math.min(2, devicePixelRatio || 1);
      const w = Math.round(r.width * d);
      const h = Math.round(r.height * d);
      if (!w || canvas.width === w) return;
      let keep: HTMLCanvasElement | null = null;
      if (mask.width) {
        keep = document.createElement("canvas");
        keep.width = mask.width;
        keep.height = mask.height;
        keep.getContext("2d")!.drawImage(mask, 0, 0);
      }
      canvas.width = mask.width = w;
      canvas.height = mask.height = h;
      if (keep) mctx.drawImage(keep, 0, 0, w, h);
      render();
    };
    const stamp = (x: number, y: number) => {
      const rad = canvas.width * 0.09;
      const g = mctx.createRadialGradient(x, y, rad * 0.35, x, y, rad);
      g.addColorStop(0, "rgba(0,0,0,1)");
      g.addColorStop(1, "rgba(0,0,0,0)");
      mctx.fillStyle = g;
      mctx.beginPath();
      mctx.arc(x, y, rad, 0, Math.PI * 2);
      mctx.fill();
    };
    const check = () => {
      if (finished) return;
      const s = 24;
      const t = document.createElement("canvas");
      t.width = t.height = s;
      const c = t.getContext("2d")!;
      c.drawImage(mask, 0, 0, s, s);
      const d = c.getImageData(0, 0, s, s).data;
      let on = 0;
      for (let i = 3; i < d.length; i += 4) if (d[i] > 120) on++;
      if (on / (s * s) > 0.55) {
        finished = true;
        setDone(true);
      }
    };
    const line = (a: { x: number; y: number }, b: { x: number; y: number }) => {
      const dx = b.x - a.x;
      const dy = b.y - a.y;
      const n = Math.max(1, Math.ceil(Math.hypot(dx, dy) / (canvas.width * 0.02)));
      for (let i = 0; i <= n; i++) stamp(a.x + (dx * i) / n, a.y + (dy * i) / n);
      render();
      if (++strokes % 12 === 0) check();
    };
    const local = (e: PointerEvent) => {
      const r = canvas.getBoundingClientRect();
      const k = canvas.width / r.width;
      return { x: (e.clientX - r.left) * k, y: (e.clientY - r.top) * k, cx: e.clientX - r.left, cy: e.clientY - r.top };
    };
    const moveIron = (p: { cx: number; cy: number }) => {
      iron.style.transform = `translate(${p.cx}px, ${p.cy}px)`;
    };

    const onDown = (e: PointerEvent) => {
      board.setPointerCapture(e.pointerId);
      board.classList.add("is-active");
      last = local(e);
      moveIron(last);
      stamp(last.x, last.y);
      render();
    };
    const onMove = (e: PointerEvent) => {
      const p = local(e);
      moveIron(p);
      if (e.pointerType === "mouse" && !e.buttons) {
        if (last) line(last, p);
        last = p;
        return;
      }
      if (last) line(last, p);
      last = p;
    };
    const onUp = (e: PointerEvent) => {
      last = null;
      if (e.pointerType !== "mouse") board.classList.remove("is-active");
      check();
    };
    const onEnter = () => board.classList.add("is-active");
    const onLeave = () => {
      board.classList.remove("is-active");
      last = null;
    };

    autoRef.current = () => {
      const w = canvas.width;
      const h = canvas.height;
      const rows = 7;
      const pts: number[][] = [];
      for (let r = 0; r < rows; r++) {
        const y = h * (0.08 + (r * 0.84) / (rows - 1));
        pts.push(r % 2 ? [w * 0.95, y, w * 0.05, y] : [w * 0.05, y, w * 0.95, y]);
      }
      const finish = () => {
        finished = true;
        setDone(true);
      };
      if (reduce) {
        pts.forEach((q) => line({ x: q[0], y: q[1] }, { x: q[2], y: q[3] }));
        finish();
        return;
      }
      let i = 0;
      const step = () => {
        if (i >= pts.length) return finish();
        const q = pts[i++];
        const t0 = performance.now();
        let prev = { x: q[0], y: q[1] };
        const seg = (now: number) => {
          const k = Math.min(1, (now - t0) / 240);
          const cur = { x: q[0] + (q[2] - q[0]) * k, y: q[1] + (q[3] - q[1]) * k };
          line(prev, cur);
          prev = cur;
          if (k < 1) requestAnimationFrame(seg);
          else step();
        };
        requestAnimationFrame(seg);
      };
      step();
    };

    board.addEventListener("pointerdown", onDown);
    board.addEventListener("pointermove", onMove);
    board.addEventListener("pointerup", onUp);
    board.addEventListener("pointerenter", onEnter);
    board.addEventListener("pointerleave", onLeave);
    img.onload = () => {
      size();
      render();
    };
    const ro = new ResizeObserver(size);
    ro.observe(board);
    return () => {
      ro.disconnect();
      board.removeEventListener("pointerdown", onDown);
      board.removeEventListener("pointermove", onMove);
      board.removeEventListener("pointerup", onUp);
      board.removeEventListener("pointerenter", onEnter);
      board.removeEventListener("pointerleave", onLeave);
    };
  }, [pressed]);

  return (
    <div className="flex w-full flex-col items-center gap-4">
      <div
        ref={boardRef}
        role="img"
        aria-label={label}
        className={`press-board relative aspect-square w-full touch-none select-none overflow-hidden rounded-[1.75rem] shadow-2xl shadow-ink/25 ${done ? "is-done" : ""}`}
      >
        {/* eslint-disable-next-line @next/next/no-img-element -- static export; the creased photo is the base layer under the canvas */}
        <img src={creased} alt="" className="absolute inset-0 size-full object-cover" draggable={false} />
        <canvas ref={canvasRef} className="absolute inset-0 size-full" />
        <span ref={ironRef} aria-hidden className="press-iron" />
        <span aria-hidden className="press-done">Pressed.</span>
      </div>
      <button
        type="button"
        onClick={() => autoRef.current()}
        className="rounded-full border-2 border-ink bg-white/80 px-5 py-2.5 font-semibold text-ink backdrop-blur hover:bg-ink hover:text-white"
      >
        {done ? "Pressed. Like we do it." : "Press it for me"}
      </button>
    </div>
  );
}
