"use client";

import { useSyncExternalStore } from "react";
import { playStoreUrl } from "@/lib/install-links";
import { StoreButtons } from "./store-buttons";

/** Nothing to subscribe to: the user agent and URL do not change while the page is open. */
const subscribe = () => () => {};

function platform(): "ios" | "android" | "other" {
  const ua = navigator.userAgent;
  if (/android/i.test(ua)) return "android";
  // iPadOS reports itself as a Mac; touch support gives it away.
  if (/iphone|ipad|ipod/i.test(ua) || (/macintosh/i.test(ua) && navigator.maxTouchPoints > 1)) return "ios";
  return "other";
}

/** Reads one client-only value; the static HTML gets `fallback`, so the first paint never waits for JavaScript. */
export function useClientValue<T extends string>(read: () => T, fallback: T): T {
  return useSyncExternalStore(subscribe, read, () => fallback);
}

/**
 * Store buttons that put the visitor's own store first and pass ?src= and ?c= (or the given values) to Google Play as an
 * install referrer. Before JavaScript runs, Google Play comes first: most visitors are on Android.
 */
export function SmartStoreButtons({ onDark = false, src, campaign }: { onDark?: boolean; src?: string; campaign?: string }) {
  const os = useClientValue(platform, "other");
  const search = useClientValue(() => window.location.search, "");
  const q = new URLSearchParams(search);
  const playUrl = playStoreUrl(src ?? q.get("src") ?? undefined, campaign ?? q.get("c") ?? undefined);
  return <StoreButtons onDark={onDark} playUrl={playUrl} appleFirst={os === "ios"} />;
}
