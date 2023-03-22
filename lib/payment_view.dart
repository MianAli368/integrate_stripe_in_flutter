import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentView extends StatefulWidget {
  const PaymentView({super.key});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  // PaymentIntent is used to initialize Payment.
  Map<String, dynamic>? paymentIntentData;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(title: const Text("Stripe Payment")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
              onPressed: () async {
                await makePayment();
              },
              child: const Text("Pay"))
        ],
      ),
    ));
  }

  Future<void> makePayment() async {
    try {
      paymentIntentData = await createPaymentIntent("20", "USD");
      // payment sheet is to set parameters.
      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
              // Add Client Secrey Key in the place of client_secret
              paymentIntentClientSecret: paymentIntentData!["client_secret"],
              // If you wanna add apple pay and google pay then set them true;
              // applePay: true,
              // googlePay: true,
              // Below data is optional
              // style: ThemeMode.dark,
              merchantDisplayName: "Mian Ali"));

      displayPaymentSheet();
    } catch (e) {
      print(e.toString());
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet(
          // parameters: PresentPaymentSheetParameters(clientSecret: "")
          );
      setState(() {
        paymentIntentData = null;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Paid Successfully")));
    } on SocketException {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("No Internet Connection")));
    } on StripeException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));

      showDialog(
          context: context,
          builder: ((context) {
            return AlertDialog(
              content: Text("Cancelled"),
            );
          }));
    }
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        "amount": calculateAmount(amount),
        "currency": currency,
        "payment_method_types[]": "card"
      };

      var response = await http.post(
          Uri.parse("https://api.stripe.com/v1/payment_intents"),
          body: body,
          // line after Bearer is your Secret Key
          headers: {
            "Authorization":
                "Bearer private key",
            "Content-Type": "application/x-www-form-urlencoded"
          });
      return jsonDecode(response.body.toString());
    } catch (e) {
      print(e.toString());
    }
  }

  calculateAmount(String amount) {
    final price = int.parse(amount) * 100;
    return price.toString();
  }
}
