// Stub for Cashfree SDK classes — used on web where the native SDK is unavailable.

enum CFEnvironment { SANDBOX, PRODUCTION }

class CFErrorResponse {
  String? getMessage() => null;
}

class CFSessionBuilder {
  CFSessionBuilder setEnvironment(CFEnvironment e) => this;
  CFSessionBuilder setOrderId(String id) => this;
  CFSessionBuilder setPaymentSessionId(String id) => this;
  CFSession build() => CFSession();
}

class CFSession {}

class CFWebCheckoutPaymentBuilder {
  CFWebCheckoutPaymentBuilder setSession(CFSession s) => this;
  CFWebCheckoutPayment build() => CFWebCheckoutPayment();
}

class CFWebCheckoutPayment {}

class CFPaymentGatewayService {
  static final CFPaymentGatewayService _instance = CFPaymentGatewayService._();
  CFPaymentGatewayService._();
  factory CFPaymentGatewayService() => _instance;
  void setCallback(void Function(String) onSuccess, void Function(CFErrorResponse, String) onError) {}
  void doPayment(CFWebCheckoutPayment payment) {}
}
