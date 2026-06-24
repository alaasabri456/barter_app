/**
 * scenarios/03_create_product.js
 * Load test: Product listing creation (seller flow).
 *
 * Each VU:
 *   1. Signs up as a new load-test user
 *   2. Creates a User document (required by Firestore rules)
 *   3. Creates a Product document
 *   4. Reads the product back (verify)
 *   5. Deletes the product + user (cleanup)
 *
 * Run standalone:
 *   k6 run --env FIREBASE_API_KEY=<key> scenarios/03_create_product.js
 */

import { sleep } from 'k6';
import { check } from 'k6';
import { uuidv4 } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';
import { loadTestOptions } from '../k6.config.js';
import { signUp, deleteUser } from '../helpers/auth.js';
import { firestoreSet, firestoreGet, firestoreDelete } from '../helpers/firestore.js';
import { randomUser, randomProduct, randSleep } from '../helpers/utils.js';

export const options = loadTestOptions;

export default function () {
  const user = randomUser();
  const session = signUp(user.email, user.password);
  if (!session) return;

  const { idToken, uid } = session;

  // 1. Create User document (Firestore security rules require this to exist)
  const userDoc = {
    id: uid,
    name: user.name,
    email: user.email,
    role: 'user',
    walletBalance: 0,
    isPremiumActive: false,
    isSuspended: false,
    favouriteProductIds: [],
    blockedUserIds: [],
  };
  const userCreated = firestoreSet('Users', uid, userDoc, idToken);
  check(userCreated, { 'createProduct: user doc created': Boolean });

  sleep(randSleep(200, 500));

  // 2. Create a product
  const product = randomProduct(uid, user.name);
  const productCreated = firestoreSet('Products', product.id, product, idToken);
  check(productCreated, { 'createProduct: product doc created': Boolean });

  sleep(randSleep(300, 800));

  // 3. Read it back to verify
  const fetched = firestoreGet('Products', product.id, idToken);
  check(fetched, {
    'createProduct: product readable': (p) => p !== null,
    'createProduct: title matches': (p) => p !== null && p.title === product.title,
  });

  sleep(randSleep(500, 1500));

  // 4. Cleanup — only what security rules allow for regular users
  firestoreDelete('Products', product.id, idToken);  // owners can delete ✅
  // firestoreDelete('Users', uid, idToken) ❌ admin-only — cleanup.js handles User docs
  deleteUser(idToken);  // Firebase Auth self-delete ✅

  sleep(randSleep(500, 1000));
}
