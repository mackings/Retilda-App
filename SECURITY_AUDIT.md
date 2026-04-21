# Retilda App Security Audit

Date: 2026-04-21

Scope: Flutter client code in this repository. This was a static defensive review only. I did not attack the live API or verify backend authorization, rate limits, database rules, or payment-provider configuration.

## Executive Summary

The highest-risk issues are concentrated in authentication/session handling, payment webviews, admin/staff paths, and logging. The app stores bearer tokens and user/staff profiles in `SharedPreferences`, logs passwords/tokens/full API responses in several places, opens server-provided payment and bank authorization URLs in unrestricted webviews without host validation, and exposes privileged endpoint shapes from the client. Server-side authorization may still block abuse, but the client currently makes token theft, replay, phishing, and privilege probing easier than necessary.

## Critical Findings

### 1. Bearer Tokens And Sensitive Profiles Stored In `SharedPreferences`

Affected places:

- `lib/Views/Auth/Signin.dart:103` stores the full login response as `userData`.
- `lib/Views/Staff/api/staff_service.dart:40` stores `staffToken`.
- `lib/Views/Staff/api/staff_service.dart:45` stores `staffData`.
- Many services read those values directly, including `lib/Views/Wallet/Api/ApiService.dart:43`, `lib/Views/Admin/Api/service.dart:49`, `lib/Views/Invoices/api/invoice_service.dart:10`, and `lib/Views/Chat/api/chat_service.dart:10`.

Why this is vulnerable:

`SharedPreferences` is not secure secret storage. A rooted/jailbroken device, compromised backup, malware with local file access, debug tooling, or an injected test build can recover bearer tokens and replay them against the API. Because the token authorizes wallet, purchase, admin, invoice, staff, and chat actions, this is an account-takeover and privilege-abuse risk.

Fix:

- Move access/refresh tokens and staff tokens to `flutter_secure_storage` or native Keychain/Keystore-backed storage.
- Store the minimum needed profile data. Do not persist full login responses.
- Use short-lived access tokens plus refresh token rotation.
- Add server-side token revocation on logout/password reset/staff disable.
- Consider binding high-risk actions to recent auth or step-up verification.

### 2. Passwords, Tokens, User Records, Wallet Data, And API Responses Are Logged

Affected places:

- `lib/Views/Auth/Signin.dart:89` logs the login payload, including password.
- `lib/Views/Auth/Signup.dart:120` logs signup payload, including password.
- `lib/Views/Staff/api/staff_service.dart:97` logs staff login payload, including password.
- `lib/Views/Admin/Api/admin_staff_service.dart:75` logs create-staff payload, including password.
- `lib/Views/Products/Connect/views/connect.dart:129` logs the bearer token.
- `lib/Views/Merchant/upload.dart:44` logs the bearer token.
- `lib/Views/Auth/kyc.dart:43` and `lib/Views/Auth/kyc.dart:104` log the bearer token.
- `lib/Views/Home/homecategory.dart:43` and `lib/Views/Delivery/views/deliveryhome.dart:46` log bearer tokens.
- `lib/Views/Products/details.dart:538`, `lib/Views/Products/searchresults.dart:35`, `lib/Views/Products/Update/searchupdate.dart:42`, `lib/Views/Wallet/Purchasehistory.dart:91`, and `lib/Views/Wallet/transactions.dart:78` log full user data.
- API loggers print full response bodies in `lib/Views/Wallet/Api/ApiService.dart:35`, `lib/Views/Admin/Api/service.dart:38`, `lib/Views/Invoices/api/invoice_service.dart:57`, `lib/Views/Chat/api/chat_service.dart:43`, `lib/Views/Geo/api/geo_service.dart:43`, and related services.

Why this is vulnerable:

Logs can be collected through device logs, crash reporters, CI logs, customer support screenshots, compromised test devices, or debug builds. Logging credentials and auth responses creates a direct credential disclosure path.

Fix:

- Remove all credential, token, OTP, wallet, and full-response logging.
- Create a central logger that is disabled or sanitized in release builds.
- Redact fields named `password`, `token`, `Authorization`, `otp`, `accountNumber`, `wallet`, `email`, and payment URLs.
- Ensure `flutter build --release` is the distributed artifact and avoid debug/profile distribution.

### 3. Unrestricted Webviews Load Untrusted Server-Provided Payment And Bank URLs

Affected places:

- `lib/Views/Widgets/webview.dart:20` enables unrestricted JavaScript and loads any `widget.url`.
- `lib/Views/Invoices/views/invoice_pdf_screen.dart:38` enables unrestricted JavaScript and loads any `widget.url`.
- `lib/Views/Products/Connect/views/connect.dart:452` enables unrestricted JavaScript and loads any redirect URL.
- Payment/bank URLs are consumed from API responses in `lib/Views/Products/details.dart:372`, `lib/Views/Products/details.dart:942`, `lib/Views/Wallet/Api/ApiService.dart:204`, and `lib/Views/Products/Connect/views/connect.dart:179`.

Why this is vulnerable:

If the backend, network path, or a payment initialization response is compromised, the app will render arbitrary pages in a trusted in-app context. This can support payment phishing, credential collection, malicious redirects, and abuse of webview capabilities. The invoice PDF screen also attaches `Authorization` headers to `widget.url` without validating the destination.

Fix:

- Allowlist exact trusted hosts for payment, invoice, and bank authorization URLs before loading.
- Reject non-HTTPS URLs and unknown schemes.
- Disable unrestricted JavaScript unless required by a specific trusted payment provider.
- Use `NavigationDelegate` to block unexpected host changes and external redirects.
- Never attach bearer tokens to arbitrary webview URLs. Only attach them to the Retilda API host.
- Prefer external browser/custom tabs for third-party payment authorization where possible.

## High Findings

### 4. Privileged Admin/Staff Endpoints Are Reachable From Client Code And Often Fall Back To User Tokens

Affected places:

- `lib/Views/Admin/Api/admin_order_service.dart:18` uses `staffToken`, then falls back to a normal user token.
- `lib/Views/Staff/api/staff_service.dart:27` uses `staffToken`, then falls back to a normal user token.
- `lib/Views/Invoices/api/invoice_service.dart:18` uses `staffToken`, then falls back to a normal user token.
- Privileged actions include order status update at `lib/Views/Admin/Api/admin_order_service.dart:67`, delivery status update at `lib/Views/Admin/Api/admin_order_service.dart:93`, delivery completion at `lib/Views/Admin/Api/admin_order_service.dart:121`, invoice admin listing at `lib/Views/Invoices/api/invoice_service.dart:138`, invoice creation at `lib/Views/Invoices/api/invoice_service.dart:67`, staff creation at `lib/Views/Admin/Api/admin_staff_service.dart:52`, and geo state mutation at `lib/Views/Geo/api/geo_service.dart:97`.

Why this is vulnerable:

The client cannot enforce authorization. Any authenticated user can inspect the app, discover privileged routes, and replay requests manually. The fallback to user tokens is a red flag: if any backend route trusts token presence instead of role claims, normal users may be able to perform staff/admin operations.

Server-side verification required:

- Confirm every `/Api/admin/*`, `/Api/staff/*`, invoice admin, order mutation, delivery mutation, product mutation, and geo mutation route checks role claims server-side.
- Confirm role claims come from server-trusted token/session state, not from client-stored `userRole`, `staffRole`, or request bodies.
- Confirm object-level authorization on `purchaseId`, `userId`, `invoiceId`, `threadId`, and `productId`.

Fix:

- Remove user-token fallback from staff/admin client services.
- Split user, staff, and admin sessions by audience/scope.
- Enforce role/scope checks on every privileged backend route.
- Add backend audit logs for privileged writes.

### 5. Potential IDOR/BOLA Across User, Purchase, Invoice, Chat, And Product IDs

Affected places:

- `lib/Views/Admin/Api/service.dart:96` fetches purchases by `userId` query string.
- `lib/Views/Invoices/api/invoice_service.dart:244` fetches outstanding purchases by `userId`.
- `lib/Views/Invoices/api/invoice_service.dart:178` pays invoice by `invoiceId`.
- `lib/Views/Invoices/api/invoice_service.dart:200` constructs invoice PDF URLs by `invoiceId`.
- `lib/Views/Chat/api/chat_service.dart:147` fetches chat messages by `threadId`.
- `lib/Views/Chat/api/chat_service.dart:218` closes chat threads by `threadId`.
- `lib/Views/Staff/api/staff_service.dart:173` fetches staff messages by `threadId`.
- `lib/Views/OrderTracking/api/order_status_service.dart:53` fetches order status by `purchaseId`.
- `lib/Views/Admin/Api/admin_order_service.dart:121` completes delivery by `purchaseId`.
- `lib/Views/Products/Update/updatedetails.dart:88` updates product price by `product.id`.
- `lib/Views/Products/Update/updatedetails.dart:132` deletes product by `product.id`.

Why this is vulnerable:

The client sends direct object identifiers. If the backend only checks that a token is valid, an attacker can change IDs and read/update another user purchase, invoice, chat thread, product, or order status.

Server-side verification required:

- Verify ownership or role permission for every object ID.
- Use deny-by-default authorization middleware.
- Add tests for cross-user access attempts.
- Avoid exposing sequential or guessable IDs where possible.

### 6. Password Reset Flow Appears To Reset With OTP And New Password Only

Affected places:

- `lib/Views/Auth/resetpass.dart:48` requests reset by email.
- `lib/Views/Auth/resetpass.dart:96` resets with only `password` and `otp`.
- `lib/Views/Auth/resetpass.dart:81` and `lib/Views/Auth/resetpass.dart:130` display raw backend response bodies to the user.

Why this is vulnerable:

The client does not send the email/account identifier during reset, so the server must bind OTPs securely to an account and expiration window. If OTPs are global, weak, long-lived, reusable, or not rate-limited, an attacker can reset accounts by guessing or replaying OTPs. Showing raw backend responses can leak implementation details or account-existence signals.

Server-side verification required:

- OTP length, randomness, expiration, single-use semantics, and attempt limits.
- Per-account and per-IP rate limiting.
- Uniform responses that do not reveal whether an email exists.
- Password reset invalidates existing sessions and refresh tokens.

Fix:

- Send a reset transaction ID from the forgot-password step and require it for the reset step.
- Do not display raw response bodies.
- Enforce password strength client-side and server-side.

### 7. Product Upload And Update Accept Files And User-Controlled Product Fields

Affected places:

- `lib/Views/Merchant/upload.dart:170` picks arbitrary gallery images.
- `lib/Views/Merchant/upload.dart:211` uploads multipart files to `/Api/uploadproduct`.
- `lib/Views/Products/Update/alldetailsupdate.dart:118` updates product details and files.
- `lib/Views/Products/Update/updatedetails.dart:88` updates product price.
- `lib/Views/Products/Update/updatedetails.dart:132` deletes product.

Why this is vulnerable:

Client-side checks do not protect the server. A malicious user can bypass the UI and upload oversized files, unsupported content, malformed images, scriptable SVGs if accepted server-side, or update/delete products they do not own.

Server-side verification required:

- Role/ownership checks for product create/update/delete.
- File type sniffing, size limits, image re-encoding, malware scanning, and safe storage names.
- Validation for price, dimensions, category, stock, description, and brand.

## Medium Findings

### 8. Query Strings Are Built With Raw User Input

Affected places:

- `lib/Views/Products/Allproducts.dart:370`
- `lib/Views/Products/searchresults.dart:46`
- `lib/Views/Products/Update/searchupdate.dart:55`
- Similar category paths are built from raw category strings in product listing screens.

Why this is vulnerable:

Raw interpolation into URLs can produce malformed requests and parameter injection, for example when a search query includes `&`, `?`, or path separator characters. Server-side injection depends on backend implementation, but the client should still construct URLs safely.

Fix:

- Use `Uri.https(host, path, {'q': query})` for query parameters.
- Use `Uri.encodeComponent` for dynamic path segments.
- Validate and normalize category values.

### 9. Full Backend Error Responses Are Shown To Users

Affected places:

- `lib/Views/Auth/resetpass.dart:81` and `lib/Views/Auth/resetpass.dart:130`
- `lib/Views/Merchant/upload.dart:247`
- `lib/Views/Auth/kyc.dart:102`
- Several screens print or surface raw `response.body` during error cases.

Why this is vulnerable:

Raw API errors often reveal stack traces, validation internals, database field names, provider errors, or account-existence information. This helps attackers map the backend and can leak sensitive data to screenshots/support logs.

Fix:

- Map backend errors to safe user-facing messages.
- Log sanitized error IDs server-side, not raw details in the client.

### 10. No Evidence Of Certificate Pinning Or Network Hardening

Affected places:

- The app uses the default `http` client throughout; no `SecurityContext`, certificate pinning, or custom transport hardening was found.
- Android only declares internet permission in `android/app/src/main/AndroidManifest.xml:45`.
- No ATS exceptions were found in `ios/Runner/Info.plist`, which is good, but HTTPS trust still relies on the platform CA store.

Why this matters:

For a wallet/payment app, platform TLS is the baseline, but a compromised CA, user-installed root certificate, enterprise interception, or rooted device can still intercept traffic unless the app or backend uses additional controls.

Fix:

- Consider certificate/public-key pinning for the Retilda API host if operationally acceptable.
- Add backend replay protections and short-lived tokens.
- Ensure HSTS and modern TLS are configured on the backend.

### 11. Firebase Configuration Is Checked In

Affected places:

- `ios/Runner/GoogleService-Info.plist:5`
- `macos/Runner/GoogleService-Info.plist:5`
- `lib/firebase_options.dart:50`

Why this matters:

Firebase API keys are often intended to be embedded in clients, but they must be restricted. If unrestricted, attackers can abuse Firebase-backed services, quota, analytics, or storage access depending on project configuration.

Fix:

- Restrict Firebase API keys to expected bundle IDs/package names and SHA fingerprints.
- Review Firestore/Storage/Auth rules.
- Remove stale commented config from source if Firebase is not in use.

## Attack Surface Inventory

Authentication and session:

- Login: `/Api/login`
- Signup: `/Api/signUp`
- Forgot/reset password: `/Api/forgotPassword`, `/Api/resetPassword`
- Staff login: `/Api/staff/login`
- Client storage keys: `userData`, `userRole`, `staffToken`, `staffRole`, `staffData`

Wallet and payments:

- Wallet balance and transactions: `/Api/userBalance`, `/Api/viewTransactionHistory`, `/Api/balance`
- Product purchase: `/Api/buyproductonsales/onetimepaymentusingcard`, `/Api/buyProductOnInstallment`, `/Api/buyProductOnInstallmentUsingCard`
- Repayments/top-ups: `/Api/installmentRepaymentUsingWallet`, `/Api/installmentRepaymentUsingCard`, `/Api/installmentRepaymentUsingWalletByPercentage`
- Direct debit: `/Api/direct-debit`
- Payment URLs loaded in unrestricted webviews.

Admin/staff operations:

- Users and purchases: `/Api/users`, `/Api/getUserPurchases`
- Staff creation/active/chat: `/Api/staff`, `/Api/staff/active`, `/Api/chat/staff/*`
- Order/delivery mutation: `/Api/order/status`, `/Api/products/updatedelivery`, `/Api/updatedPurchasesForDeliveryCompleted/*`
- Invoice admin flows: `/Api/admin/invoices`, `/Api/invoices/*`
- Geo state mutation: `/Api/geo/states`

Product and merchant operations:

- Product upload/update/delete/search/category listing under `/Api/products/*`, `/Api/uploadproduct`, `/Api/updateProductByPrice/*`
- Multipart file upload and user-controlled product metadata.

Messaging:

- User chat threads/messages: `/Api/chat/threads`, `/Api/chat/start`, `/Api/chat/messages/*`, `/Api/chat/message`, `/Api/chat/close/*`
- Staff chat threads/messages: `/Api/chat/staff/*`

## Priority Remediation Plan

1. Remove credential/token/full-response logging and ship only release builds.
2. Migrate tokens from `SharedPreferences` to secure storage and reduce persisted profile data.
3. Add strict URL allowlisting and navigation controls for all webviews, especially payment, invoice, and bank authorization flows.
4. Remove user-token fallback from staff/admin/invoice services and enforce server-side role/scope checks.
5. Add backend tests for IDOR/BOLA on every `userId`, `purchaseId`, `invoiceId`, `threadId`, and `productId`.
6. Harden password reset: OTP rate limits, transaction binding, single-use expiry, uniform responses, session invalidation.
7. Validate all upload/product/search inputs server-side and construct client URLs with `Uri` query/path encoding.
8. Review Firebase restrictions, backend TLS/HSTS, token lifetime, refresh rotation, and audit logging.

## Notes

This report intentionally avoids exploit steps. The items above are enough to reproduce the engineering risk in code review and to create backend/client remediation tickets. Backend source and configuration should be audited next because most high-impact issues depend on whether the API correctly enforces role and object-level authorization.
