/**
 * k6.config.js
 * Shared k6 options, stages, and thresholds for the Barter load test suite.
 *
 * Load profile:
 *   0 → 10 VUs  over  1 min  (warm-up / smoke check)
 *   10 → 50 VUs over  2 min  (ramp up to normal load)
 *   50 → 100 VUs over 2 min  (approaching stress)
 *   100 → 150 VUs over 2 min (peak / stress)
 *   150 VUs held for  3 min  (sustained peak)
 *   150 → 0 VUs over  2 min  (ramp down)
 *   Total: ~12 minutes
 *
 * Thresholds (SLO targets):
 *   - 95th-percentile request duration < 3 s
 *   - < 5% of requests may fail
 *   - Firestore reads p95 < 2 s
 *   - Auth requests p95 < 1.5 s
 */

export const loadTestOptions = {
  stages: [
    { duration: '1m',  target: 10  },
    { duration: '2m',  target: 50  },
    { duration: '2m',  target: 100 },
    { duration: '2m',  target: 150 },
    { duration: '3m',  target: 150 },
    { duration: '2m',  target: 0   },
  ],

  thresholds: {
    // Overall
    http_req_duration: ['p(95)<3000'],
    http_req_failed:   ['rate<0.05'],

    // Auth endpoints
    'http_req_duration{name:auth/signUp}': ['p(95)<1500'],
    'http_req_duration{name:auth/signIn}': ['p(95)<1500'],

    // Firestore reads
    'http_req_duration{name:firestore/get/Products}':   ['p(95)<2000'],
    'http_req_duration{name:firestore/list/Products}':  ['p(95)<2000'],
    'http_req_duration{name:firestore/query/Products}': ['p(95)<2000'],
    'http_req_duration{name:firestore/query/Trades}':   ['p(95)<2500'],
    'http_req_duration{name:firestore/get/Trades}':     ['p(95)<2000'],

    // Firestore writes
    'http_req_duration{name:firestore/set/Products}':   ['p(95)<3000'],
    'http_req_duration{name:firestore/set/Trades}':     ['p(95)<3000'],

    // Check pass-rate — 95% of all checks must pass
    checks: ['rate>0.95'],
  },

  // k6 Cloud / Grafana output tags
  tags: {
    env: 'staging',
    app: 'barter',
    project: 'barter-30a05',
  },

  // Graceful stop: wait up to 30s for iterations to finish on ramp-down
  gracefulStop: '30s',
};

/**
 * Smoke test options — quick sanity check (< 1 min, 3 VUs).
 * Run with: k6 run --env SCENARIO=smoke scenarios/08_full_journey.js
 */
export const smokeOptions = {
  stages: [
    { duration: '30s', target: 3 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<4000'],
    http_req_failed:   ['rate<0.10'],
  },
  tags: { env: 'smoke', app: 'barter' },
};

/**
 * Spike test options — sudden burst to 200 VUs.
 * Run with: k6 run --env SCENARIO=spike scenarios/08_full_journey.js
 */
export const spikeOptions = {
  stages: [
    { duration: '30s', target: 200 },
    { duration: '1m',  target: 200 },
    { duration: '30s', target: 0   },
  ],
  thresholds: {
    http_req_duration: ['p(95)<5000'],
    http_req_failed:   ['rate<0.10'],
  },
  tags: { env: 'spike', app: 'barter' },
};
