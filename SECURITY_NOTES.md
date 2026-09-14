# EARNKIT — SECURITY & CONFIG NOTES
(Internal reference — DO NOT commit sensitive values to public repo)

---

## 1. Firebase Project
- Project ID: `earnkit-app`
- Firebase console: https://console.firebase.google.com/project/earnkit-app
- Registered platforms: android, ios, macos, web, windows (only ANDROID is actively used per roadmap)
- Config file: `lib/firebase_options.dart` (auto-generated, safe to commit — contains public config, not secret keys)
- Firebase Auth account used to create project: 1234skkutub@gmail.com

## 2. Package / Bundle IDs
- Android package name: `com.example.earnkit` (⚠️ TODO: change to proper package name like `com.codewithkutub.earnkit` before Phase 20 release — "com.example" is not allowed on Play Store)

## 3. Firestore Security Rules (apply from Phase 4 onward)
- Users can only read/write their own `users/{uid}` doc
- `walletBalance`, `lockedBonus`, `transactions` fields → Cloud Function-only writes, NEVER client-writable
- Rule reference: see `03_SECURITY.md` Section 2

## 4. Reward Crediting Rule (CRITICAL — never violate)
- Wallet balance NEVER updated directly from Flutter client code
- Only Cloud Functions (server-side, after SSV/postback verification) may write to walletBalance
- Phase 6 (AdMob test ads): only LOG the "ad watched" event, do not credit
- Phase 7: real crediting logic goes here, server-side only

## 5. API Keys / Secrets (fill in as each phase adds them — NEVER commit actual values to GitHub)
- AdMob App ID: _(not yet set — Phase 6)_
- AdMob Rewarded Ad Unit ID (test): _(not yet set — Phase 6)_
- AdMob Rewarded Ad Unit ID (production): _(not yet set — Phase 20, only at release)_
- Offerwall (Ayet Studios / AdGate) publisher key: _(not yet set — Phase 12)_
- Razorpay/Cashfree Payout API key: _(not yet set — Phase 14)_
- Admin Panel Firebase Auth pool: _(not yet set — Phase 17, MUST be separate from user app auth)_

## 6. .gitignore Checklist (verify before every commit)
- [ ] `google-services.json` NOT committed (Android Firebase config — sensitive)
- [ ] `GoogleService-Info.plist` NOT committed (iOS Firebase config — sensitive)
- [ ] `.env` files NOT committed
- [ ] `firebase_options.dart` — ⚠️ contains API keys too, technically safe for client apps (public by design) but double-check before public repo push

## 7. Admin Panel (Phase 17 — future)
- Separate Firebase Auth user pool (allow-listed emails, no public signup)
- 2FA mandatory
- Hosted separately (Vercel, non-obvious subdomain)
- Every sensitive action → audit log (who/what/when/old→new value)

---
**Update this file every time a new key, credential type, or security-relevant decision is added in any phase.**