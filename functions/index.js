const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const CASHFREE_APP_ID_TEST = process.env.CASHFREE_APP_ID_TEST;
const CASHFREE_SECRET_TEST = process.env.CASHFREE_SECRET_TEST;
const CASHFREE_APP_ID_PROD = process.env.CASHFREE_APP_ID_PROD;
const CASHFREE_SECRET_PROD = process.env.CASHFREE_SECRET_PROD;

// Creates a Cashfree order and returns payment_session_id — Flutter calls this before opening checkout
exports.createCashfreeOrder = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") { res.status(204).send(""); return; }

  const { orderId, orderAmount, customerEmail, customerPhone, customerName, stage } = req.body;

  if (!orderId || !orderAmount) {
    res.status(400).json({ error: "orderId and orderAmount are required" });
    return;
  }

  const isTest = stage === "TEST";
  const appId = isTest ? CASHFREE_APP_ID_TEST : CASHFREE_APP_ID_PROD;
  const secret = isTest ? CASHFREE_SECRET_TEST : CASHFREE_SECRET_PROD;
  const baseUrl = isTest
    ? "https://sandbox.cashfree.com/pg/orders"
    : "https://api.cashfree.com/pg/orders";

  try {
    const response = await axios.post(
      baseUrl,
      {
        order_id: orderId,
        order_amount: parseFloat(orderAmount),
        order_currency: "INR",
        customer_details: {
          customer_id: orderId,
          customer_email: customerEmail || "customer@example.com",
          customer_phone: customerPhone || "9999999999",
          customer_name: customerName || "Customer",
        },
      },
      {
        headers: {
          "x-client-id": appId,
          "x-client-secret": secret,
          "x-api-version": "2023-08-01",
          "Content-Type": "application/json",
        },
      }
    );
    functions.logger.info("Cashfree order response", response.data);
    res.status(200).json({
      payment_session_id: response.data.payment_session_id,
      order_id: orderId,
      _debug: response.data,
    });
  } catch (e) {
    functions.logger.error("createCashfreeOrder error", e.response?.data ?? e.message);
    res.status(500).json({ error: e.response?.data?.message ?? e.message });
  }
});

// Verifies payment status — Flutter calls this after SDK reports success
exports.verifyCashfreeOrder = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") { res.status(204).send(""); return; }

  const { orderId, stage } = req.body;

  if (!orderId) {
    res.status(400).json({ error: "orderId is required" });
    return;
  }

  const isTest = stage === "TEST";
  const appId = isTest ? CASHFREE_APP_ID_TEST : CASHFREE_APP_ID_PROD;
  const secret = isTest ? CASHFREE_SECRET_TEST : CASHFREE_SECRET_PROD;
  const baseUrl = isTest
    ? `https://sandbox.cashfree.com/pg/orders/${orderId}`
    : `https://api.cashfree.com/pg/orders/${orderId}`;

  try {
    const response = await axios.get(baseUrl, {
      headers: {
        "x-client-id": appId,
        "x-client-secret": secret,
        "x-api-version": "2023-08-01",
      },
    });
    const order = response.data;
    res.status(200).json({
      txStatus: order?.order_status === "PAID" ? "SUCCESS" : "FAILED",
      referenceId: order?.cf_order_id?.toString() ?? "",
    });
  } catch (e) {
    functions.logger.error("verifyCashfreeOrder error", e.response?.data ?? e.message);
    res.status(500).json({ error: e.response?.data?.message ?? e.message });
  }
});

// ── Push broadcast ────────────────────────────────────────────────────────────
// Admin calls this with { title, body }. It (1) writes the notification record
// so the in-app feed keeps working, and (2) sends an FCM push to every user's
// stored token(s). The FCM credential stays server-side (the function's own
// service account) — no key ships in any app.
exports.sendBroadcast = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") { res.status(204).send(""); return; }

  const title = (req.body.title || "").toString().trim();
  const body = (req.body.body || "").toString().trim();

  if (!title || !body) {
    res.status(400).json({ error: "title and body are required" });
    return;
  }

  const db = admin.database();

  try {
    // 1) Write the notification record (in-app feed).
    const notifRef = db.ref("notifications").push();
    await notifRef.set({
      id: notifRef.key,
      title,
      body,
      timestamp: Date.now(),
    });

    // 2) Collect all FCM tokens from users.
    //    Supports both a single `fcmToken` string and an `fcmTokens` map
    //    (multiple devices per user).
    const usersSnap = await db.ref("users").get();
    const tokenSet = new Set();
    const tokenOwner = {}; // token -> "uid/childKey" so we can prune invalid ones

    if (usersSnap.exists()) {
      const users = usersSnap.val();
      for (const uid of Object.keys(users)) {
        const u = users[uid] || {};
        if (typeof u.fcmToken === "string" && u.fcmToken) {
          tokenSet.add(u.fcmToken);
          tokenOwner[u.fcmToken] = `${uid}/fcmToken`;
        }
        if (u.fcmTokens && typeof u.fcmTokens === "object") {
          for (const key of Object.keys(u.fcmTokens)) {
            if (u.fcmTokens[key]) {
              tokenSet.add(key);
              tokenOwner[key] = `${uid}/fcmTokens/${key}`;
            }
          }
        }
      }
    }

    const tokens = Array.from(tokenSet);
    if (tokens.length === 0) {
      res.status(200).json({ successCount: 0, failureCount: 0, totalTokens: 0 });
      return;
    }

    // 3) Send in batches of 500 (FCM multicast limit).
    let successCount = 0;
    let failureCount = 0;
    const invalidTokens = [];

    for (let i = 0; i < tokens.length; i += 500) {
      const batch = tokens.slice(i, i + 500);
      const response = await admin.messaging().sendEachForMulticast({
        tokens: batch,
        notification: { title, body },
        android: {
          priority: "high",
          notification: { sound: "default" },
        },
        apns: {
          payload: { aps: { sound: "default" } },
        },
      });

      successCount += response.successCount;
      failureCount += response.failureCount;

      response.responses.forEach((r, idx) => {
        if (!r.success) {
          const code = r.error && r.error.code;
          if (
            code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-argument" ||
            code === "messaging/invalid-registration-token"
          ) {
            invalidTokens.push(batch[idx]);
          }
        }
      });
    }

    // 4) Prune tokens that FCM rejected as dead.
    await Promise.all(
      invalidTokens.map((t) =>
        tokenOwner[t] ? db.ref(`users/${tokenOwner[t]}`).remove().catch(() => {}) : null
      )
    );

    functions.logger.info("sendBroadcast", { totalTokens: tokens.length, successCount, failureCount });
    res.status(200).json({
      successCount,
      failureCount,
      totalTokens: tokens.length,
      pruned: invalidTokens.length,
    });
  } catch (e) {
    functions.logger.error("sendBroadcast error", e.message);
    res.status(500).json({ error: e.message });
  }
});
