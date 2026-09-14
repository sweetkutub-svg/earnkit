# EARNKIT — FIRESTORE DATA MODEL (Phase 4)

## Collection: users/{uid}
| Field | Type | Notes |
|---|---|---|
| uid | string | matches Firebase Auth uid |
| name | string | |
| email | string | |
| createdAt | timestamp | server-set |
| walletBalance | int | EarnGrow Points, withdrawable — server-write only from Phase 7 |
| lockedBonus | int | EarnGrow Points, locked until unlock condition met |
| referralCodeUsed | string | empty if none |
| signInMethod | string | 'email' \| 'google' |
| emailVerified | bool | true always for google sign-in |

## Collection: transactions/{transactionId}
| Field | Type | Notes |
|---|---|---|
| uid | string | owner |
| type | string | 'ad_watched' \| 'task_completed' \| 'referral_bonus' \| 'withdrawal' |
| amount | int | signed delta in points |
| source | string | human-readable description |
| timestamp | timestamp | server-set |

## Collection: withdrawals/{withdrawalId}
| Field | Type | Notes |
|---|---|---|
| uid | string | owner |
| amount | int | |
| upiId | string | |
| status | string | 'pending' \| 'approved' \| 'paid' \| 'rejected' |
| requestedAt | timestamp | server-set |
| gatewayTransactionId | string? | null until paid |

## Collection: referrals/{referralId}
| Field | Type | Notes |
|---|---|---|
| referrerUid | string | who gets the bonus |
| referredUid | string | who signed up |
| referralCode | string | |
| completed | bool | true once referred user completes 1 verified activity |
| createdAt | timestamp | server-set |

---
**Security note:** `updateWallet()` in `firestore_service.dart` is a Phase 4 testing
scaffold — direct client wallet writes are temporarily allowed via Firestore rules
below. From Phase 7 onward this must be locked down to Cloud Functions only
(see 03_SECURITY.md Section 3).
