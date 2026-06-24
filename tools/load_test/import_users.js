/**
 * import_users.js
 * Pre-creates 300 Firebase Auth users (150 VU pairs: lt_vu_N_a + lt_vu_N_b)
 * using `firebase auth:import` (bypasses the 100 signups/hour/IP rate limit).
 *
 * Run ONCE before the full load test:
 *   node tools/load_test/import_users.js
 *
 * Password for all users: password123
 * Hash algorithm: HMAC_SHA256 (key: "load-test-key")
 */

const fs   = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const crypto = require('crypto');

const PROJECT_ID = 'barter-30a05';
const PASSWORD   = 'password123';
const HMAC_KEY   = 'load-test-key';     // arbitrary HMAC key we supply to Firebase
const VU_COUNT   = 150;

// HMAC-SHA256 of password, base64-encoded (Firebase expects base64 passwordHash)
function hmacSha256(key, data) {
  return crypto.createHmac('sha256', key).update(data).digest('base64');
}

const passwordHash = hmacSha256(HMAC_KEY, PASSWORD);

console.log('Generating users JSON...');
const users = [];
for (let vu = 1; vu <= VU_COUNT; vu++) {
  for (const suffix of ['a', 'b']) {
    users.push({
      localId:      `lt_vu_${vu}_${suffix}`,
      email:        `lt_vu_${vu}_${suffix}@example.com`,
      passwordHash: passwordHash,
      emailVerified: true
    });
  }
}

const exportData = { users };
const jsonPath   = path.join(__dirname, 'precreated_users.json');
fs.writeFileSync(jsonPath, JSON.stringify(exportData, null, 2), 'utf8');
console.log(`  ✅ Wrote ${users.length} users to ${jsonPath}`);

// Firebase auth:import expects the HMAC key as base64
const keyBase64 = Buffer.from(HMAC_KEY).toString('base64');

const cmd = [
  'npx firebase auth:import',
  `"${jsonPath}"`,
  '--hash-algo=HMAC_SHA256',
  `--hash-key="${keyBase64}"`,
  `--project ${PROJECT_ID}`,
].join(' ');

console.log(`\nImporting into Firebase Auth (project: ${PROJECT_ID})...`);
console.log(`  ${cmd}\n`);

try {
  execSync(cmd, { stdio: 'inherit', cwd: path.join(__dirname, '../..') });
  console.log(`\n✅ Successfully imported ${users.length} load-test users!`);
  console.log('   You can now run the full load test.');
} catch (err) {
  console.error('\n❌ Import failed:', err.message);
  process.exit(1);
}
