import { onRequest } from "firebase-functions/v2/https";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

/**
 * Paymob Webhook to handle successful payments
 * Version: 1.0.2 - Robust Retry Logic
 */
export const paymobWebhook = onRequest(async (req, res) => {
  // Paymob sends POST requests
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  // Verify HMAC (Optional but highly recommended for production)
  // Paymob sends specific fields concatenated to generate HMAC.
  // For this example, we proceed with the core logic assuming verification passes
  // or implementing a basic check if hmac is provided in query
  const receivedHmac = req.query.hmac as string;
  if (receivedHmac) {
      // In a real implementation, you would calculate HMAC from req.body and compare
      // For now, we just log it.
      logger.info("Received HMAC:", receivedHmac);
  }

  const transaction = req.body?.obj || req.body;
  if (!transaction) {
    logger.error("Invalid Paymob webhook payload", req.body);
    res.status(400).send("Invalid payload");
    return;
  }

  // We only care about successful transactions
  const isSuccess = transaction.success === true || 
                    transaction.success === "true" || 
                    transaction.success === 1 || 
                    transaction.success === "1";

  if (!isSuccess) {
    logger.info("Transaction not successful, ignoring.", { id: transaction.id, success: transaction.success });
    res.status(200).send("Ignored");
    return;
  }

  const rawId = transaction.id || transaction.obj?.id;
  if (!rawId) {
    logger.error("No transaction ID found in payload", transaction);
    res.status(400).send("No ID found");
    return;
  }

  const transactionId = rawId.toString().trim();
  logger.info(`Processing Paymob webhook for transaction ID: ${transactionId}`);
  
  try {
    // 1. Find the corresponding Payment document by transactionId
    const paymentsRef = db.collection("Payments");
    const countSnapshot = await paymentsRef.count().get();
    logger.info(`Searching in Payments collection (Total docs: ${countSnapshot.data().count}) for transactionId: ${transactionId}`);
    
    // Search as string
    let paymentQuery = await paymentsRef.where("transactionId", "==", transactionId).limit(1).get();
    
    // If not found, try searching as number (just in case)
    if (paymentQuery.empty && !isNaN(Number(transactionId))) {
      paymentQuery = await paymentsRef.where("transactionId", "==", Number(transactionId)).limit(1).get();
    }

    if (paymentQuery.empty) {
      logger.warn(`Payment with transaction ID '${transactionId}' not found in Firestore.`);
      
      // DIAGNOSTIC: Log all transactionIds in the database to see what they actually look like
      const allDocs = await paymentsRef.get();
      const allIds = allDocs.docs.map(d => ({
        docId: d.id, 
        transactionId: d.data().transactionId,
        type: typeof d.data().transactionId
      }));
      logger.info(`Existing transaction IDs in DB: ${JSON.stringify(allIds)}`);

      // Return 404 so Paymob retries the webhook later. 
      res.status(404).send("Payment record not found yet. Retrying...");
      return;
    }

    const paymentDoc = paymentQuery.docs[0];
    const paymentData = paymentDoc.data();
    
    // Check idempotency (prevent double crediting)
    if (paymentData.isCredited === true) {
      logger.info(`Transaction ${transactionId} was already credited.`);
      res.status(200).send("Already credited");
      return;
    }

    const sellerId = paymentData.sellerId;
    const amount = paymentData.amount; // Ensure this is the correct amount to credit

    // Use a Firestore Transaction for atomicity
    await db.runTransaction(async (t) => {
      const sellerRef = db.collection("Users").doc(sellerId);
      const sellerSnap = await t.get(sellerRef);

      if (!sellerSnap.exists) {
        throw new Error(`Seller ${sellerId} does not exist`);
      }

      const currentBalance = sellerSnap.data()?.walletBalance || 0;
      const newBalance = currentBalance + amount;

      // Update seller's balance
      t.update(sellerRef, { walletBalance: newBalance });

      // Create a WalletTransaction record
      const walletTxRef = db.collection("WalletTransactions").doc();
      t.set(walletTxRef, {
        id: walletTxRef.id,
        userId: sellerId,
        amount: amount,
        type: "credit",
        referenceId: paymentDoc.id,
        description: `Payment received for ${paymentData.productTitle}`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Mark payment as credited
      t.update(paymentDoc.ref, { isCredited: true });
    });

    logger.info(`Successfully credited ${amount} to seller ${sellerId}`);

    // Send Notification to Seller
    const sellerDoc = await db.collection("Users").doc(sellerId).get();
    const fcmToken = sellerDoc.data()?.fcmToken;
    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: "Payment Received!",
          body: `You received ${amount} EGP for your product.`,
        },
        data: {
          type: "wallet_update",
        }
      });
    }

    res.status(200).send("Success");
  } catch (error) {
    logger.error("Error processing webhook:", error);
    res.status(500).send("Internal Server Error");
  }
});

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
        // Ideally, revert status or alert admin
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
