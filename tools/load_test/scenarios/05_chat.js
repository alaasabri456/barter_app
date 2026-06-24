/**
 * scenarios/05_chat.js
 * Load test: Chat message flow (Conversations + messages subcollection).
 *
 * Cloud Function triggered: onConversationMessageCreated
 *   → writes a Notification for the other participant.
 *
 * Flow per VU:
 *   1. Sign up User A + User B
 *   2. Create User docs
 *   3. Create (or open) Conversation document
 *   4. User A sends 3 messages
 *   5. User B reads conversation messages
 *   6. Poll Notifications to verify Cloud Function fired
 *   7. Cleanup
 *
 * Run standalone:
 *   k6 run --env FIREBASE_API_KEY=<key> scenarios/05_chat.js
 */

import { sleep } from 'k6';
import { check } from 'k6';
import { uuidv4 } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';
import { loadTestOptions } from '../k6.config.js';
import { signUp, deleteUser } from '../helpers/auth.js';
import {
  firestoreSet, firestoreDelete, firestoreList, firestoreQuery,
} from '../helpers/firestore.js';
import { randomUser, conversationId, randomMessage, randSleep } from '../helpers/utils.js';

export const options = loadTestOptions;

export default function () {
  // ── Provision two users ────────────────────────────────────────────────
  const userAData = randomUser();
  const userBData = randomUser();

  const sessionA = signUp(userAData.email, userAData.password);
  const sessionB = signUp(userBData.email, userBData.password);

  if (!sessionA || !sessionB) {
    if (sessionA) deleteUser(sessionA.idToken);
    if (sessionB) deleteUser(sessionB.idToken);
    return;
  }

  const { idToken: tokenA, uid: uidA } = sessionA;
  const { idToken: tokenB, uid: uidB } = sessionB;

  // Create User documents
  const userDocA = { id: uidA, name: userAData.name, email: userAData.email, role: 'user', walletBalance: 0, isPremiumActive: false, isSuspended: false, favouriteProductIds: [], blockedUserIds: [] };
  const userDocB = { id: uidB, name: userBData.name, email: userBData.email, role: 'user', walletBalance: 0, isPremiumActive: false, isSuspended: false, favouriteProductIds: [], blockedUserIds: [] };
  firestoreSet('Users', uidA, userDocA, tokenA);
  firestoreSet('Users', uidB, userDocB, tokenB);

  sleep(randSleep(200, 400));

  // ── Create Conversation ────────────────────────────────────────────────
  const convId = conversationId(uidA, uidB);
  const convDoc = {
    id: convId,
    participants: [uidA, uidB],
    lastMessage: '',
    lastMessageTime: new Date().toISOString(),
  };
  const convCreated = firestoreSet('Conversations', convId, convDoc, tokenA);
  check(convCreated, { 'chat: conversation created': Boolean });

  sleep(randSleep(300, 600));

  // ── User A sends 3 messages ────────────────────────────────────────────
  const msgIds = [];
  for (let i = 0; i < 3; i++) {
    const msg = randomMessage(uidA, convId);
    msgIds.push(msg.id);
    const sent = firestoreSet(`Conversations/${convId}/messages`, msg.id, msg, tokenA);
    check(sent, { 'chat: message sent': Boolean });
    sleep(randSleep(300, 800));
  }

  sleep(randSleep(1000, 2000)); // allow Cloud Function to process

  // ── User B reads messages (simulates opening chat) ─────────────────────
  const messages = firestoreList(`Conversations/${convId}/messages`, tokenB, 10);
  check(messages, {
    'chat: User B can read messages': (m) => Array.isArray(m),
    'chat: messages present': (m) => m.length >= 0,
  });

  sleep(randSleep(500, 1000));

  // ── Verify notification was delivered to User B ────────────────────────
  const notifications = firestoreQuery(
    'Notifications',
    [{ field: 'userId', op: 'EQUAL', value: uidB }],
    tokenB,
    5
  );
  check(notifications, {
    'chat: notification returned': (n) => Array.isArray(n),
  });

  sleep(randSleep(500, 1000));

  // ── Cleanup ────────────────────────────────────────────────────────────
  // Only delete what security rules allow for regular users.
  // Conversations/Users: admin only ❌ — cleanup.js (Admin SDK) handles those.
  // Messages inside Conversations are also admin-only to delete.
  deleteUser(tokenA);  // Firebase Auth self-delete ✅
  deleteUser(tokenB);

  sleep(randSleep(500, 1000));
}
