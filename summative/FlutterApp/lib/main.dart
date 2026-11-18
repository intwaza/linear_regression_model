import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// my FastAPI on Render
const String apiUrl = 'https://order-cycle-api.onrender.com/predict';

void main() {
  runApp(const OrderCycleApp());
}

class OrderCycleApp extends StatelessWidget {
  const OrderCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Order Cycle Time',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const PredictionPage(),
    );
  }
}

// One input of the model: the name the API expects, the label shown in the app,
// a starting value and a short help text.
class InputField {
  final String key;
  final String label;
  final String startValue;
  final String help;
  final bool isNumber;

  const InputField(this.key, this.label, this.startValue, this.help, {this.isNumber = false});
}

// the 12 inputs, in the same order as the API
const List<InputField> inputs = [
  InputField('country', 'Country', 'Rwanda', 'For example Rwanda, Kenya or Uganda'),
  InputField('order_type', 'Order type', 'Purchase Order', 'Purchase Order or Distribution Order'),
  InputField('transport_mode', 'Transport mode', 'Air', 'Air, Land, Sea or Multiple'),
  InputField('product_category', 'Product category', 'HIV/AIDS Pharmaceuticals',
      'For example HIV/AIDS Pharmaceuticals or Laboratory Reagents'),
  InputField('health_element', 'Health element', 'HIV/AIDS', 'For example HIV/AIDS, Malaria or Family Planning and Reproduction'),
  InputField('vendor_incoterm', 'Vendor incoterm', 'FCA', 'CIP, CPT, DAP, DDP, EXW, FCA, Other or Unknown'),
  InputField('destination_incoterm', 'Destination incoterm', 'DAP', 'CIF, CIP, CPT, DAP, DDP, FCA, Other or Unknown'),
  InputField('ordered_quantity', 'Ordered quantity', '5000', 'Number of units, 1 to 5,000,000', isNumber: true),
  InputField('unit_price', 'Unit price (USD)', '7.5', 'Price of one unit, more than 0', isNumber: true),
  InputField('est_lead_time_days', 'Estimated lead time (days)', '150', 'Days, 0 to 730', isNumber: true),
  InputField('order_year', 'Order year', '2023', '2016 to 2030', isNumber: true),
  InputField('order_month', 'Order month', '3', '1 to 12', isNumber: true),
];

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final Map<String, TextEditingController> controllers = {};
  String message = 'Fill in the order and press Predict.';
  bool isError = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final field in inputs) {
      controllers[field.key] = TextEditingController(text: field.startValue);
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Builds the JSON body. An empty field is left out, so the API says it is required.
  // A number field is sent as a number if it is one, otherwise as text, so the API
  // rejects it with a "wrong type" error.
  Map<String, dynamic> buildBody() {
    final body = <String, dynamic>{};
    for (final field in inputs) {
      final text = controllers[field.key]!.text.trim();
      if (text.isEmpty) continue;
      body[field.key] = field.isNumber ? (num.tryParse(text) ?? text) : text;
    }
    return body;
  }

  // Turns the list of errors from the API into lines like
  // "Order month: Input should be less than or equal to 12"
  String readErrors(List<dynamic> errors) {
    final labels = {for (final field in inputs) field.key: field.label};
    final lines = <String>[];
    for (final error in errors) {
      final key = error['loc'].last.toString();
      var text = error['msg'].toString().replaceFirst('Value error, ', '');
      if (error['type'] == 'missing') text = 'Please fill in this field';
      lines.add('${labels[key] ?? key}: $text');
    }
    return lines.join('\n');
  }

  Future<void> predict() async {
    FocusScope.of(context).unfocus(); // hide the keyboard
    setState(() {
      isLoading = true;
      isError = false;
      message = 'Predicting... The first request can take up to a minute while the server wakes up.';
    });

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(buildBody()),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final num days = jsonDecode(response.body)['predicted_order_cycle_days'];
        setState(() {
          message = 'Predicted order cycle time: $days days\n(about ${(days / 30).toStringAsFixed(1)} months)';
        });
      } else if (response.statusCode == 422) {
        setState(() {
          message = readErrors(jsonDecode(response.body)['detail']);
          isError = true;
        });
      } else {
        setState(() {
          message = 'The server had a problem (error ${response.statusCode}). Please try again.';
          isError = true;
        });
      }
    } on TimeoutException {
      setState(() {
        message = 'The server took too long to answer. Please press Predict again.';
        isError = true;
      });
    } catch (e) {
      setState(() {
        message = 'Could not reach the server. Check your internet connection and try again.';
        isError = true;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildField(InputField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controllers[field.key],
        keyboardType: field.isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: field.label,
          helperText: field.help,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildResult() {
    final color = isError ? Colors.red.shade700 : Colors.teal.shade700;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      // if there are many errors the box scrolls instead of covering the form
      constraints: const BoxConstraints(maxHeight: 190),
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 16, color: isLoading ? Colors.black87 : color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Cycle Time Predictor'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // the form scrolls, the button and the result stay at the bottom
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Predicts how many days a health commodity order takes from order entry to delivery.',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    const Text('Order details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    for (final field in inputs.where((f) => !f.isNumber)) buildField(field),
                    const SizedBox(height: 8),
                    const Text('Quantity, price and dates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    for (final field in inputs.where((f) => f.isNumber)) buildField(field),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: isLoading ? null : predict,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: const Text('Predict', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  buildResult(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
