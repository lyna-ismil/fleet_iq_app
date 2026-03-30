import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'NFCKeyScreen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../constants/api_config.dart';
import '../../constants/theme.dart';
import './widgets/custom_text_field.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String carId;
  final DateTime startDate;
  final DateTime endDate;
  final String pickupLocation;
  final String dropOffLocation;
  
  const PaymentScreen({
    Key? key,
    required this.carId,
    required this.startDate,
    required this.endDate,
    required this.pickupLocation,
    required this.dropOffLocation,
    required this.totalAmount,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  String selectedMethod = "Credit Card";
  final _formKey = GlobalKey<FormState>();
  bool isProcessing = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    nameController.dispose();
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<dynamic> _storeBooking() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) return null;

    final url = Uri.parse(bookingEndpoint);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "id_user": userId,
        "id_car": widget.carId,
        "date_hour_booking": widget.startDate.toIso8601String(),
        "date_hour_expire": widget.endDate.toIso8601String(),
        "paiement": widget.totalAmount,
        "location_Before_Renting": widget.pickupLocation,
        "location_After_Renting": widget.dropOffLocation,
        "estimated_Location": widget.dropOffLocation,
        "status": true
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      return null;
    }
  }

  void _simulatePayment() async {
    if (selectedMethod == "Credit Card" && !_formKey.currentState!.validate()) return;
    setState(() => isProcessing = true);
    await Future.delayed(Duration(seconds: 2));

    try {
      final booking = await _storeBooking();
      if (booking == null) throw Exception("Failed to store booking.");
      setState(() => isProcessing = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NFCKeyScreen(
            carId: widget.carId,
            startDate: widget.startDate,
            endDate: widget.endDate,
            pickupLocation: widget.pickupLocation,
            dropOffLocation: widget.dropOffLocation,
            estimatedPrice: widget.totalAmount,
            bookingId: booking['_id'],
          ),
        ),
      );
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: AppTheme.surfaceWhite),
              SizedBox(width: 8),
              Expanded(child: Text(e.toString())),
            ],
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  String _formatCardNumber(String input) {
    String cleaned = input.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += cleaned[i];
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surfaceWhite,
        iconTheme: IconThemeData(color: AppTheme.textMain),
        title: Text("Payment", style: Theme.of(context).textTheme.displaySmall),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildProgressStep(1, "Vehicle", true),
                            _buildProgressLine(true),
                            _buildProgressStep(2, "Details", true),
                            _buildProgressLine(true),
                            _buildProgressStep(3, "Payment", true),
                            _buildProgressLine(false),
                            _buildProgressStep(4, "Confirm", false),
                          ],
                        ),
                        SizedBox(height: 24),
                        Text(
                          "Complete Payment",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  Text("Payment Method", style: Theme.of(context).textTheme.bodyLarge),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMethodCard(
                          "Credit Card",
                          Icons.credit_card,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildMethodCard(
                          "PayPal",
                          Icons.account_balance_wallet_outlined,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),

                  if (selectedMethod == "Credit Card") ...[
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppTheme.brandBlue,
                        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                        boxShadow: AppTheme.softShadow,
                      ),
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Credit Card",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.surfaceWhite.withOpacity(0.8),
                                ),
                              ),
                              Icon(Icons.contactless, color: AppTheme.surfaceWhite.withOpacity(0.6), size: 28),
                            ],
                          ),
                          Spacer(),
                          Text(
                            cardNumberController.text.isEmpty
                                ? "••••  ••••  ••••  ••••"
                                : _formatCardNumber(cardNumberController.text),
                            style: TextStyle(
                              fontSize: 24,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.surfaceWhite,
                            ),
                          ),
                          SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "CARD HOLDER",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.surfaceWhite.withOpacity(0.6),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    nameController.text.isEmpty ? "YOUR NAME" : nameController.text.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.surfaceWhite,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "EXPIRES",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.surfaceWhite.withOpacity(0.6),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    expiryController.text.isEmpty ? "MM/YY" : expiryController.text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.surfaceWhite,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: nameController,
                            hintText: "Card Holder Name",
                            icon: Icons.person_outline,
                            onChanged: (val) => setState(() {}),
                            validator: (val) => val == null || val.isEmpty ? "Required" : null,
                          ),
                          SizedBox(height: 16),
                          CustomTextField(
                            controller: cardNumberController,
                            hintText: "Card Number",
                            icon: Icons.credit_card_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(16),
                            ],
                            onChanged: (val) => setState(() {}),
                            validator: (val) => val == null || val.isEmpty ? "Required" : null,
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: expiryController,
                                  hintText: "MM/YY",
                                  icon: Icons.calendar_today_outlined,
                                  keyboardType: TextInputType.text,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                    _ExpiryDateInputFormatter(),
                                  ],
                                  onChanged: (val) => setState(() {}),
                                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: CustomTextField(
                                  controller: cvvController,
                                  hintText: "CVV",
                                  icon: Icons.lock_outline,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.brandLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.account_balance_wallet_outlined, color: AppTheme.brandBlue, size: 40),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Secure PayPal Checkout",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "You will be redirected securely to complete the payment.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 32),

                  // Summary
                  Text("Order Summary", style: Theme.of(context).textTheme.bodyLarge),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Subtotal", style: Theme.of(context).textTheme.bodyMedium),
                            Text("${(widget.totalAmount * 0.9).toStringAsFixed(2)} DT", style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Tax", style: Theme.of(context).textTheme.bodyMedium),
                            Text("${(widget.totalAmount * 0.1).toStringAsFixed(2)} DT", style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        SizedBox(height: 16),
                        Divider(color: AppTheme.surfaceBorder),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                            Text(
                              "${widget.totalAmount.toStringAsFixed(2)} DT",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brandBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: isProcessing ? null : _simulatePayment,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 56),
                    ),
                    child: isProcessing
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: AppTheme.surfaceWhite, strokeWidth: 2),
                          )
                        : Text("Pay ${widget.totalAmount.toStringAsFixed(2)} DT"),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.brandBlue : AppTheme.surfaceGray,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? AppTheme.surfaceWhite : AppTheme.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppTheme.brandBlue : AppTheme.textMuted,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? AppTheme.brandBlue : AppTheme.surfaceBorder,
      ),
    );
  }

  Widget _buildMethodCard(String method, IconData icon) {
    bool isSelected = selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = method),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandLight : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: isSelected ? AppTheme.brandBlue : AppTheme.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.softShadow : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.brandBlue : AppTheme.textMuted,
              size: 28,
            ),
            SizedBox(height: 12),
            Text(
              method,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.brandBlue : AppTheme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    if (newText.isEmpty) return newValue;
    String formatted = newText;
    if (newText.length == 2 && oldValue.text.length == 1) {
      formatted = '$newText/';
    }
    if (oldValue.text.length == 3 && oldValue.text.endsWith('/') && newText.length == 2) {
      formatted = newText.substring(0, 2);
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
