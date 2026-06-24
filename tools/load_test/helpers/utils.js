/**
 * helpers/utils.js
 * Random data generators and shared utilities for k6 load tests.
 *
 * All load-test emails are prefixed with "lt_" so cleanup scripts
 * can identify and delete them without touching real user data.
 */

import { uuidv4 } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';

/** Generate a unique load-test user */
export function randomUser() {
  const id = uuidv4().replace(/-/g, '').substring(0, 12);
  return {
    email: `lt_${id}@test.barter.load`,
    password: `LT_Pass_${id}!`,
    name: `LoadUser_${id}`,
  };
}

const CATEGORIES = ['Electronics', 'Books', 'Clothing', 'Sports', 'Home', 'Toys'];
const CONDITIONS = ['new', 'like_new', 'good', 'fair'];
const LOCATIONS  = ['Cairo', 'Alexandria', 'Giza', 'Mansoura', 'Luxor'];

/** Generate a valid product payload matching productFields() in Firestore rules */
export function randomProduct(ownerId, ownerName) {
  const id  = uuidv4();
  const cat = CATEGORIES[Math.floor(Math.random() * CATEGORIES.length)];
  const cond = CONDITIONS[Math.floor(Math.random() * CONDITIONS.length)];
  const loc  = LOCATIONS[Math.floor(Math.random() * LOCATIONS.length)];
  return {
    id,
    title: `LT Product ${id.substring(0, 8)}`,
    description: `Load test product — auto-generated. Category: ${cat}.`,
    category: cat,
    condition: cond,
    ownerId,
    ownerName,
    images: [],
    isAvailable: true,
    tags: ['load_test', cat.toLowerCase()],
    location: loc,
    latitude: 30.0 + Math.random() * 2,
    longitude: 31.0 + Math.random() * 2,
    status: 'available',
    viewCount: 0,
    interestedUsers: [],
    viewedUserIds: [],
    reportedByUserIds: [],
    transactionType: 'swap',
    needsReview: false,
    reviewStatus: 'approved',
  };
}

/** Generate a valid trade payload */
export function randomTrade(fromUserId, fromUserName, toUserId, toUserName, offeredProductId, requestedProductId) {
  return {
    id: uuidv4(),
    fromUserId,
    fromUserName,
    toUserId,
    toUserName,
    offeredProductIds: [offeredProductId],
    requestedProductIds: [requestedProductId],
    message: `Load test trade offer — ${new Date().toISOString()}`,
    status: 'pending',
    type: 'swap',
    isCounterOffer: false,
    isFromPremium: false,
    hasUnreadMessages: false,
    counterOffers: [],
    deliveryProvidedBy: [],
  };
}

/** Generate a conversation ID in the format the app uses */
export function conversationId(uid1, uid2) {
  const sorted = [uid1, uid2].sort();
  return `conversation_${sorted[0]}_${sorted[1]}`;
}

/** Generate a chat message payload */
export function randomMessage(senderId, convId) {
  return {
    id: uuidv4(),
    conversationId: convId,
    senderId,
    text: `Load test message ${Date.now()}`,
    isRead: false,
  };
}

/** Sleep between min and max milliseconds (as k6 sleep takes seconds) */
export function randSleep(minMs, maxMs) {
  return (minMs + Math.random() * (maxMs - minMs)) / 1000;
}

/** Pick a random item from an array */
export function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}
