# Store release flow: iOS (build uploaded) and Google Play (listing drafted, bundle built, not uploaded)

Status as of 6 Oct 2026. The listing copy, privacy answers and graphics are in
[`customer-app-release.md`](customer-app-release.md) and [`store-submission-assets.md`](store-submission-assets.md); this page is the
order of operations and where each store stands.

## iOS first: build 101 (2 Nov 2026)

Build 101 (2.0.0) replaces build 100. What changed for the iPhone, and what only the owner can do.

**Build 100 was rejected on 22 Oct 2026** (App Review, Guideline 2.1(a), App Completeness): "an error message after app launch", reviewed on an
iPad Air 11-inch, iPadOS 27, connection active. The launch calls had a 10 s connect and 20 s read limit, and the free Render API takes about a minute
to wake, so the first open showed "We'll be right back". Build 101 retries a slow or waking API (`lib/data/wake_retry.dart`) and shows
"Getting things ready" instead. The real fix is hosting that stays awake: move the API to a paid Render plan. Build 101 was uploaded on 2 Nov 2026 and Apple
then flagged a missing `NSLocationAlwaysAndWhenInUseUsageDescription` (ITMS-90683; the location plugin references the always-on API), so build 102 adds
it. **Build 102 was attached to version 2.0.0, a reply was sent to App Review, and the submission was resubmitted on 3 Nov 2026 (Waiting for Review).**

Changed in the app and API:

- **No "Continue with Google" on iPhone.** Apple's rule 4.8 asks for Sign in with Apple next to any social sign-in. iOS signs in with a mobile number
  only until Sign in with Apple is built (entitlement, Firebase Apple provider, `apple.com` handling in the API token verifier). Android keeps Google.
- A release build now refuses to start if it was built without the production settings (dev flavor, dev sign-in, or a non-https API address).
- Setup screens (name, first pickup address) have a "Use a different account" button, so nobody is stuck on the wrong account.
- The Name screen shows the email a Google customer already has, so saving a blank field no longer erases it.
- Privacy policy and terms (`packages/legal`) now describe Google sign-in on Android and the Google account name and email it shares;
  the delete-account page accepts a Google email. Deploy `apps/web` for the website copy to go live (the in-app copy ships with the build).
- API: `TRUST_PROXY_HOPS=1` (in `render.yaml`) makes the rate limiter count each caller, not Render's load balancer, as one address.
  **Redeploy the API on Render** (`autoDeploy` is off) for this to take effect.

Only the owner can do these before pressing "Add for Review":

1. **Firebase test phone number** (Authentication, Sign-in method, Phone, "Phone numbers for testing") with a fixed code, and put both in App Store
   Connect, App Review Information, Sign-in required. Reviewers cannot use a real SMS.
2. **APNs key** (.p8) uploaded in Firebase, Project settings, Cloud Messaging, so push arrives.
3. **Razorpay live keys** in Render, plus the webhook and `RAZORPAY_WEBHOOK_SECRET`; a small live payment, then refund it.
4. **Render and Supabase off the free plans** (the API sleeps and times out the app's first call; free Supabase has no backups).
5. **Privacy answers in App Store Connect:** Email Address is now collected for Android Google users; the store text should match the updated policy.
6. **Screenshots** in App Store Connect still show the pre-November design.
7. A TestFlight run on a physical iPhone: sign in with the test number, add an address, cash order, pay online, track, cancel, delete account.

## Google Play: what the console actually shows (3 Nov 2026)

This corrects the older text below, which says nothing was uploaded.

- The Play developer account is **"kalyan kumar b"** (an organization account), opened with `cloudironingfactory@gmail.com`. The app
  `com.irondost.customer` is **live in production**: release **2.0.0 (100)**, 100% rollout, India, 3 installs. Build 100 has no Google sign-in.
- **Play App Signing fingerprints**, added on 3 Nov 2026 to the Firebase Android app `1:264618787416:android:ad3c715399093417c7c02d`
  (`firebase apps:android:sha:create` equivalent): SHA-1 `BB:68:65:75:43:B4:84:E2:BD:23:6B:F3:64:EF:C6:33:31:43:8D:59`, SHA-256
  `98:D6:0D:20:6C:BC:43:56:64:5D:75:F1:DF:DA:A7:47:BE:83:E9:90:26:F5:F3:5B:EE:46:EE:4E:06:79:7B:F3`. Firebase then created the Android OAuth
  client for it, and `android/app/google-services.json` was refreshed. Google sign-in on a Play-installed build needs this.
- **Maps key** ("IronDost Maps Android", project `irondost-app`): it only allowed the old package, so maps were blank in the live app. Rows added
  for `com.irondost.customer` with the Play signing SHA-1 and the upload-key SHA-1. Allow up to 5 minutes to take effect.
- The Firebase MCP's default project was `aura-akvega`; always set the active project to `irondost-app` before changing anything.
- **Release 2.0.0 (102)** was uploaded to the production track and sent for review on 3 Nov 2026 ("Start full rollout", Managed publishing off,
  so it goes live by itself once Google approves). Release notes: waits for the servers on open, Google sign-in. It went straight to production,
  not through Internal testing; check phone sign-in, Google sign-in, maps and an order on a real Android phone as soon as it is live.
- Play still shows "4 recommended actions" for build 100 (edge-to-edge, large-screen orientation lock, deprecated APIs, bitmap downsampling).
  None block a release.

## Where each store stands

| Step | App Store | Google Play |
|---|---|---|
| Developer account | Working (`kalyan91333@gmail.com`) | Developer account "akvega" (organization), signed in as `cloudironingfactory@gmail.com` in the kalyan Chrome profile. The other Play account on `kalyan91333@gmail.com` was removed in 2023 and is not used. |
| App record | Exists: IronDost: Laundry & Ironing, `com.irondost.customer` | Created 6 Oct 2026: IronDost: Laundry & Ironing, package `com.irondost.customer` (permanent), Free, English (US). Status: Draft. |
| Signing | Automatic, team `AQLMTLP6PD` | Upload keystore created 6 Oct 2026 at `~/irondost-upload.jks` (alias `upload`); its passwords are only in the gitignored `apps/customer/android/key.properties`. Release builds are signed with it. **Back up both files.** |
| Build | Build 100 (2.0.0) uploaded and processed | `app-release.aab` built (68.9 MB, `com.irondost.customer`, version 2.0.0+100, upload-signed). Not uploaded yet. |
| Listing | Filled and saved as a draft; not submitted | Default listing saved as a draft (name, short and full description, icon, feature graphic, 5 screenshots). Category Lifestyle and public contact details saved. |
| Privacy answers | Published (14 data types) | All 10 App content declarations are actioned (privacy policy, ads, advertising ID, government, financial, health, sign in details, content ratings, target audience, Data safety). Saved as drafts in Publishing overview, not sent for review. |

Nothing has been sent for review on either store.

## iOS: what was run

```bash
cd apps/customer
flutter build ipa --release --dart-define-from-file=env/prod.json
xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist <ExportOptions.plist with destination = upload> -allowProvisioningUpdates
```

`ExportOptions.plist` is the one Flutter writes to `build/ios/ipa/`, with `destination` changed from `export` to `upload`. The upload uses the Apple
account signed in to Xcode, so no password or API key is handled. Then, in App Store Connect: Distribution, version 2.0.0, Add Build, Save.
Submission ("Add for Review") is a separate step that the owner takes.

Still open on iOS: EU Digital Services Act trader details (account level), the APNs key upload in Firebase (for push), and the "Add for Review" click.

## Google Play: the same flow, in order

1. **Account.** Done: developer account "akvega" (organization), signed in as `cloudironingfactory@gmail.com`. The IronDost app was created in it on 6 Oct 2026.
2. **Upload key.** Done: see the status table and the section below.
3. **Android project and Firebase.** Done: see the next section.
4. **Build.** `cd apps/customer && flutter build appbundle --release --dart-define-from-file=env/prod.json`. Raise the `+100` in `pubspec.yaml` if the console already holds a higher version code.
5. **Listing.** Saved as a draft (Grow users, Store presence, Store listings, default listing):

   | Field | Value | Limit |
   |---|---|---|
   | App name | IronDost: Laundry & Ironing | 30 (27) |
   | Short description | Book ironing, wash and dry cleaning. We pick up and deliver to your door. | 80 (73) |
   | Full description | The text in `customer-app-release.md`, section 5 | 4000 (597) |
   | Category | Lifestyle | |
   | Icon | `apps/customer/store/google-play/icon-512.png` | 512 x 512 |
   | Feature graphic | `apps/customer/store/google-play/feature-graphic.png` | 1024 x 500 |
   | Phone screenshots | the five PNGs in `apps/customer/store/google-play/screenshots/`, in order | 1080 x 1920 |
   | Privacy policy | https://irondost-app.web.app/privacy | |
   | Account deletion page | https://irondost-app.web.app/delete-account | |
   | Contact | the support email, phone and website from https://irondost-app.web.app/support | |

6. **App content.** All 10 declarations are actioned (see the status table and the Data safety section below). The business confirms them before the app goes to review.
7. **Test track first.** Testing, Internal testing, create a release, upload the `.aab`, add testers by email, and test sign-in, a cash order, tracking and a real push on a physical phone before any production release.
8. **Production.** Send for review only after the checklist in `customer-app-release.md`, section 9, is done.

## Play: Android project moved to `com.irondost.customer`

Done on 6 Oct 2026, so the Android build matches the new Play app:

- `android/app/build.gradle.kts`: `applicationId` is now `com.irondost.customer` (the `namespace`, `com.irondost.irondost_customer`, is unchanged).
- Firebase project `irondost-app`: a new Android app "IronDost (Android)" for `com.irondost.customer`, app ID `1:264618787416:android:ad3c715399093417c7c02d`. The old app (`com.cloudironingfactory.customer`) is still there and untouched. The debug key's SHA-1 and SHA-256 are registered on the new app.
- `android/app/google-services.json`: now holds a client for each package, so the Gradle plugin picks the one that matches the app ID. `lib/firebase_options.dart` points the Android options at the new app ID. Both Firebase apps share one project API key.
- Checked on a release build: `flutter build apk --release --dart-define-from-file=env/prod.json` produces package `com.irondost.customer`, the prod API address and the new Firebase app ID. It is still signed with the debug key.

Upload key (created 6 Oct 2026), certificate fingerprints:

- SHA-1: `AB:43:41:EE:A9:90:86:2A:53:F6:A3:6F:5C:9C:9A:85:AE:82:CD:2A`
- SHA-256: `34:D2:E1:5D:6E:0D:2D:4E:63:8E:62:6F:C6:97:9C:E5:DC:90:0E:0B:E8:07:92:AB:EB:CC:0D:FF:28:C5:05:5F`

Both are registered on the new Firebase Android app, together with the debug key's.

Build: `cd apps/customer && flutter build appbundle --release --dart-define-from-file=env/prod.json`, which writes `build/app/outputs/bundle/release/app-release.aab`. Check the signer with `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab`; it must say `CN=IronDost`, not `Android Debug`.

Still to do (these are in your Google Cloud and Play accounts):

1. **Maps key.** In Google Cloud, project `irondost-app`, APIs and services, Credentials, "IronDost Maps Android": under Android restrictions, Add a row with package `com.irondost.customer` and SHA-1 `92:EE:F9:D9:B3:10:84:04:1E:5B:8B:DA:49:C3:18:D3:32:0F:FD:6F` (the debug key, for sideloaded builds). The existing row only allows the old package, so map tiles will not load in the new app until this is added. Add the Play App Signing SHA-1 as another row once the first bundle is uploaded.
2. **Upload.** Play Console, IronDost, Testing, Internal testing, create a release, upload `app-release.aab`, and add testers by email. The first upload registers the upload key above with Play App Signing.
3. **Play App Signing key.** After the first upload, copy its SHA-1 and SHA-256 from Play Console, App integrity, and add both to the new Firebase Android app (`firebase apps:android:sha:create 1:264618787416:android:ad3c715399093417c7c02d <sha> --project irondost-app`) and the Maps key. Phone sign-in and maps on store builds need them.

The Firebase "Android key (auto created by Firebase)" has no application restriction (only an API list), so it does not block the new package.

## Play: what the Data safety form says

Filled on 6 Oct 2026 from the app's own code (`pubspec.yaml` has only `firebase_core`, `firebase_auth` and `firebase_messaging`), the AndroidManifest permissions, and `customer-app-release.md` section 6.

| Data type | Collected | Shared | Required or optional | Purpose |
|---|---|---|---|---|
| Precise location | yes | no | optional (the address can be typed) | App functionality |
| Name | yes | no | required | App functionality |
| Email address | yes | no | optional | App functionality |
| User IDs | yes | no | required | App functionality |
| Address | yes | yes, with the delivery partner for that order | required | App functionality |
| Phone number | yes | no | required | App functionality |
| User payment info (Razorpay checkout) | yes | no | optional (cash on delivery) | App functionality |
| Purchase history | yes | no | required | App functionality |
| Device or other IDs (push token, Firebase installation ID) | yes | no | required | App functionality |

Nothing is marked as processed ephemerally. Encrypted in transit: yes. Account creation: username and other authentication (phone number and one-time code). Delete account page: https://irondost-app.web.app/delete-account. Data is not shared with Firebase or Razorpay in this form because they act as service providers for the app.

**Check this against iOS.** The published App Store answers list 14 types. The extra five (Product Interaction, Other Data Types, Performance Data, Other Diagnostic Data, Crash Data) are used "for Analytics", but the app has no analytics or crash-reporting package. If Razorpay's SDK collects device or diagnostic data, Play may need an "App info and performance" entry too. Decide what is accurate, then make the two stores agree.

The Address-sharing answer assumes the delivery partner counts as a third party; if partners are staff acting for IronDost, that row can be changed to not shared.
