import { onRequest } from "firebase-functions/v2/https";
import { onDocumentUpdated, onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

/**
 * Paymob Webhook — simple acknowledger.
 * The actual wallet crediting is now handled by onPaymentCreated below.
 * This endpoint exists only so Paymob gets a 200 and stops retrying.
 */
export const paymobWebhook = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const receivedHmac = req.query.hmac as string;
  if (receivedHmac) {
    logger.info("Received HMAC:", receivedHmac);
  }

  const transaction = req.body?.obj || req.body;
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
export const onPaymentCreated = onDocumentCreated(
  "Payments/{paymentId}",
  async (event) => {
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
        const sellerRef = db.collection("Users").doc(sellerId);
        const sellerSnap = await t.get(sellerRef);

        if (!sellerSnap.exists) {
          throw new Error(`Seller ${sellerId} does not exist`);
        }

        const currentBalance = sellerSnap.data()?.walletBalance || 0;
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
      const fcmToken = sellerDoc.data()?.fcmToken;
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
    } catch (error) {
      logger.error(`Error crediting seller for payment ${paymentId}:`, error);
    }
  }
);

/**
 * Triggered when a WithdrawalRequest document is updated.
 * Handles the logic of deducting the seller's balance when the admin marks the withdrawal as 'completed'.
 */
export const onWithdrawalStatusChange = onDocumentUpdated(
  "WithdrawalRequests/{requestId}",
  async (event) => {
    if (!event.data) return;
    const newData = event.data.after.data();
    const previousData = event.data.before.data();

    // If status changed to 'completed' from something else
    if (newData.status === "completed" && previousData.status !== "completed") {
      const sellerId = newData.sellerId;
      const amount = newData.amount;

      try {
        await db.runTransaction(async (t) => {
          const sellerRef = db.collection("Users").doc(sellerId);
          const sellerSnap = await t.get(sellerRef);

          if (!sellerSnap.exists) {
            throw new Error(`Seller ${sellerId} does not exist`);
          }

          const currentBalance = sellerSnap.data()?.walletBalance || 0;
          
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
            referenceId: event.data!.after.id,
            description: `Withdrawal completed`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        logger.info(`Successfully deducted ${amount} from seller ${sellerId} for withdrawal`);

        // Notify Seller
        const sellerDoc = await db.collection("Users").doc(sellerId).get();
        const fcmToken = sellerDoc.data()?.fcmToken;
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
      } catch (error) {
        logger.error("Error processing withdrawal completion:", error);
      }
    } 
    // If status changed to 'rejected'
    else if (newData.status === "rejected" && previousData.status !== "rejected") {
        const sellerId = newData.sellerId;
        const sellerDoc = await db.collection("Users").doc(sellerId).get();
        const fcmToken = sellerDoc.data()?.fcmToken;
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
export const onDeliveryCreated = onDocumentCreated(
  "deliveries/{orderId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

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

      const tokens: string[] = [];
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
    } catch (error) {
      logger.error("Error notifying agents of new delivery:", error);
    }
  }
);

/**
 * Triggered when a Delivery is updated.
 * Notifies the user when their delivery status changes.
 */
export const onDeliveryUpdated = onDocumentUpdated(
  "deliveries/{orderId}",
  async (event) => {
    if (!event.data) return;

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

      const fcmToken = userDoc.data()?.fcmToken;
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
    } catch (error) {
      logger.error(`Error notifying user ${userId} of delivery update:`, error);
    }
  }
);

/**
 * Triggered when a Trade status changes to 'completed'.
 * Prompts the users who haven't provided delivery details to do so.
 */
export const onTradeCompleted = onDocumentUpdated(
  "Trades/{tradeId}",
  async (event) => {
    if (!event.data) return;

    const previousData = event.data.before.data();
    const newData = event.data.after.data();
    const tradeId = event.params.tradeId;

    // Trigger only when status changes to 'completed'
    if (newData.status === "completed" && previousData.status !== "completed") {
      const fromUserId = newData.fromUserId;
      const toUserId = newData.toUserId;
      const deliveryProvidedBy: string[] = newData.deliveryProvidedBy || [];

      logger.info(`onTradeCompleted triggered for trade: ${tradeId}`);

      const notifyUser = async (userId: string) => {
        try {
          const userDoc = await db.collection("Users").doc(userId).get();
          const fcmToken = userDoc.data()?.fcmToken;
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
        } catch (err) {
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
  }
);
