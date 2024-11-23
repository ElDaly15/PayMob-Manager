import 'package:demons/core/utils/const.dart';
import 'package:dio/dio.dart';

class PaymobWalletManager {
  Future<String> getPaymentKeyForWallet(
      int amount, String currency, String walletMobileNumber) async {
    try {
      // Step 1: Get Authentication Token
      String authenticationToken = await _getAuthenticationToken();

      // Step 2: Get Order ID
      int orderId = await _getOrderId(
        authenticationToken: authenticationToken,
        amount: (100 * amount).toString(),
        currency: currency,
      );

      // Step 3: Get Payment Key
      String paymentKey = await _getPaymentKey(
        authenticationToken: authenticationToken,
        amount: (100 * amount).toString(),
        currency: currency,
        orderId: orderId.toString(),
      );

      // Step 4: Pay With Wallet
      String redirectUrl = await _payWithWallet(
          paymentKey: paymentKey, walletMobileNumber: walletMobileNumber);

      // Step 5: Return Redirect URL
      return redirectUrl;
    } catch (e) {
      throw Exception("Wallet Payment Failed: ${e.toString()}");
    }
  }

  // Step 1: Get Authentication Token
  Future<String> _getAuthenticationToken() async {
    final Response response =
        await Dio().post("https://accept.paymob.com/api/auth/tokens", data: {
      "api_key": KConstants.apiKey,
    });
    return response.data["token"];
  }

  // Step 2: Get Order ID
  Future<int> _getOrderId({
    required String authenticationToken,
    required String amount,
    required String currency,
  }) async {
    final Response response = await Dio()
        .post("https://accept.paymob.com/api/ecommerce/orders", data: {
      "auth_token": authenticationToken,
      "amount_cents": amount,
      "currency": currency,
      "delivery_needed": "true",
      "items": [],
    });
    return response.data["id"];
  }

  // Step 3: Get Payment Key
  Future<String> _getPaymentKey({
    required String authenticationToken,
    required String orderId,
    required String amount,
    required String currency,
  }) async {
    final Response response = await Dio()
        .post("https://accept.paymob.com/api/acceptance/payment_keys", data: {
      "expiration": 3600,
      "auth_token": authenticationToken,
      "order_id": orderId,
      "integration_id": KConstants.walletIntegrationId, // Wallet Integration ID
      "amount_cents": amount,
      "currency": currency,
      "billing_data": {
        "first_name": "Wallet User",
        "last_name": "N/A",
        "email":
            "wallet_user@example.com", // You can replace it with the actual email if available
        "phone_number": 'N/A',
        "apartment": "NA",
        "floor": "NA",
        "street": "NA",
        "building": "NA",
        "shipping_method": "NA",
        "postal_code": "NA",
        "city": "NA",
        "country": "NA",
        "state": "NA"
      },
    });
    return response.data["token"];
  }

  // Step 4: Pay With Wallet
  Future<String> _payWithWallet({
    required String paymentKey,
    required String walletMobileNumber,
  }) async {
    final Response response = await Dio().post(
      "https://accept.paymob.com/api/acceptance/payments/pay",
      data: {
        "source": {
          "identifier": walletMobileNumber, // Mobile number linked to wallet
          "subtype": "WALLET",
        },
        "payment_token": paymentKey,
      },
    );

    // Check if redirect URL exists

    // Extract the redirect URL from the response
    String redirectUrl = response.data['redirect_url'];
    return redirectUrl;
  }
}
