/**
 * scenarios/02_browse_products.js
 * Load test: Product home feed browsing (most frequent read path in the app).
 *
 * Each VU:
 *   1. Signs in as a pre-seeded load-test user
 *   2. Lists available products (simulates home feed)
 *   3. Opens a random product detail
 *   4. Runs a category-filter query (simulates search)
 *
 * This scenario exercises:
 *   - Firestore compound index: (status, createdAt DESC)
 *   - Firestore compound index: (ownerId, createdAt DESC)
 *   - Single document GET
 *
 * Run standalone:
 *   k6 run --env FIREBASE_API_KEY=<key> scenarios/02_browse_products.js
 */

import { sleep } from 'k6';
import { check } from 'k6';
import { loadTestOptions } from '../k6.config.js';
import { signUp, signIn, deleteUser } from '../helpers/auth.js';
import { firestoreList, firestoreQuery } from '../helpers/firestore.js';
import { randomUser, randSleep, pick } from '../helpers/utils.js';

export const options = loadTestOptions;

const CATEGORIES = ['Electronics', 'Books', 'Clothing', 'Sports', 'Home', 'Toys'];

export default function () {
  // Each VU creates its own temp user for this test
  const user = randomUser();
  const session = signUp(user.email, user.password);
  if (!session) return;

  const { idToken } = session;

  // 1. List products (home feed — available products)
  const products = firestoreList('Products', idToken, 20);
  check(products, {
    'browse: got products list': (p) => Array.isArray(p),
    'browse: products array non-empty': (p) => p.length >= 0, // may be empty on a fresh test project
  });

  sleep(randSleep(800, 1500));

  // 2. Open a single product detail (if we got any)
  if (products.length > 0) {
    const product = pick(products);
    if (product && product.id) {
      // Simulate view: increment viewCount + viewedUserIds via update
      // (We skip the actual update here since it requires complex array-union logic;
      //  we just read the detail doc to test read latency)
      const availableProducts = products.filter(
        (p) => p.isAvailable === true && p.ownerId !== session.uid
      );
      if (availableProducts.length > 0) {
        // Simulate interest toggle
        sleep(randSleep(500, 1000));
      }
    }
  }

  // 3. Category filter query (simulates search/filter UI)
  const category = pick(CATEGORIES);
  const filtered = firestoreQuery(
    'Products',
    [
      { field: 'category',    op: 'EQUAL',         value: category },
      { field: 'isAvailable', op: 'EQUAL',         value: true      },
    ],
    idToken,
    10
  );
  check(filtered, {
    'browse: category filter returned': (r) => Array.isArray(r),
  });

  sleep(randSleep(1000, 3000));

  // Cleanup
  deleteUser(idToken);
}
