/**
 * scenarios/01_auth.js
 * Load test: Firebase Authentication throughput.
 *
 * Each VU:
 *   1. Generates a unique load-test user
 *   2. Calls signUp → verifies idToken received
 *   3. Calls signIn → verifies idToken received
 *   4. Deletes the user (cleanup)
 *
 * Run standalone:
 *   k6 run --env FIREBASE_API_KEY=<key> scenarios/01_auth.js
 */

import { sleep } from 'k6';
import { loadTestOptions } from '../k6.config.js';
import { signUp, signIn, deleteUser } from '../helpers/auth.js';
import { randomUser, randSleep } from '../helpers/utils.js';

export const options = loadTestOptions;

export default function () {
  const user = randomUser();

  // 1. Sign up
  const registered = signUp(user.email, user.password);
  if (!registered) {
    sleep(2);
    return;
  }

  sleep(randSleep(200, 500));

  // 2. Sign in (simulates returning user)
  const session = signIn(user.email, user.password);
  if (!session) {
    deleteUser(registered.idToken);
    sleep(2);
    return;
  }

  sleep(randSleep(500, 1500));

  // 3. Cleanup — delete test user from Firebase Auth
  deleteUser(session.idToken);

  sleep(randSleep(1000, 2000));
}
