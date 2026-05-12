"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.onWithdrawalStatusChange = exports.onPaymentCreated = exports.paymobWebhook = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-functions/v2/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
/**
 * Paymob Webhook — simple acknowledger.
 * The actual wallet crediting is now handled by onPaymentCreated below.
 * This endpoint exists only so Paymob gets a 200 and stops retrying.
 */
exports.paymobWebhook = (0, https_1.onRequest)(async (req, res) => {
    var _a;
    if (req.method !== "POST") {
        res.status(405).send("Method Not Allowed");
        return;
    }
    const receivedHmac = req.query.hmac;
    if (receivedHmac) {
        logger.info("Received HMAC:", receivedHmac);
    }
    const transaction = ((_a = req.body) === null || _a === void 0 ? void 0 : _a.obj) || req.body;
    if (!transaction) {
        res.status(400).send("Invalid payload");
        return;
    }
    logger.info("Paymob webhook received", {
        transactionId: transaction.id,
        success: transaction.success,
    });
    // Always return 200 — wallet crediting is handled by onPaymentCreated trigger
    res.status(200).send("OK");
});
/**
 * ✅ NEW: Firestore trigger — fires whenever a Payment document is created.
 * This completely eliminates the race condition because:
 *   1. The Flutter app saves the Payment doc to Firestore.
 *   2. This trigger fires immediately with all the data already in the document.
 *   3. No need to query or match transactionIds.
 */
exports.onPaymentCreated = (0, firestore_1.onDocumentCreated)("Payments/{paymentId}", async (event) => {
    var _a;
    const snap = event.data;
    if (!snap) {
        logger.error("onPaymentCreated: No data in event");
        return;
    }
    const paymentData = snap.data();
    const paymentId = event.params.paymentId;
    logger.info(`onPaymentCreated triggered for payment: ${paymentId}`);
    // Only process completed payments
    if (paymentData.status !== "completed") {
        logger.info(`Payment ${paymentId} status is '${paymentData.status}', skipping.`);
        return;
    }
    // Check idempotency (prevent double crediting)
    if (paymentData.isCredited === true) {
        logger.info(`Payment ${paymentId} was already credited. Skipping.`);
        return;
    }
    const sellerId = paymentData.sellerId;
    const amount = paymentData.amount;
    const productTitle = paymentData.productTitle || "a product";
    if (!sellerId || !amount) {
        logger.error(`Payment ${paymentId} is missing sellerId or amount.`, paymentData);
        return;
    }
    try {
        // Atomic transaction: credit seller + create wallet record + mark as credited
        await db.runTransaction(async (t) => {
            var _a;
            const sellerRef = db.collection("Users").doc(sellerId);
            const sellerSnap = await t.get(sellerRef);
            if (!sellerSnap.exists) {
                throw new Error(`Seller ${sellerId} does not exist`);
            }
            const currentBalance = ((_a = sellerSnap.data()) === null || _a === void 0 ? void 0 : _a.walletBalance) || 0;
            const newBalance = currentBalance + amount;
            // Update seller's wallet balance
            t.update(sellerRef, { walletBalance: newBalance });
            // Create a WalletTransaction record
            const walletTxRef = db.collection("WalletTransactions").doc();
            t.set(walletTxRef, {
                id: walletTxRef.id,
                userId: sellerId,
                amount: amount,
                type: "credit",
                referenceId: paymentId,
                description: `Payment received for ${productTitle}`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // Mark payment as credited (idempotency flag)
            t.update(snap.ref, { isCredited: true });
        });
        logger.info(`Successfully credited ${amount} EGP to seller ${sellerId} for payment ${paymentId}`);
        // Send push notification to seller
        const sellerDoc = await db.collection("Users").doc(sellerId).get();
        const fcmToken = (_a = sellerDoc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
        if (fcmToken) {
            await admin.messaging().send({
                token: fcmToken,
                notification: {
                    title: "Payment Received!",
                    body: `You received ${amount} EGP for your product "${productTitle}".`,
                },
                data: {
                    type: "wallet_update",
                },
            });
            logger.info(`Push notification sent to seller ${sellerId}`);
        }
    }
    catch (error) {
        logger.error(`Error crediting seller for payment ${paymentId}:`, error);
    }
});
/**
 * Triggered when a WithdrawalRequest document is updated.
 * Handles the logic of deducting the seller's balance when the admin marks the withdrawal as 'completed'.
 */
exports.onWithdrawalStatusChange = (0, firestore_1.onDocumentUpdated)("WithdrawalRequests/{requestId}", async (event) => {
    var _a, _b;
    if (!event.data)
        return;
    const newData = event.data.after.data();
    const previousData = event.data.before.data();
    // If status changed to 'completed' from something else
    if (newData.status === "completed" && previousData.status !== "completed") {
        const sellerId = newData.sellerId;
        const amount = newData.amount;
        try {
            await db.runTransaction(async (t) => {
                var _a;
                const sellerRef = db.collection("Users").doc(sellerId);
                const sellerSnap = await t.get(sellerRef);
                if (!sellerSnap.exists) {
                    throw new Error(`Seller ${sellerId} does not exist`);
                }
                const currentBalance = ((_a = sellerSnap.data()) === null || _a === void 0 ? void 0 : _a.walletBalance) || 0;
                if (currentBalance < amount) {
                    throw new Error(`Insufficient balance. Has ${currentBalance}, trying to withdraw ${amount}`);
                }
                const newBalance = currentBalance - amount;
                // Update seller's balance
                t.update(sellerRef, { walletBalance: newBalance });
                // Create a WalletTransaction record
                const walletTxRef = db.collection("WalletTransactions").doc();
                t.set(walletTxRef, {
                    id: walletTxRef.id,
                    userId: sellerId,
                    amount: amount,
                    type: "debit",
                    referenceId: event.data.after.id,
                    description: `Withdrawal completed`,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            });
            logger.info(`Successfully deducted ${amount} from seller ${sellerId} for withdrawal`);
            // Notify Seller
            const sellerDoc = await db.collection("Users").doc(sellerId).get();
            const fcmToken = (_a = sellerDoc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
            if (fcmToken) {
                await admin.messaging().send({
                    token: fcmToken,
                    notification: {
                        title: "Withdrawal Completed",
                        body: `Your withdrawal of ${amount} EGP has been processed and transferred to your bank.`,
                    },
                    data: {
                        type: "wallet_update",
                    }
                });
            }
        }
        catch (error) {
            logger.error("Error processing withdrawal completion:", error);
        }
    }
    // If status changed to 'rejected'
    else if (newData.status === "rejected" && previousData.status !== "rejected") {
        const sellerId = newData.sellerId;
        const sellerDoc = await db.collection("Users").doc(sellerId).get();
        const fcmToken = (_b = sellerDoc.data()) === null || _b === void 0 ? void 0 : _b.fcmToken;
        if (fcmToken) {
            await admin.messaging().send({
                token: fcmToken,
                notification: {
                    title: "Withdrawal Rejected",
                    body: `Your withdrawal request of ${newData.amount} EGP was rejected.`,
                },
                data: {
                    type: "wallet_update",
                }
            });
        }
    }
});
//# sourceMappingURL=index.js.map