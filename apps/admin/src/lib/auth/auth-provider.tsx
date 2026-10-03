"use client";

import { useQueryClient } from "@tanstack/react-query";
import {
  onAuthStateChanged,
  RecaptchaVerifier,
  signInWithPhoneNumber,
  signOut as firebaseSignOut,
  type ConfirmationResult,
} from "firebase/auth";
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import { api, ApiError, setTokenProvider, unwrap } from "@/lib/api/client";
import type { User } from "@/lib/api/types";
import { devAuthEnabled, firebaseAuth, firebaseEnabled } from "./firebase";

type AuthState =
  | { status: "loading" }
  | { status: "signedOut"; error?: string }
  | { status: "signedIn"; user: User };

interface AuthContextValue {
  state: AuthState;
  user: User | null;
  isSuperAdmin: boolean;
  firebaseEnabled: boolean;
  devAuthEnabled: boolean;
  /** Sends an OTP to a 10-digit Indian mobile number. */
  sendOtp: (mobile: string) => Promise<void>;
  verifyOtp: (code: string) => Promise<void>;
  devSignIn: (mobile: string) => Promise<void>;
  signOut: () => Promise<void>;
  /** Re-reads the signed-in admin (after they edit their own staff record). */
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);
const DEV_KEY = "irondost.admin.devPhone";

const SESSION_ERRORS: Record<string, string> = {
  NOT_REGISTERED: "This number is not registered as an admin. Ask a super admin to add you.",
  WRONG_APP: "This number belongs to a customer or partner account, not an admin.",
  ACCOUNT_DISABLED: "This admin account has been disabled.",
};

function readDevPhone(): string | null {
  try {
    return devAuthEnabled ? window.localStorage.getItem(DEV_KEY) : null;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AuthState>({ status: "loading" });
  const confirmation = useRef<ConfirmationResult | null>(null);
  const verifier = useRef<RecaptchaVerifier | null>(null);
  const queryClient = useQueryClient();

  /** Registers this admin with the API. Resolves to the resulting auth state; never throws. */
  const openSession = useCallback(async (): Promise<AuthState> => {
    try {
      const user = await unwrap(api.POST("/v1/auth/session", { body: { app: "ADMIN" } }));
      return { status: "signedIn", user };
    } catch (err) {
      const code = err instanceof ApiError ? err.code : "";
      try {
        window.localStorage.removeItem(DEV_KEY);
      } catch {}
      const auth = firebaseAuth();
      if (auth?.currentUser) await firebaseSignOut(auth);
      setTokenProvider(async () => null);
      return {
        status: "signedOut",
        error: SESSION_ERRORS[code] ?? (err instanceof Error ? err.message : "Sign-in failed"),
      };
    }
  }, []);

  // Restore a session on load: a saved dev sign-in, or Firebase's persisted user.
  useEffect(() => {
    let active = true;
    const apply = (next: AuthState) => {
      if (active) setState(next);
    };
    const devPhone = readDevPhone();
    const auth = firebaseAuth();
    let unsubscribe: (() => void) | undefined;

    if (devPhone) {
      setTokenProvider(async () => `dev:${devPhone}`);
      void openSession().then(apply);
    } else if (auth) {
      unsubscribe = onAuthStateChanged(auth, (fbUser) => {
        if (!fbUser) {
          setTokenProvider(async () => null);
          setState((s) => (s.status === "signedOut" ? s : { status: "signedOut" }));
          return;
        }
        setTokenProvider(() => fbUser.getIdToken());
        void openSession().then(apply);
      });
    } else {
      void Promise.resolve<AuthState>({ status: "signedOut" }).then(apply);
    }
    return () => {
      active = false;
      unsubscribe?.();
    };
  }, [openSession]);

  const signOut = useCallback(async () => {
    try {
      window.localStorage.removeItem(DEV_KEY);
    } catch {}
    const auth = firebaseAuth();
    if (auth?.currentUser) await firebaseSignOut(auth);
    setTokenProvider(async () => null);
    queryClient.clear();
    setState({ status: "signedOut" });
  }, [queryClient]);

  // An expired or revoked session anywhere in the app sends the admin back to sign-in.
  useEffect(() => {
    return queryClient.getQueryCache().subscribe((event) => {
      const err = event.query.state.error;
      if (event.type === "updated" && err instanceof ApiError && err.status === 401) void signOut();
    });
  }, [queryClient, signOut]);

  const sendOtp = useCallback(async (mobile: string) => {
    const auth = firebaseAuth();
    if (!auth) throw new Error("Phone sign-in is not configured");
    verifier.current ??= new RecaptchaVerifier(auth, "recaptcha-container", { size: "invisible" });
    confirmation.current = await signInWithPhoneNumber(auth, `+91${mobile}`, verifier.current);
  }, []);

  const verifyOtp = useCallback(async (code: string) => {
    if (!confirmation.current) throw new Error("Request a new code first");
    setState({ status: "loading" });
    try {
      await confirmation.current.confirm(code);
      // onAuthStateChanged takes it from here and starts the API session.
    } catch {
      setState({ status: "signedOut", error: "That code is not right or has expired. Try again." });
    }
  }, []);

  const devSignIn = useCallback(
    async (mobile: string) => {
      if (!devAuthEnabled) throw new Error("Dev sign-in is disabled");
      try {
        window.localStorage.setItem(DEV_KEY, mobile);
      } catch {}
      setTokenProvider(async () => `dev:${mobile}`);
      setState({ status: "loading" });
      setState(await openSession());
    },
    [openSession],
  );

  const refreshUser = useCallback(async () => {
    const user = await unwrap(api.GET("/v1/me"));
    setState({ status: "signedIn", user });
  }, []);

  const value = useMemo<AuthContextValue>(() => {
    const user = state.status === "signedIn" ? state.user : null;
    return {
      state,
      user,
      isSuperAdmin: user?.role === "SUPER_ADMIN",
      firebaseEnabled,
      devAuthEnabled,
      sendOtp,
      verifyOtp,
      devSignIn,
      signOut,
      refreshUser,
    };
  }, [state, sendOtp, verifyOtp, devSignIn, signOut, refreshUser]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used inside AuthProvider");
  return ctx;
}
