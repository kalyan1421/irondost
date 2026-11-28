# Deep links, campaign links and install attribution (customer app 2.1.0)

Links to `irondost.in` open the IronDost customer app when it is installed (Android App Links, iOS Universal Links) and
fall back to the website when it is not. The website serves the verification files; the app declares the domains.

## Identifiers

| What | Value |
| --- | --- |
| Android package name (`applicationId`) | `com.irondost.customer` |
| iOS bundle id | `com.irondost.customer` |
| Apple team id | `AQLMTLP6PD` |
| iOS app id for the AASA file | `AQLMTLP6PD.com.irondost.customer` |
| Domains | `irondost.in`, `www.irondost.in` |

## Paths the app opens

| Link | Opens | Also |
| --- | --- | --- |
| `/get?src=<src>&c=<campaign>` | Home | Records `src` and `c` as Firebase Analytics user properties |
| `/offers` | Offers | |
| `/o/<orderId>` | That order's detail | |
| `/r/<code>` | Home | Stores the referral code on the phone (`referralCodeProvider`) for checkout to send once the API accepts one |

Only these four are declared to Android and listed in the AASA file, so every other page (blog, prices…) stays in the
browser. Inside the app, campaign pushes and inbox rows can also link to `/orders/<id>`, `/catalogue`, `/basket`,
`/notifications`, `/help`, `/account` and any `https://` page (opened in the browser). The mapping lives in
`apps/customer/lib/app/links.dart` (`resolveLink`, `appLinkFor`) and the link-only paths are routes in
`apps/customer/lib/app/router.dart` (`Routes.linkRoutes`).

### How links reach the app

Flutter's built-in deep linking stays **off** on both platforms (`FlutterDeepLinkingEnabled` = false in `Info.plist`,
`flutter_deeplinking_enabled` = false in `AndroidManifest.xml`). With it on, the Firebase phone-number callback URL is
handed to the router and sign-in breaks. Instead `app_links` delivers incoming URLs to `deepLinkListenerProvider`, which
ignores every host except `irondost.in`. A link that arrives before sign-in (or before startup finishes) waits in
`pendingLinkProvider` and is opened as soon as the tabs are on screen.

## Verification files (served by the website session)

### Android: `https://irondost.in/.well-known/assetlinks.json`

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.irondost.customer",
    "sha256_cert_fingerprints": ["TODO_OWNER_PLAY_APP_SIGNING_SHA256"]
  }
}]
```

> **TODO (owner):** open Play Console → IronDost → Test and release → **App integrity → App signing**, copy the
> **App signing key certificate → SHA-256 certificate fingerprint** (`AB:CD:…`), and put it in place of the placeholder
> in `apps/web` (the website currently has `REPLACE_ME_PLAY_CONSOLE_APP_SIGNING_SHA256`). Use the *app signing* key,
> not the upload key: Play re-signs the app, so only that fingerprint matches installed copies. For local debug builds
> you can add the debug keystore's SHA-256 as a second entry (`keytool -list -v -keystore ~/.android/debug.keystore`).
> Serve it directly on `www.irondost.in` too: Android does not follow redirects for this file.

Check after deploy:

```bash
curl -s https://irondost.in/.well-known/assetlinks.json
adb shell pm verify-app-links --re-verify com.irondost.customer
adb shell pm get-app-links com.irondost.customer
```

### iOS: `https://irondost.in/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "details": [{
      "appIDs": ["AQLMTLP6PD.com.irondost.customer"],
      "components": [
        { "/": "/get" },
        { "/": "/offers" },
        { "/": "/o/*" },
        { "/": "/r/*" }
      ]
    }]
  }
}
```

Served as `application/json`, no redirect, on both hosts.

> **TODO (owner):** in the Apple Developer portal → Identifiers → `com.irondost.customer`, turn on **Associated
> Domains**, then let Xcode regenerate the provisioning profiles (or re-download them in CI). The entitlement is already
> in `ios/Runner/Runner.entitlements`; a profile without the capability fails to sign.

## Install attribution (Android)

`irondost.in/get` sends people without the app to Google Play with a referrer. On first launch the app reads the Play
install referrer once (`play_install_referrer`) and sets user properties:

* `src` ← `src` or `utm_source`
* `c` ← `c` or `utm_campaign`
* when `utm_source=ref`, `utm_campaign` is also stored as the referral code.

The website currently builds `referrer=utm_source=<src>&utm_medium=<get_page|website>&utm_campaign=<c>`
(URL-encoded). iOS has no install referrer; there `src`/`c` are recorded only when a `/get` link opens the installed app.

To see them in Firebase: Analytics → Custom definitions → **Create custom dimension**, scope *User*, user property
`src`, and again for `c`. Until registered they are collected but not shown in reports.

## Analytics funnel

`app_open`, `address_saved`, `basket_started`, `slot_picked`, `order_placed`, `order_delivered`, `second_order`
(`apps/customer/lib/features/analytics/analytics.dart`, names in `Funnel`). `order_delivered` fires the first time
the app sees an order delivered (orders already delivered when 2.1.0 is installed are not replayed). `second_order`
fires with `order_placed` when the customer had exactly one earlier order. Mark `order_placed` as a key event in
Firebase → Analytics → Events.

## Rich push (campaigns)

Admin campaign pushes carry FCM `data = { type: 'campaign', campaignId, link, imageUrl }` plus a notification image
(Android `notification.imageUrl`, iOS `fcm_options.image` with `mutable-content: 1`). The inbox row's `data` JSON has the
same `link` and `imageUrl`. Tapping either opens `link` (an in-app path or an `https://` page); the inbox shows the image.

Android shows the image in the system notification with no app code. **iOS needs a Notification Service Extension**
to download and attach the image; until it is added, iOS shows the text only. It is left as a follow-up because it means
a new Xcode target, its own bundle id (`com.irondost.customer.NotificationService`), App ID and provisioning profile,
which have to be created in Xcode and the developer portal by the owner:

1. Xcode → File → New → Target → *Notification Service Extension*, name `NotificationService`, embed in Runner, deployment
   target equal to Runner's.
2. In `ios/Podfile` add:
   ```ruby
   target 'NotificationService' do
     use_frameworks!
     pod 'Firebase/Messaging'
   end
   ```
3. Replace the body of `didReceive(_:withContentHandler:)` with
   `Messaging.serviceExtension().populateNotificationContent(bestAttemptContent!, withContentHandler: contentHandler)`.
4. Create the App ID and profiles for the extension, and add it to the iOS release workflow's signing.
