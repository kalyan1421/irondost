import { getApps, initializeApp, type FirebaseApp } from "firebase/app";
import { getAuth, type Auth } from "firebase/auth";

const config = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

/** Firebase is only used for phone-OTP sign-in. */
export const firebaseEnabled = Boolean(config.apiKey && config.authDomain && config.projectId);

/** Local development without Firebase: sign in as any registered admin phone. Never enable in production. */
export const devAuthEnabled = process.env.NEXT_PUBLIC_AUTH_DEV_BYPASS === "true";

let app: FirebaseApp | null = null;

export function firebaseAuth(): Auth | null {
  if (!firebaseEnabled || typeof window === "undefined") return null;
  app ??= getApps()[0] ?? initializeApp(config);
  const auth = getAuth(app);
  auth.languageCode = "en";
  return auth;
}
