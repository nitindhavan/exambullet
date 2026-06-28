const functions = require("firebase-functions");
const axios = require("axios");

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
