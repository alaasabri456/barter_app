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
exports.onTradeCompleted = exports.onDeliveryUpdated = exports.onDeliveryCreated = exports.onWithdrawalStatusChange = exports.onPaymentStatusChanged = exports.paymobWebhook = void 0;
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
 * Firestore trigger — fires whenever a Payment document is **updated**.
 *
 * The Flutter app now follows a two-phase write:
 *   Phase 1 (before gateway): creates the doc with status = 'pending'.
 *   Phase 3 (after gateway):  updates the same doc to status = 'completed'.
 *
 * This function fires on Phase 3 and credits the seller's wallet only when
 * the status transitions from 'pending' → 'completed', preventing any
 * double-crediting even if the trigger fires more than once.
 */
exports.onPaymentStatusChanged = (0, firestore_1.onDocumentUpdated)("Payments/{paymentId}", async (event) => {
    var _a;
    if (!event.data) {
        logger.error("onPaymentStatusChanged: No data in event");
        return;
    }
    const before = event.data.before.data();
    const after = event.data.after.data();
    const paymentId = event.params.paymentId;
    // Guard: only act on the pending → completed transition.
    if (before.status !== "pending" || after.status !== "completed") {
        logger.info(`Payment ${paymentId}: status changed from '${before.status}' to '${after.status}'. No action needed.`);
        return;
    }
    // Guard: idempotency — prevent double-crediting.
    if (after.isCredited === true) {
        logger.info(`Payment ${paymentId} was already credited. Skipping.`);
        return;
    }
    const sellerId = after.sellerId;
    const amount = after.amount;
    const productTitle = after.productTitle || "a product";
    if (!sellerId || !amount) {
        logger.error(`Payment ${paymentId} is missing sellerId or amount.`, after);
        return;
    }
    try {
        // Atomic transaction: credit seller + create wallet record + mark as credited.
        await db.runTransaction(async (t) => {
            var _a;
            const sellerRef = db.collection("Users").doc(sellerId);
            const sellerSnap = await t.get(sellerRef);
            if (!sellerSnap.exists) {
                throw new Error(`Seller ${sellerId} does not exist`);
            }
            const currentBalance = ((_a = sellerSnap.data()) === null || _a === void 0 ? void 0 : _a.walletBalance) || 0;
            const newBalance = currentBalance + amount;
            // Update seller's wallet balance.
            t.update(sellerRef, { walletBalance: newBalance });
            // Create a WalletTransaction record.
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
            // Mark payment as credited (idempotency flag).
            t.update(event.data.after.ref, { isCredited: true });
        });
        logger.info(`Successfully credited ${amount} EGP to seller ${sellerId} for payment ${paymentId}`);
        // Send push notification to seller.
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
/**
 * Triggered when a new Delivery is created.
 * Notifies all delivery agents about the new delivery.
 */
exports.onDeliveryCreated = (0, firestore_1.onDocumentCreated)("deliveries/{orderId}", async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const deliveryData = snap.data();
    const orderId = event.params.orderId;
    const itemName = deliveryData.itemName || "a new item";
    logger.info(`onDeliveryCreated triggered for delivery: ${orderId}`);
    try {
        // Find all users with role 'agent'
        const agentsSnap = await db.collection("Users").where("role", "==", "agent").get();
        if (agentsSnap.empty) {
            logger.info("No agents found to notify.");
            return;
        }
        const tokens = [];
        agentsSnap.forEach(doc => {
            const fcmToken = doc.data().fcmToken;
            if (fcmToken) {
                tokens.push(fcmToken);
            }
        });
        if (tokens.length > 0) {
            await admin.messaging().sendEachForMulticast({
                tokens: tokens,
                notification: {
                    title: "New Delivery Available!",
                    body: `A new delivery for "${itemName}" is pending. Check your dashboard.`,
                },
                data: {
                    type: "new_delivery",
                    orderId: orderId
                }
            });
            logger.info(`Notified ${tokens.length} agents about new delivery ${orderId}`);
        }
    }
    catch (error) {
        logger.error("Error notifying agents of new delivery:", error);
    }
});
/**
 * Triggered when a Delivery is updated.
 * Notifies the user when their delivery status changes.
 */
exports.onDeliveryUpdated = (0, firestore_1.onDocumentUpdated)("deliveries/{orderId}", async (event) => {
    var _a;
    if (!event.data)
        return;
    const previousData = event.data.before.data();
    const newData = event.data.after.data();
    const orderId = event.params.orderId;
    // Only notify if the status has actually changed
    if (previousData.status === newData.status) {
        return;
    }
    const newStatus = newData.status;
    const userId = newData.userId;
    const itemName = newData.itemName || "your item";
    logger.info(`onDeliveryUpdated triggered for delivery: ${orderId}, new status: ${newStatus}`);
    try {
        const userDoc = await db.collection("Users").doc(userId).get();
        if (!userDoc.exists) {
            logger.info(`User ${userId} not found for delivery ${orderId}`);
            return;
        }
        const fcmToken = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
        if (!fcmToken) {
            logger.info(`User ${userId} has no FCM token. Cannot send delivery update.`);
            return;
        }
        let statusMessage = "";
        switch (newStatus) {
            case "picked_up":
                statusMessage = `Your item "${itemName}" has been picked up by the agent.`;
                break;
            case "in_transit":
                statusMessage = `Your item "${itemName}" is currently in transit.`;
                break;
            case "out_for_delivery":
                statusMessage = `Your item "${itemName}" is on its way to you!`;
                break;
            case "delivered":
                statusMessage = `Your item "${itemName}" has been successfully delivered!`;
                break;
            default:
                statusMessage = `Your delivery for "${itemName}" has an updated status: ${newStatus}`;
        }
        await admin.messaging().send({
            token: fcmToken,
            notification: {
                title: "Delivery Update",
                body: statusMessage,
            },
            data: {
                type: "delivery_update",
                orderId: orderId,
                status: newStatus
            }
        });
        logger.info(`Notified user ${userId} about delivery ${orderId} status change to ${newStatus}`);
    }
    catch (error) {
        logger.error(`Error notifying user ${userId} of delivery update:`, error);
    }
});
/**
 * Triggered when a Trade status changes to 'completed'.
 * Prompts the users who haven't provided delivery details to do so.
 */
exports.onTradeCompleted = (0, firestore_1.onDocumentUpdated)("Trades/{tradeId}", async (event) => {
    if (!event.data)
        return;
    const previousData = event.data.before.data();
    const newData = event.data.after.data();
    const tradeId = event.params.tradeId;
    // Trigger only when status changes to 'completed'
    if (newData.status === "completed" && previousData.status !== "completed") {
        const fromUserId = newData.fromUserId;
        const toUserId = newData.toUserId;
        const deliveryProvidedBy = newData.deliveryProvidedBy || [];
        logger.info(`onTradeCompleted triggered for trade: ${tradeId}`);
        const notifyUser = async (userId) => {
            var _a;
            try {
                const userDoc = await db.collection("Users").doc(userId).get();
                const fcmToken = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
                if (fcmToken) {
                    await admin.messaging().send({
                        token: fcmToken,
                        notification: {
                            title: "Trade Completed!",
                            body: "Your trade swap is complete. Please provide your delivery details to receive your items.",
                        },
                        data: {
                            type: "trade_delivery_pending",
                            tradeId: tradeId,
                        }
                    });
                    logger.info(`Notified user ${userId} to provide delivery details for trade ${tradeId}`);
                }
            }
            catch (err) {
                logger.error(`Error notifying user ${userId} for completed trade:`, err);
            }
        };
        // Notify the user who hasn't provided delivery details yet
        if (!deliveryProvidedBy.includes(fromUserId)) {
            await notifyUser(fromUserId);
        }
        if (!deliveryProvidedBy.includes(toUserId)) {
            await notifyUser(toUserId);
        }
    }
});
//# sourceMappingURL=index.js.map