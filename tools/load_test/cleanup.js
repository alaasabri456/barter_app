/**
 * cleanup.js
 * Post-test cleanup script (Node.js — NOT k6).
 *
 * Deletes all Firestore documents and Firebase Auth users that were created
 * by the load test (identified by the "lt_" prefix in emails / product titles).
 *
 * Requirements:
 *   - Node.js 18+
 *   - A Firebase service account key JSON file
 *
 * Usage:
 *   node tools/load_test/cleanup.js --key path/to/serviceAccountKey.json
 *
 * Or set GOOGLE_APPLICATION_CREDENTIALS env var:
 *   $env:GOOGLE_APPLICATION_CREDENTIALS = "path/to/serviceAccountKey.json"
 *   node tools/load_test/cleanup.js
 */

const admin = require('firebase-admin');
const path = require('path');

// ── Init ──────────────────────────────────────────────────────────────────────
const keyArg = process.argv.indexOf('--key');
if (keyArg !== -1 && process.argv[keyArg + 1]) {
  process.env.GOOGLE_APPLICATION_CREDENTIALS = path.resolve(process.argv[keyArg + 1]);
}

admin.initializeApp({
  projectId: 'barter-30a05',
});

const db   = admin.firestore();
const auth = admin.auth();

const LT_PREFIX    = 'lt_';
const BATCH_SIZE   = 400; // Firestore batch limit is 500

// Collections to scan for load-test documents
const COLLECTIONS_TO_CLEAN = [
  { name: 'Products',      field: 'title',    prefix: `LT Product` },
  { name: 'Trades',        field: 'message',  prefix: `Load test trade` },
  { name: 'Conversations', field: 'id',       prefix: `conversation_` },
  { name: 'Users',         field: 'email',    prefix: LT_PREFIX },
  { name: 'Notifications', field: 'body',     prefix: null }, // cleaned via user deletion cascade
];

async function deleteCollection(collectionName, field, prefix) {
  if (!prefix) return 0;

  console.log(`\n🗑️  Scanning ${collectionName} where ${field} starts with "${prefix}"...`);
  let deleted = 0;

  // Firestore doesn't support startsWith, so we use range query: >= prefix && < prefix + '\uf8ff'
  const snap = await db.collection(collectionName)
    .where(field, '>=', prefix)
    .where(field, '<=', prefix + '\uf8ff')
    .get();

  if (snap.empty) {
    console.log(`   ✅ No load-test documents found in ${collectionName}.`);
    return 0;
  }

  console.log(`   Found ${snap.size} documents to delete.`);

  // Process in batches
  const docs = snap.docs;
  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    docs.slice(i, i + BATCH_SIZE).forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    deleted += Math.min(BATCH_SIZE, docs.length - i);
    console.log(`   Deleted ${deleted}/${snap.size} from ${collectionName}...`);
  }

  return deleted;
}

async function deleteLoadTestAuthUsers() {
  console.log(`\n🗑️  Scanning Firebase Auth for load-test users (email prefix: "${LT_PREFIX}")...`);
  let deleted = 0;
  let pageToken;

  do {
    const result = await auth.listUsers(1000, pageToken);
    const ltUsers = result.users.filter((u) => u.email && u.email.startsWith(LT_PREFIX));

    if (ltUsers.length > 0) {
      const uids = ltUsers.map((u) => u.uid);
      await auth.deleteUsers(uids);
      deleted += uids.length;
      console.log(`   Deleted ${deleted} load-test auth users so far...`);
    }

    pageToken = result.pageToken;
  } while (pageToken);

  return deleted;
}

async function main() {
  console.log('════════════════════════════════════════════════════');
  console.log('  Barter Load Test — Post-Run Cleanup               ');
  console.log('  Project: barter-30a05                             ');
  console.log('════════════════════════════════════════════════════');

  let totalDeleted = 0;

  for (const { name, field, prefix } of COLLECTIONS_TO_CLEAN) {
    totalDeleted += await deleteCollection(name, field, prefix);
  }

  totalDeleted += await deleteLoadTestAuthUsers();

  console.log('\n════════════════════════════════════════════════════');
  console.log(`  Cleanup complete. Total documents/users removed: ${totalDeleted}`);
  console.log('════════════════════════════════════════════════════\n');
}

main().catch((err) => {
  console.error('Cleanup failed:', err);
  process.exit(1);
});
