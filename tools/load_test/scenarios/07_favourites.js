/**
 * scenarios/07_favourites.js
 * Load test: Favourites toggle (add/remove a product from favourites list).
 *
 * Exercises: Users/{uid}.favouriteProductIds field update — a partial Firestore
 * update that the Firestore security rules carefully validate.
 *
 * Flow per VU:
 *   1. Sign up + create User doc
 *   2. Create a product to favourite
 *   3. Add product to favouriteProductIds (simulates heart tap)
 *   4. Remove product from favouriteProductIds (simulates un-heart tap)
 *   5. Cleanup
 *
 * Run standalone:
 *   k6 run --env FIREBASE_API_KEY=<key> scenarios/07_favourites.js
 */

import { sleep } from 'k6';
import { check } from 'k6';
import { uuidv4 } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';
import { loadTestOptions } from '../k6.config.js';
import { signUp, deleteUser } from '../helpers/auth.js';
import { firestoreSet, firestoreUpdate, firestoreGet, firestoreDelete } from '../helpers/firestore.js';
import { randomUser, randomProduct, randSleep } from '../helpers/utils.js';

export const options = loadTestOptions;

export default function () {
  const user = randomUser();
  const session = signUp(user.email, user.password);
  if (!session) return;

  const { idToken, uid } = session;

  // 1. Create User document
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
  firestoreSet('Users', uid, userDoc, idToken);

  sleep(randSleep(200, 400));

  // 2. Create a product to favourite (owned by a "seller" — but we just need an ID)
  const product = randomProduct(uid, user.name);
  firestoreSet('Products', product.id, product, idToken);

  sleep(randSleep(300, 600));

  // 3. Read current user doc
  const currentUser = firestoreGet('Users', uid, idToken);
  if (!currentUser) {
    firestoreDelete('Products', product.id, idToken);
    deleteUser(idToken);
    return;
  }

  // 4. Add product to favourites (read-then-write satisfies validOwnUserUpdate rule)
  const withFav = Object.assign({}, currentUser, { favouriteProductIds: [product.id] });
  const added = firestoreSet('Users', uid, withFav, idToken);
  check(added, { 'favourites: product added': Boolean });

  sleep(randSleep(500, 1500));

  // 5. Remove product from favourites
  const withoutFav = Object.assign({}, currentUser, { favouriteProductIds: [] });
  const removed = firestoreSet('Users', uid, withoutFav, idToken);
  check(removed, { 'favourites: product removed': Boolean });

  sleep(randSleep(500, 1000));

  // 6. Cleanup — only what security rules allow from client tokens
  firestoreDelete('Products', product.id, idToken);  // owners can delete products ✅
  // firestoreDelete('Users', uid, idToken) ❌ admin-only — handled by cleanup.js
  deleteUser(idToken);  // Firebase Auth self-delete ✅

  sleep(randSleep(500, 1000));
}
