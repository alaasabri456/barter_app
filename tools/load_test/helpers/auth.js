/**
 * helpers/auth.js
 * Firebase Authentication REST API helpers for k6 load tests.
 *
 * Uses Firebase Identity Toolkit REST API v1:
 *   POST https://identitytoolkit.googleapis.com/v1/accounts:signUp
 *   POST https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword
 *   POST https://identitytoolkit.googleapis.com/v1/accounts:delete
 */

import http from 'k6/http';
import { check } from 'k6';

const API_KEY = __ENV.FIREBASE_API_KEY || 'AIzaSyDpLwQQpMlyMEyEZFi2YC-xKiQvA_TuX4E';
const AUTH_BASE = 'https://identitytoolkit.googleapis.com/v1/accounts';

const JSON_HEADERS = { 'Content-Type': 'application/json' };

/**
 * Register a new Firebase user.
 * @param {string} email
 * @param {string} password
 * @returns {{ idToken: string, uid: string, email: string } | null}
 */
export function signUp(email, password) {
  const res = http.post(
    `${AUTH_BASE}:signUp?key=${API_KEY}`,
    JSON.stringify({ email, password, returnSecureToken: true }),
    { headers: JSON_HEADERS, tags: { name: 'auth/signUp' } }
  );

  const ok = check(res, {
    'signUp: status 200': (r) => r.status === 200,
    'signUp: has idToken': (r) => {
      try { return !!JSON.parse(r.body).idToken; } catch { return false; }
    },
  });

  if (!ok) return null;

  const body = JSON.parse(res.body);
  return { idToken: body.idToken, uid: body.localId, email: body.email };
}

/**
 * Sign in an existing Firebase user with email/password.
 * @param {string} email
 * @param {string} password
 * @returns {{ idToken: string, uid: string, refreshToken: string } | null}
 */
export function signIn(email, password) {
  const res = http.post(
    `${AUTH_BASE}:signInWithPassword?key=${API_KEY}`,
    JSON.stringify({ email, password, returnSecureToken: true }),
    { headers: JSON_HEADERS, tags: { name: 'auth/signIn' } }
  );

  const ok = check(res, {
    'signIn: status 200': (r) => r.status === 200,
    'signIn: has idToken': (r) => {
      try { return !!JSON.parse(r.body).idToken; } catch { return false; }
    },
  });

  if (!ok) return null;

  const body = JSON.parse(res.body);
  return {
    idToken: body.idToken,
    uid: body.localId,
    refreshToken: body.refreshToken,
  };
}

/**
 * Delete a Firebase Auth user (cleanup after tests).
 * Requires the user's current idToken.
 * @param {string} idToken
 * @returns {boolean}
 */
export function deleteUser(idToken) {
  const res = http.post(
    `${AUTH_BASE}:delete?key=${API_KEY}`,
    JSON.stringify({ idToken }),
    { headers: JSON_HEADERS, tags: { name: 'auth/deleteUser' } }
  );
  return res.status === 200;
}
