import { onRequest } from "firebase-functions/v2/https";
import { onDocumentUpdated, onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// ─── Localized notification strings (mirrors Dart localizedNotificationStrings) ──

const localizedStrings: Record<string, Record<string, string>> = {
  en: {
    newOfferTitle: "New Trade Offer",
    newOfferBody: "{sender} sent you a trade offer.",
    counterOfferTitle: "New Counter Offer",
    counterOfferBody: "{sender} sent a counter offer.",
    tradeAcceptedTitle: "Trade Accepted!",
    tradeAcceptedBody: "Your trade offer has been accepted!",
    tradeRejectedTitle: "Trade Rejected",
    tradeRejectedBody: "Your trade offer was rejected.",
    tradeAutoRejectedBody:
      "Your offer was cancelled because the item is no longer available.",
    tradeCompletedTitle: "Trade Completed!",
    tradeCompletedBody: "The trade has been confirmed as completed.",
    newMessageTitle: "New Message",
    newMessageBody: "{sender}: {message}",
    newReviewTitle: "New Review received",
    newReviewBody: "{sender} left you a review: {rating}⭐",
    newReportTitle: "New Report Submitted",
    newReportBody: 'A new report was submitted for "{product}" by {reporter}.',
    productUpdatedTitle: "Product Updated",
    productUpdatedBody:
      'The item "{product}" in your pending trade has been updated.',
  },
  ar: {
    newOfferTitle: "عرض مبادلة جديد",
    newOfferBody: "أرسل لك {sender} عرض مبادلة.",
    counterOfferTitle: "عرض مقابل جديد",
    counterOfferBody: "أرسل {sender} عرضاً مقابلاً.",
    tradeAcceptedTitle: "تم قبول المبادلة!",
    tradeAcceptedBody: "تم قبول عرض المبادلة الخاص بك!",
    tradeRejectedTitle: "تم رفض المبادلة",
    tradeRejectedBody: "تم رفض عرض المبادلة الخاص بك.",
    tradeAutoRejectedBody: "تم إلغاء عرضك لأن السلعة لم تعد متوفرة.",
    tradeCompletedTitle: "اكتملت المبادلة!",
    tradeCompletedBody: "تم تأكيد اكتمال المبادلة.",
    newMessageTitle: "رسالة جديدة",
    newMessageBody: "{sender}: {message}",
    newReviewTitle: "تم استلام تقييم جديد",
    newReviewBody: "ترك لك {sender} تقييمًا: {rating}⭐",
    newReportTitle: "تم تقديم بلاغ جديد",
    newReportBody: 'تم تقديم بلاغ جديد عن "{product}" بواسطة {reporter}.',
    productUpdatedTitle: "تم تحديث المنتج",
    productUpdatedBody: 'تم تحديث العنصر "{product}" في صفقتك المعلقة.',
  },
};

// ─── Shared helper ────────────────────────────────────────────────────────────

/**
 * Resolve a localized string pair for a given recipient, replacing
 * any {placeholder} tokens with the provided args.
 */
async function resolveLocalizedStrings(
  recipientId: string,
  titleKey: string,
  bodyKey: string,
  args?: Record<string, string>
): Promise<{ title: string; body: string }> {
  let lang = "en";
  try {
    const userSnap = await db.collection("Users").doc(recipientId).get();
    const userLang = userSnap.data()?.languageCode as string | undefined;
    if (userLang && localizedStrings[userLang]) lang = userLang;
  } catch {
    // fall back to English
  }

  const strings = localizedStrings[lang] ?? localizedStrings["en"];
  let title = strings[titleKey] ?? localizedStrings["en"][titleKey] ?? titleKey;
  let body = strings[bodyKey] ?? localizedStrings["en"][bodyKey] ?? bodyKey;

  if (args) {
    for (const [key, value] of Object.entries(args)) {
      const pattern = new RegExp(`\\{${key}\\}`, "g");
      title = title.replace(pattern, value);
      body = body.replace(pattern, value);
    }
  }

  return { title, body };
}

/**
 * Write a single in-app Notification document to Firestore on behalf of a
 * server-side trigger. The document schema matches NotificationModel.toJson().
 */
async function createInAppNotification(params: {
  userId: string;
  title: string;
  body: string;
  type: string;
  relatedId?: string;
}): Promise<void> {
  const notifRef = db.collection("Notifications").doc();
  await notifRef.set({
    id: notifRef.id,
    userId: params.userId,
    title: params.title,
    body: params.body,
    type: params.type,
    relatedId: params.relatedId ?? null,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// ─── Trade triggers ───────────────────────────────────────────────────────────

/**
 * Fires when a new Trade document is created.
 * Sends a "new offer" or "counter offer" in-app notification to toUserId.
 */
export const onTradeCreated = onDocumentCreated(
  "Trades/{tradeId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const trade = snap.data();
    const tradeId = event.params.tradeId;
    const isCounterOffer = trade.isCounterOffer === true;

    const recipientId: string = trade.toUserId;
    const senderName: string = trade.fromUserName ?? "Someone";

    const titleKey = isCounterOffer ? "counterOfferTitle" : "newOfferTitle";
    const bodyKey = isCounterOffer ? "counterOfferBody" : "newOfferBody";

    try {
      const { title, body } = await resolveLocalizedStrings(
        recipientId,
        titleKey,
        bodyKey,
        { sender: senderName }
      );

      await createInAppNotification({
        userId: recipientId,
        title,
        body,
        type: "tradeUpdate",
        relatedId: tradeId,
      });

      logger.info(
        `onTradeCreated: notified ${recipientId} of ${isCounterOffer ? "counter offer" : "new offer"} for trade ${tradeId}`
      );
    } catch (err) {
      logger.error(`onTradeCreated: error for trade ${tradeId}`, err);
    }
  }
);

/**
 * Fires when a Trade document is updated.
 * Handles status transitions: accepted, rejected, completed, and auto-rejected
 * (identified by rejectionReason containing "no longer available").
 */
export const onTradeStatusChanged = onDocumentUpdated(
  "Trades/{tradeId}",
  async (event) => {
    if (!event.data) return;

    const before = event.data.before.data();
    const after = event.data.after.data();
    const tradeId = event.params.tradeId;

    // Only act when status has changed
    if (before.status === after.status) return;

    const newStatus: string = after.status;
    const relevantStatuses = ["accepted", "rejected", "cancelled", "completed", "expired"];
    if (!relevantStatuses.includes(newStatus)) return;

    // The "acting" user is derived from updatedAt context; we notify the other participant.
    // We don't know which side acted, so we notify both and let the client filter by userId.
    // Actually: follow the Dart pattern — the notification recipient is the OTHER participant.
    // Since we don't know who acted, we send to BOTH participants and each only sees their own
    // notification via `where('userId', isEqualTo: uid)` on the client.
    // But to keep parity with Dart (one notification, to the other side), we check
    // lastMessageSenderId or use fromUserId as the actor for status changes.
    // Simplest correct approach: always notify BOTH participants. Each reads only their own docs.

    const fromUserId: string = after.fromUserId;
    const toUserId: string = after.toUserId;

    let titleKey: string;
    let bodyKey: string;
    const isAutoRejected =
      newStatus === "rejected" &&
      typeof after.rejectionReason === "string" &&
      after.rejectionReason.toLowerCase().includes("no longer available");

    if (newStatus === "accepted") {
      titleKey = "tradeAcceptedTitle";
      bodyKey = "tradeAcceptedBody";
    } else if (newStatus === "completed") {
      titleKey = "tradeCompletedTitle";
      bodyKey = "tradeCompletedBody";
    } else if (isAutoRejected) {
      titleKey = "tradeRejectedTitle";
      bodyKey = "tradeAutoRejectedBody";
    } else {
      // rejected / cancelled / expired
      titleKey = "tradeRejectedTitle";
      bodyKey = "tradeRejectedBody";
    }

    // For accepted/completed/rejected: Dart notified the "other" participant.
    // For auto-rejected: Dart notified fromUserId (the one who made the offer).
    const recipientIds: string[] = isAutoRejected
      ? [fromUserId]
      : [fromUserId, toUserId]; // send to both; each user only reads their own notifications

    try {
      for (const recipientId of recipientIds) {
        const { title, body } = await resolveLocalizedStrings(
          recipientId,
          titleKey,
          bodyKey
        );

        await createInAppNotification({
          userId: recipientId,
          title,
          body,
          type: "tradeUpdate",
          relatedId: tradeId,
        });
      }

      logger.info(
        `onTradeStatusChanged: trade ${tradeId} status → ${newStatus}, notified: ${recipientIds.join(", ")}`
      );
    } catch (err) {
      logger.error(`onTradeStatusChanged: error for trade ${tradeId}`, err);
    }
  }
);

// ─── Chat trigger ─────────────────────────────────────────────────────────────

/**
 * Fires when a message is created in a Conversation's messages subcollection.
 * Sends a "new message" in-app notification to the other participant.
 * The conversationId follows the format: conversation_<uid1>_<uid2>
 */
export const onConversationMessageCreated = onDocumentCreated(
  "Conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const message = snap.data();
    const conversationId: string = event.params.conversationId;
    const senderId: string = message.senderId;

    // Read the Conversation document to get the participants array reliably.
    // (The conversationId format "conversation_uid1_uid2" is an implementation
    // detail; reading participants from Firestore is more robust.)
    try {
      const convSnap = await db.collection("Conversations").doc(conversationId).get();
      if (!convSnap.exists) return;

      const participants: string[] = convSnap.data()?.participants ?? [];
      const recipientId = participants.find((uid) => uid !== senderId);
      if (!recipientId) return;

      // Resolve sender's name from Users collection
      let senderName = "Someone";
      try {
        const senderSnap = await db.collection("Users").doc(senderId).get();
        senderName = senderSnap.data()?.name ?? "Someone";
      } catch {
        // use default
      }

      const messageText: string =
        message.imageUrl ? "📷 Photo" : (message.text ?? "");

      const { title, body } = await resolveLocalizedStrings(
        recipientId,
        "newMessageTitle",
        "newMessageBody",
        { sender: senderName, message: messageText }
      );

      await createInAppNotification({
        userId: recipientId,
        title,
        body,
        type: "chatMessage",
        relatedId: conversationId,
      });

      logger.info(
        `onConversationMessageCreated: notified ${recipientId} of message in conversation ${conversationId}`
      );
    } catch (err) {
      logger.error(
        `onConversationMessageCreated: error for conversation ${conversationId}`,
        err
      );
    }
  }
);

// ─── Review trigger ───────────────────────────────────────────────────────────

/**
 * Fires when a new review document is created.
 * Sends a "new review" in-app notification to the reviewed user (targetUserId).
 */
export const onReviewCreated = onDocumentCreated(
  "reviews/{reviewId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const review = snap.data();
    const reviewId = event.params.reviewId;
    const recipientId: string = review.targetUserId;
    const reviewerName: string = review.reviewerName ?? "Someone";
    const rating: string = String(review.rating ?? "");

    try {
      const { title, body } = await resolveLocalizedStrings(
        recipientId,
        "newReviewTitle",
        "newReviewBody",
        { sender: reviewerName, rating }
      );

      await createInAppNotification({
        userId: recipientId,
        title,
        body,
        type: "system",
        relatedId: reviewId,
      });

      logger.info(
        `onReviewCreated: notified ${recipientId} of new review ${reviewId}`
      );
    } catch (err) {
      logger.error(`onReviewCreated: error for review ${reviewId}`, err);
    }
  }
);

// ─── Report trigger ───────────────────────────────────────────────────────────

/**
 * Fires when a new Report document is created.
 * Sends a "new report" in-app notification to every user with role == 'admin'.
 */
export const onReportCreated = onDocumentCreated(
  "Reports/{reportId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const report = snap.data();
    const reportId = event.params.reportId;
    const reporterName: string = report.reporterName ?? "Someone";
    const productTitle: string = report.reportedProductTitle ?? "a product";

    try {
      const adminsSnap = await db
        .collection("Users")
        .where("role", "==", "admin")
        .get();

      if (adminsSnap.empty) {
        logger.info("onReportCreated: no admins found");
        return;
      }

      for (const adminDoc of adminsSnap.docs) {
        const adminId = adminDoc.id;
        const { title, body } = await resolveLocalizedStrings(
          adminId,
          "newReportTitle",
          "newReportBody",
          { reporter: reporterName, product: productTitle }
        );

        await createInAppNotification({
          userId: adminId,
          title,
          body,
          type: "system",
          relatedId: reportId,
        });
      }

      logger.info(
        `onReportCreated: notified ${adminsSnap.size} admin(s) of report ${reportId}`
      );
    } catch (err) {
      logger.error(`onReportCreated: error for report ${reportId}`, err);
    }
  }
);

// ─── Product update trigger ───────────────────────────────────────────────────

/**
 * Fires when a Product document is updated.
 * Finds all pending trades that contain this product and notifies the OTHER
 * participant (the one who does not own the product) of the update.
 */
export const onProductUpdated = onDocumentUpdated(
  "Products/{productId}",
  async (event) => {
    if (!event.data) return;

    const after = event.data.after.data();
    const productId = event.params.productId;
    const productTitle: string = after.title ?? "a product";
    const ownerId: string = after.ownerId;

    try {
      // Query pending trades that include this product (offered or requested)
      const [offeredSnap, requestedSnap] = await Promise.all([
        db
          .collection("Trades")
          .where("offeredProductIds", "array-contains", productId)
          .where("status", "==", "pending")
          .get(),
        db
          .collection("Trades")
          .where("requestedProductIds", "array-contains", productId)
          .where("status", "==", "pending")
          .get(),
      ]);

      // Deduplicate by trade ID
      const tradeMap = new Map<string, FirebaseFirestore.DocumentData>();
      for (const doc of [...offeredSnap.docs, ...requestedSnap.docs]) {
        if (!tradeMap.has(doc.id)) tradeMap.set(doc.id, doc.data());
      }

      if (tradeMap.size === 0) return;

      const notifiedUsers = new Set<string>();

      for (const [tradeId, trade] of tradeMap) {
        // Notify the participant who is NOT the product owner
        const recipientId =
          trade.fromUserId === ownerId ? trade.toUserId : trade.fromUserId;

        if (!recipientId || notifiedUsers.has(recipientId)) continue;
        notifiedUsers.add(recipientId);

        const { title, body } = await resolveLocalizedStrings(
          recipientId,
          "productUpdatedTitle",
          "productUpdatedBody",
          { product: productTitle }
        );

        await createInAppNotification({
          userId: recipientId,
          title,
          body,
          type: "productUpdate",
          relatedId: tradeId,
        });
      }

      if (notifiedUsers.size > 0) {
        logger.info(
          `onProductUpdated: product ${productId} updated, notified ${notifiedUsers.size} user(s)`
        );
      }
    } catch (err) {
      logger.error(`onProductUpdated: error for product ${productId}`, err);
    }
  }
);

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
export const onPaymentStatusChanged = onDocumentUpdated(
  "Payments/{paymentId}",
  async (event) => {
    if (!event.data) {
      logger.error("onPaymentStatusChanged: No data in event");
      return;
    }

    const before = event.data.before.data();
    const after  = event.data.after.data();
    const paymentId = event.params.paymentId;

    // Guard: only act on the pending → completed transition.
    if (before.status !== "pending" || after.status !== "completed") {
      logger.info(
        `Payment ${paymentId}: status changed from '${before.status}' to '${after.status}'. No action needed.`
      );
      return;
    }

    // Guard: idempotency — prevent double-crediting.
    if (after.isCredited === true) {
      logger.info(`Payment ${paymentId} was already credited. Skipping.`);
      return;
    }

    const sellerId    = after.sellerId;
    const amount      = after.amount;
    const productTitle = after.productTitle || "a product";

    if (!sellerId || !amount) {
      logger.error(`Payment ${paymentId} is missing sellerId or amount.`, after);
      return;
    }

    try {
      // Atomic transaction: credit seller + create wallet record + mark as credited.
      await db.runTransaction(async (t) => {
        const sellerRef  = db.collection("Users").doc(sellerId);
        const sellerSnap = await t.get(sellerRef);

        if (!sellerSnap.exists) {
          throw new Error(`Seller ${sellerId} does not exist`);
        }

        const currentBalance = sellerSnap.data()?.walletBalance || 0;
        const newBalance     = currentBalance + amount;

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
        t.update(event.data!.after.ref, { isCredited: true });
      });

      logger.info(
        `Successfully credited ${amount} EGP to seller ${sellerId} for payment ${paymentId}`
      );

      // Send push notification to seller.
      const sellerDoc = await db.collection("Users").doc(sellerId).get();
      const fcmToken  = sellerDoc.data()?.fcmToken;
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
