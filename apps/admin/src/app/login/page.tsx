"use client";

import { Loader2, ShieldAlert } from "lucide-react";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { BrandWordmark } from "@/components/brand";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useAuth } from "@/lib/auth/auth-provider";

const MOBILE = /^[6-9]\d{9}$/;

function LoginForm() {
  const { state, firebaseEnabled, devAuthEnabled, sendOtp, verifyOtp, devSignIn } = useAuth();
  const router = useRouter();
  const next = useSearchParams().get("next") ?? "/";
  const [mobile, setMobile] = useState("");
  const [code, setCode] = useState("");
  const [step, setStep] = useState<"phone" | "code">("phone");
  const [busy, setBusy] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  useEffect(() => {
    if (state.status === "signedIn") router.replace(next.startsWith("/") ? next : "/");
  }, [state, next, router]);

  const error = localError ?? (state.status === "signedOut" ? state.error : undefined);
  const validMobile = MOBILE.test(mobile);

  async function onSendCode(e: React.FormEvent) {
    e.preventDefault();
    if (!validMobile) return setLocalError("Enter a 10-digit mobile number starting with 6–9.");
    setBusy(true);
    setLocalError(null);
    try {
      await sendOtp(mobile);
      setStep("code");
    } catch (err) {
      setLocalError(err instanceof Error ? err.message : "Could not send the code. Try again.");
    } finally {
      setBusy(false);
    }
  }

  async function onVerify(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setLocalError(null);
    await verifyOtp(code);
    setBusy(false);
  }

  async function onDevSignIn() {
    if (!validMobile) return setLocalError("Enter a 10-digit mobile number starting with 6–9.");
    setLocalError(null);
    await devSignIn(mobile);
  }

  const signingIn = state.status === "loading" && (busy || step === "code");

  return (
    <div className="flex w-full max-w-sm flex-col gap-6">
      <div className="lg:hidden">
        <BrandWordmark subtitle="Admin" />
      </div>
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Sign in</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          {step === "phone" ? "Use the mobile number your account was set up with." : `Enter the 6-digit code sent to +91 ${mobile}.`}
        </p>
      </div>

      {error ? (
        <Alert variant="destructive">
          <ShieldAlert />
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      ) : null}

      {step === "phone" ? (
        <form onSubmit={onSendCode} className="flex flex-col gap-4">
          <div className="grid gap-2">
            <Label htmlFor="mobile">Mobile number</Label>
            <div className="flex">
              <span className="inline-flex items-center rounded-l-md border border-r-0 bg-muted px-3 text-sm text-muted-foreground">+91</span>
              <Input
                id="mobile"
                inputMode="numeric"
                autoComplete="tel-national"
                placeholder="98765 43210"
                className="rounded-l-none"
                value={mobile}
                onChange={(e) => setMobile(e.target.value.replace(/\D/g, "").slice(0, 10))}
                autoFocus
              />
            </div>
          </div>
          {firebaseEnabled ? (
            <Button type="submit" disabled={busy || !validMobile}>
              {busy ? <Loader2 className="animate-spin" /> : null}
              Send code
            </Button>
          ) : null}
          {devAuthEnabled ? (
            <div className="grid gap-2 rounded-lg border border-dashed border-brand/60 bg-brand/5 p-3">
              <p className="text-xs text-muted-foreground">
                Development sign-in skips the SMS code. It only works against a local API with dev tokens enabled.
              </p>
              <Button type="button" variant="outline" onClick={onDevSignIn} disabled={!validMobile || state.status === "loading"}>
                {state.status === "loading" ? <Loader2 className="animate-spin" /> : null}
                Sign in without code
              </Button>
            </div>
          ) : null}
          {!firebaseEnabled && !devAuthEnabled ? (
            <p className="text-sm text-destructive">Sign-in is not configured. Set the NEXT_PUBLIC_FIREBASE_* variables.</p>
          ) : null}
        </form>
      ) : (
        <form onSubmit={onVerify} className="flex flex-col gap-4">
          <div className="grid gap-2">
            <Label htmlFor="code">Verification code</Label>
            <Input
              id="code"
              inputMode="numeric"
              autoComplete="one-time-code"
              className="tabular text-center text-lg tracking-[0.5em]"
              value={code}
              onChange={(e) => setCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
              autoFocus
            />
          </div>
          <Button type="submit" disabled={code.length !== 6 || signingIn}>
            {signingIn ? <Loader2 className="animate-spin" /> : null}
            Verify and sign in
          </Button>
          <Button
            type="button"
            variant="ghost"
            onClick={() => {
              setStep("phone");
              setCode("");
            }}
          >
            Use a different number
          </Button>
        </form>
      )}
      <div id="recaptcha-container" />
    </div>
  );
}

export default function LoginPage() {
  return (
    <main className="grid min-h-screen lg:grid-cols-[minmax(0,5fr)_minmax(0,6fr)]">
      <section className="relative hidden flex-col justify-between overflow-hidden bg-sidebar p-10 text-sidebar-foreground lg:flex">
        <BrandWordmark subtitle="Admin" inverse className="text-sidebar-accent-foreground" />
        <div className="relative z-10 max-w-md">
          <p className="text-3xl font-semibold leading-tight tracking-tight text-sidebar-accent-foreground">
            Every pickup, press and delivery, in one place.
          </p>
          <p className="mt-3 text-sm text-sidebar-foreground/70">
            Orders, partners, prices and payments for the IronDost team.
          </p>
        </div>
        <p className="text-xs text-sidebar-foreground/50">Staff access only. Activity is logged.</p>
        {/* Pressed-fabric creases */}
        <div aria-hidden className="pointer-events-none absolute -right-24 top-1/3 h-[140%] w-80 -rotate-12 bg-[repeating-linear-gradient(90deg,transparent_0_22px,oklch(1_0_0/0.04)_22px_23px)]" />
      </section>
      <section className="flex items-center justify-center p-6">
        <Suspense>
          <LoginForm />
        </Suspense>
      </section>
    </main>
  );
}
