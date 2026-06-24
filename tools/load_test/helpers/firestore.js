/**
 * helpers/firestore.js
 * Firestore REST API wrapper for k6 load tests.
 *
 * All requests use the authenticated user's Firebase ID token,
 * meaning Firestore Security Rules are enforced exactly as in production.
 *
 * Firestore REST reference:
 *   https://firebase.google.com/docs/firestore/reference/rest
 */

import http from 'k6/http';
import { check } from 'k6';

const PROJECT_ID = __ENV.FIREBASE_PROJECT_ID || 'barter-30a05';
const FS_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// ─── Value conversion ──────────────────────────────────────────────────────

/**
 * Convert a plain JS value to a Firestore REST "Value" object.
 */
function toValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    return Number.isInteger(val)
      ? { integerValue: String(val) }
      : { doubleValue: val };
  }
  if (typeof val === 'string') return { stringValue: val };
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(toValue) } };
  }
  if (typeof val === 'object') {
    return { mapValue: { fields: toFields(val) } };
  }
  return { stringValue: String(val) };
}

/**
 * Convert a plain JS object to a Firestore "fields" map.
 */
function toFields(obj) {
  const fields = {};
  for (const key of Object.keys(obj)) {
    fields[key] = toValue(obj[key]);
  }
  return fields;
}

/**
 * Parse a Firestore "Value" object back to a plain JS value.
 */
function fromValue(val) {
  if ('nullValue'    in val) return null;
  if ('booleanValue' in val) return val.booleanValue;
  if ('integerValue' in val) return parseInt(val.integerValue, 10);
  if ('doubleValue'  in val) return val.doubleValue;
  if ('stringValue'  in val) return val.stringValue;
  if ('arrayValue'   in val) {
    return (val.arrayValue.values || []).map(fromValue);
  }
  if ('mapValue' in val) {
    return fromFields(val.mapValue.fields || {});
  }
  return null;
}

/**
 * Parse a Firestore "fields" map back to a plain JS object.
 */
function fromFields(fields) {
  const obj = {};
  for (const key of Object.keys(fields)) {
    obj[key] = fromValue(fields[key]);
  }
  return obj;
}

// ─── Auth headers helper ───────────────────────────────────────────────────

function authHeaders(idToken) {
  return {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${idToken}`,
  };
}

// ─── CRUD operations ───────────────────────────────────────────────────────

/**
 * Read a single Firestore document.
 * @param {string} collection  e.g. 'Products'
 * @param {string} docId
 * @param {string} idToken
 * @returns {object|null}  parsed document data, or null on error
 */
export function firestoreGet(collection, docId, idToken) {
  const url = `${FS_BASE}/${collection}/${docId}`;
  const res = http.get(url, {
    headers: authHeaders(idToken),
    tags: { name: `firestore/get/${collection}` },
  });

  check(res, { [`firestoreGet ${collection}: 200`]: (r) => r.status === 200 });

  if (res.status !== 200) return null;
  const doc = JSON.parse(res.body);
  return doc.fields ? fromFields(doc.fields) : null;
}

/**
 * Create or overwrite a Firestore document (PUT = full write).
 * @param {string} collection
 * @param {string} docId
 * @param {object} data     plain JS object
 * @param {string} idToken
 * @returns {boolean}
 */
export function firestoreSet(collection, docId, data, idToken) {
  const url = `${FS_BASE}/${collection}/${docId}`;
  const body = JSON.stringify({ fields: toFields(data) });
  const res = http.request('PATCH', url, body, {
    headers: authHeaders(idToken),
    tags: { name: `firestore/set/${collection}` },
  });

  const ok = res.status === 200;
  if (!ok) {
    console.warn(`[firestoreSet] ${collection}/${docId} → HTTP ${res.status}: ${res.body}`);
  }
  return check(res, { [`firestoreSet ${collection}: 200`]: (r) => r.status === 200 });
}

/**
 * Partial-update a Firestore document (only the listed fields).
 * @param {string} collection
 * @param {string} docId
 * @param {object} data           partial data
 * @param {string[]} updateMask   list of field names to update
 * @param {string} idToken
 * @returns {boolean}
 */
export function firestoreUpdate(collection, docId, data, updateMask, idToken) {
  const maskParams = updateMask.map((f) => `updateMask.fieldPaths=${encodeURIComponent(f)}`).join('&');
  const url = `${FS_BASE}/${collection}/${docId}?${maskParams}`;
  const body = JSON.stringify({ fields: toFields(data) });
  const res = http.request('PATCH', url, body, {
    headers: authHeaders(idToken),
    tags: { name: `firestore/update/${collection}` },
  });

  return check(res, { [`firestoreUpdate ${collection}: 200`]: (r) => r.status === 200 });
}

/**
 * Delete a Firestore document.
 * @param {string} collection
 * @param {string} docId
 * @param {string} idToken
 * @returns {boolean}
 */
export function firestoreDelete(collection, docId, idToken) {
  const url = `${FS_BASE}/${collection}/${docId}`;
  const res = http.request('DELETE', url, null, {
    headers: authHeaders(idToken),
    tags: { name: `firestore/delete/${collection}` },
  });
  // 200 = deleted, 404 = already gone — both are fine for cleanup
  return res.status === 200 || res.status === 404;
}

/**
 * Run a structured query against Firestore.
 * @param {string} collection
 * @param {Array<{field: string, op: string, value: any}>} filters
 * @param {string} idToken
 * @param {number} [limit=20]
 * @returns {object[]}  array of parsed document data
 */
export function firestoreQuery(collection, filters, idToken, limit = 20) {
  const url = `${FS_BASE}:runQuery`;

  const where = filters.length === 1
    ? {
        fieldFilter: {
          field: { fieldPath: filters[0].field },
          op: filters[0].op,
          value: toValue(filters[0].value),
        },
      }
    : {
        compositeFilter: {
          op: 'AND',
          filters: filters.map((f) => ({
            fieldFilter: {
              field: { fieldPath: f.field },
              op: f.op,
              value: toValue(f.value),
            },
          })),
        },
      };

  const body = JSON.stringify({
    structuredQuery: {
      from: [{ collectionId: collection }],
      where,
      limit,
    },
  });

  const res = http.post(url, body, {
    headers: authHeaders(idToken),
    tags: { name: `firestore/query/${collection}` },
  });

  check(res, { [`firestoreQuery ${collection}: 200`]: (r) => r.status === 200 });

  if (res.status !== 200) return [];
  const rows = JSON.parse(res.body);
  return rows
    .filter((row) => row.document && row.document.fields)
    .map((row) => fromFields(row.document.fields));
}

/**
 * List documents in a collection (simple paginated list, no filter).
 * @param {string} collection
 * @param {string} idToken
 * @param {number} [pageSize=20]
 * @returns {object[]}
 */
export function firestoreList(collection, idToken, pageSize = 20) {
  const url = `${FS_BASE}/${collection}?pageSize=${pageSize}`;
  const res = http.get(url, {
    headers: authHeaders(idToken),
    tags: { name: `firestore/list/${collection}` },
  });

  check(res, { [`firestoreList ${collection}: 200`]: (r) => r.status === 200 });

  if (res.status !== 200) return [];
  const body = JSON.parse(res.body);
  return (body.documents || [])
    .filter((doc) => doc.fields)
    .map((doc) => fromFields(doc.fields));
}
