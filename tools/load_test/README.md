# 🔥 Barter App — Load Test Suite

A comprehensive [k6](https://k6.io) load test suite for the Barter Firebase backend.
Tests **Cloud Functions + Firestore together** via the Firebase REST APIs, running the full user journey under gradual ramp-up load.

---

## 📁 Directory Structure

```
tools/load_test/
├── k6.config.js              # Load profiles: default ramp-up, smoke, spike
├── helpers/
│   ├── auth.js               # Firebase Auth REST (signUp, signIn, deleteUser)
│   ├── firestore.js          # Firestore REST (get, set, update, delete, query)
│   └── utils.js              # Random data generators (users, products, trades, messages)
├── scenarios/
│   ├── 01_auth.js            # Auth throughput only
│   ├── 02_browse_products.js # Home feed + category filter
│   ├── 03_create_product.js  # Product listing creation
│   ├── 04_trade.js           # Trade offer → accept lifecycle
│   ├── 05_chat.js            # Conversation + message flow
│   ├── 06_payment.js         # Paymob webhook HTTP endpoint
│   ├── 07_favourites.js      # Favourites add/remove
│   └── 08_full_journey.js    ⭐ MAIN — Complete end-to-end scenario
├── cleanup.js                # Node.js post-run cleanup (deletes lt_ data)
├── run_load_test.ps1         # PowerShell runner with pre-checks
├── results/                  # Auto-created on first run (JSON + summaries)
└── README.md                 # This file
```

---

## 🚀 Quick Start

### 1. Prerequisites

| Tool | Install |
|------|---------|
| **k6** v2.0+ | Already installed via `winget install k6` |
| **Node.js** 18+ | For the cleanup script only |

### 2. Environment Variables

Set these in your PowerShell session before running:

```powershell
$env:FIREBASE_API_KEY    = "AIzaSyDpLwQQpMlyMEyEZFi2YC-xKiQvA_TuX4E"
$env:FIREBASE_PROJECT_ID = "barter-30a05"

# Optional — required only for scenario 06_payment.js
$env:PAYMOB_WEBHOOK_URL  = "https://paymobwebhook-XXXX-uc.a.run.app"
```

### 3. Run Tests

#### ✅ Smoke test first (always do this before a full run!)
```powershell
.\tools\load_test\run_load_test.ps1 -Scenario smoke
```
*~1 minute, 3 VUs — verifies everything is wired up correctly.*

#### 🚀 Full gradual ramp-up load test
```powershell
.\tools\load_test\run_load_test.ps1
```
*~12 minutes, ramps 0 → 150 VUs.*

#### ⚡ Spike test
```powershell
.\tools\load_test\run_load_test.ps1 -Scenario spike
```
*~2 minutes, bursts to 200 VUs suddenly.*

#### 🎯 Run a single scenario
```powershell
.\tools\load_test\run_load_test.ps1 -ScenarioFile 04_trade
```

#### Run directly with k6 (more control):
```powershell
k6 run `
  --env FIREBASE_API_KEY=$env:FIREBASE_API_KEY `
  --env FIREBASE_PROJECT_ID=barter-30a05 `
  --env SCENARIO=smoke `
  --out json=tools/load_test/results/my_results.json `
  tools/load_test/scenarios/08_full_journey.js
```

---

## 📊 Load Profile

| Stage | Duration | VUs | Purpose |
|-------|----------|-----|---------|
| Ramp up | 1 min | 0 → 10 | Warm-up / smoke check |
| Ramp up | 2 min | 10 → 50 | Normal load |
| Ramp up | 2 min | 50 → 100 | Approaching stress |
| Ramp up | 2 min | 100 → 150 | Peak / stress |
| Hold | 3 min | 150 | Sustained peak |
| Ramp down | 2 min | 150 → 0 | Graceful finish |
| **Total** | **~12 min** | **peak 150** | |

---

## 🎯 Scenarios Covered

| # | Scenario | Collections Touched | Cloud Functions |
|---|----------|---------------------|-----------------|
| 01 | Auth | Firebase Auth | — |
| 02 | Browse Products | `Products` | — |
| 03 | Create Product | `Users`, `Products` | — |
| 04 | Trade Offer + Accept | `Users`, `Products`, `Trades` | `onTradeCreated`, `onTradeStatusChanged` |
| 05 | Chat | `Users`, `Conversations`, `messages` | `onConversationMessageCreated` |
| 06 | Paymob Webhook | HTTP endpoint | `paymobWebhook` |
| 07 | Favourites | `Users` | — |
| 08 | **Full Journey** | All of the above | All |

---

## ✅ SLO Thresholds

| Metric | Target |
|--------|--------|
| All requests p95 | < 3,000 ms |
| Auth requests p95 | < 1,500 ms |
| Firestore reads p95 | < 2,000 ms |
| Firestore writes p95 | < 3,000 ms |
| Webhook p95 | < 2,000 ms |
| Error rate | < 5% |
| Check pass rate | > 95% |

---

## 🗑️ Test Data Cleanup

All load-test data uses the `lt_` prefix so it's easy to identify:
- **Users**: email format `lt_<uuid>@test.barter.load`
- **Products**: title format `LT Product <id>`
- **Trades**: message starts with `Load test trade offer`

The k6 `teardown()` function cleans up per-VU data automatically. For any leftover data after a failed/interrupted run, use the cleanup script:

```powershell
# Requires a Firebase Service Account key
node tools/load_test/cleanup.js --key path/to/serviceAccountKey.json
```

---

## 📈 Viewing Results

### During the test
- **k6 terminal** — live metrics (VUs, RPS, p95, error rate)
- **[Firebase Console → Firestore Usage](https://console.firebase.google.com/project/barter-30a05/firestore/usage)** — reads/writes per second
- **[Firebase Console → Functions](https://console.firebase.google.com/project/barter-30a05/functions/logs)** — Cloud Function invocations and errors

### After the test
Results are saved to `tools/load_test/results/`:
- `results_<scenario>_<timestamp>.json` — full k6 metrics (importable to Grafana)
- `summary_<scenario>_<timestamp>.txt` — human-readable threshold summary

### Key metrics to check in Firebase Console after run:
1. **Functions → `onTradeCreated`**: Should show ~1 invocation per VU iteration with < 1% errors
2. **Functions → `onConversationMessageCreated`**: Should show ~2 invocations per VU iteration
3. **Firestore → Usage**: Reads and writes should scale linearly with VU count
4. **Auth**: User creation rate (signUps/sec) should match your VU ramp

---

## ⚠️ Important Notes

> **Production Safety**: This suite runs against your production Firebase project (`barter-30a05`). All test data is prefixed with `lt_` and is cleaned up after each run. However:
> - Cloud Function invocations **do cost money** (though the free tier covers ~2M/month)
> - Firestore reads/writes **do count** against your quota
> - Run the smoke test first to estimate costs before a full load test
> - Consider running full load tests during off-hours

> **Firestore Security Rules**: All requests go through your real Firestore security rules. A test failure may indicate a security rule misconfiguration, not just a performance issue.

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| `signUp: status 400` | Check if Firebase Auth has email/password enabled |
| `firestoreSet: status 403` | Security rules denied the write — check field names match rules |
| `firestoreSet: status 400` | Document field type mismatch — check `utils.js` product/trade shapes |
| k6 threshold failed | Check Firebase Console for slow queries or missing indexes |
| Cloud Function not firing | Check Functions logs for errors; ensure functions are deployed |
