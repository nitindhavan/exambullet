import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

void registerCashfreeCallback(Completer<String> completer) {
  (web.window as JSObject).setProperty(
    '_cashfreeCallback'.toJS,
    ((JSString status, JSString message) {
      if (!completer.isCompleted) completer.complete(status.toDart);
    }).toJS,
  );
}

void callCashfreeJs(String paymentSessionId, String mode) {
  (web.window as JSObject).callMethod(
    'initiateCashfreePayment'.toJS,
    paymentSessionId.toJS,
    mode.toJS,
  );
}
