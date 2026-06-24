/**
 * scenarios/06_payment.js
 * Load test: Paymob webhook HTTP endpoint.
 *
 * Tests the publicly accessible Cloud Function HTTP endpoint that Paymob calls
 * after a payment is processed. The endpoint should always return 200 OK.
 *
 * NOTE: This does NOT trigger wallet crediting — that is handled by
 * onPaymentStatusChanged (a Firestore trigger), which is tested in 08_full_journey.js.
 * This test only verifies the HTTP endpoint's availability and latency under load.
 *
 * Environment variable required:
 *   PAYMOB_WEBHOOK_URL — the deployed Cloud Function URL, e.g.:
 *   https://paymobwebhook-<hash>-uc.a.run.app
 *   (leave unset to skip this scenario with a warning)
 *
 * Run standalone:
 *   k6 run --env FIREBASE_API_KEY=<key> \
 *          --env PAYMOB_WEBHOOK_URL=https://... \
 *          scenarios/06_payment.js
 */

import http from 'k6/http';
import { sleep, check } from 'k6';
import { uuidv4 } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';
import { loadTestOptions } from '../k6.config.js';
import { randSleep } from '../helpers/utils.js';

export const options = {
  ...loadTestOptions,
  thresholds: {
    ...loadTestOptions.thresholds,
    'http_req_duration{name:paymob/webhook}': ['p(95)<2000'],
    'http_req_failed{name:paymob/webhook}':   ['rate<0.01'],
  },
};

const WEBHOOK_URL = __ENV.PAYMOB_WEBHOOK_URL || '';

/** Build a realistic Paymob webhook payload */
function buildPaymobPayload(transactionId) {
  return {
    obj: {
      id: transactionId,
      pending: false,
      amount_cents: 10000, // 100 EGP
      success: true,
      is_auth: false,
      is_capture: false,
      is_standalone_payment: true,
      is_voided: false,
      is_refunded: false,
      is_3d_secure: true,
      integration_id: 999999,
      profile_id: 12345,
      has_parent_transaction: false,
      order: {
        id: Math.floor(Math.random() * 1000000),
        merchant_order_id: `lt_order_${transactionId}`,
        amount_cents: 10000,
        shipping_data: {},
      },
      created_at: new Date().toISOString(),
      transaction_processed_callback_responses: [],
      currency: 'EGP',
      source_data: {
        pan: '2346',
        type: 'card',
        tenure: null,
        sub_type: 'Visa',
      },
      error_occured: false,
      owner: 123456,
      data_message: '',
      is_hidden: false,
      payment_key_claims: {
        amount_cents: 10000,
        currency: 'EGP',
        extra: {},
      },
      merchant: {
        id: 12345,
        created_at: '2024-01-01T00:00:00',
        phones: [],
        company_emails: [],
        company_name: 'Barter Load Test',
      },
    },
    type: 'TRANSACTION',
  };
}

export default function () {
  if (!WEBHOOK_URL) {
    // Skip with a note — URL not configured
    sleep(1);
    return;
  }

  const txId = Math.floor(Math.random() * 9000000) + 1000000;
  const payload = buildPaymobPayload(txId);

  const res = http.post(
    `${WEBHOOK_URL}?hmac=lt_test_hmac`,
    JSON.stringify(payload),
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { name: 'paymob/webhook' },
    }
  );

  check(res, {
    'webhook: status 200': (r) => r.status === 200,
    'webhook: response OK': (r) => r.body === 'OK' || r.status === 200,
  });

  sleep(randSleep(500, 2000));
}
