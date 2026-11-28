"use client";

import { Check, Copy } from "lucide-react";
import { useState } from "react";
import { SmartStoreButtons, useClientValue } from "./smart-store-buttons";

/**
 * /r/<code> and /o/<id> are App Links / Universal Links. With the app installed the phone opens the app; everyone else lands on
 * the one static page per prefix (firebase.json rewrites /r/** to /r.html), so the code is read from the address bar here.
 */
function segment(prefix: "r" | "o"): string {
  const fromPath = window.location.pathname.split("/").filter(Boolean);
  const raw = fromPath[0] === prefix && fromPath[1] ? fromPath[1] : new URLSearchParams(window.location.search).get("code") ?? "";
  let value = raw;
  try {
    value = decodeURIComponent(raw);
  } catch {
    // A broken %-escape: keep the raw text, the filter below drops anything unsafe.
  }
  return /^[A-Za-z0-9_-]{1,40}$/.test(value) ? value : "";
}

export function ReferralFallback() {
  const code = useClientValue(() => segment("r").toUpperCase(), "");
  const [copied, setCopied] = useState(false);
  return (
    <>
      {code ? (
        <div className="mt-6 rounded-3xl bg-mist p-6">
          <p className="text-muted">Your friend&apos;s referral code</p>
          <div className="mt-2 flex flex-wrap items-center gap-3">
            <span className="rounded-xl bg-white px-4 py-2 font-mono text-2xl font-bold tracking-widest ring-1 ring-ring">{code}</span>
            <button
              type="button"
              onClick={() => {
                navigator.clipboard?.writeText(code).then(() => setCopied(true), () => setCopied(false));
              }}
              className="inline-flex min-h-11 items-center gap-2 rounded-xl border border-ring bg-white px-4 font-semibold hover:border-royal hover:text-royal"
            >
              {copied ? <Check aria-hidden className="size-4" /> : <Copy aria-hidden className="size-4" />}
              {copied ? "Copied" : "Copy code"}
            </button>
          </div>
          <p className="mt-3 leading-relaxed">Install the app, then enter this code at checkout on your first order.</p>
        </div>
      ) : (
        <p className="mt-6 text-lg leading-relaxed">Install the app, then enter your friend&apos;s referral code at checkout on your first order.</p>
      )}
      <div className="mt-8">
        <SmartStoreButtons src="ref" campaign={code.toLowerCase() || undefined} />
      </div>
    </>
  );
}

export function OrderFallback() {
  const id = useClientValue(() => segment("o"), "");
  return (
    <>
      <p className="mt-4 text-lg leading-relaxed">
        This link opens {id ? <>order <span className="font-mono font-semibold">{id.slice(0, 12)}</span></> : "your order"} in the IronDost
        app. Open it on the phone you booked with. If the app isn&apos;t installed there, get it below and sign in the way you did when
        you booked: your order is under Orders.
      </p>
      <div className="mt-8">
        <SmartStoreButtons src="order" />
      </div>
    </>
  );
}
