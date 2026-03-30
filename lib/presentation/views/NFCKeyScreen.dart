import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:http/http.dart' as http;

import '../../constants/api_config.dart';
import '../../constants/theme.dart';

class NFCKeyScreen extends StatefulWidget {
  final String carId;
  final DateTime startDate;
  final DateTime endDate;
  final String pickupLocation;
  final String dropOffLocation;
  final double estimatedPrice;
  final String bookingId;

  const NFCKeyScreen({
    Key? key,
    required this.carId,
    required this.startDate,
    required this.endDate,
    required this.pickupLocation,
    required this.dropOffLocation,
    required this.estimatedPrice,
    required this.bookingId,
  }) : super(key: key);

  @override
  _NFCKeyScreenState createState() => _NFCKeyScreenState();
}

class _NFCKeyScreenState extends State<NFCKeyScreen>
    with SingleTickerProviderStateMixin {
  late String nfcKey;
  Timer? countdownTimer;
  Duration remaining = Duration.zero;
  bool _isLoading = false;
  Map<String, dynamic> _carDetails = {};

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    generateNfcKey();
    startCountdown();
    _fetchCarDetails();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  void generateNfcKey() {
    final raw = '${widget.carId}|${widget.startDate.millisecondsSinceEpoch}|${Random().nextInt(999999)}';
    nfcKey = base64Url.encode(utf8.encode(raw));
  }

  void startCountdown() {
    final now = DateTime.now();
    if (now.isBefore(widget.startDate)) {
      remaining = widget.startDate.difference(now);
      countdownTimer = Timer.periodic(Duration(seconds: 1), (_) {
        setState(() {
          final newNow = DateTime.now();
          remaining = widget.startDate.difference(newNow);
          if (remaining.isNegative) {
            countdownTimer?.cancel();
          }
        });
      });
    }
  }

  Future<void> _fetchCarDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$carEndpoint/${widget.carId}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _carDetails = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> updateBookingWithKey() async {
    final url = Uri.parse('$bookingEndpoint/${widget.bookingId}');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'current_Key_car': nfcKey}),
    );

    if (response.statusCode == 200) {
      print("✅ Booking updated with NFC key");
    } else {
      print("❌ Failed to update booking: ${response.statusCode}");
    }
  }

  Future<void> writeKeyToCard() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius2xl)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.brandLight, shape: BoxShape.circle),
                child: Icon(Icons.nfc, color: AppTheme.brandBlue),
              ),
              SizedBox(width: 12),
              Text("Ready to Write", style: Theme.of(context).textTheme.displaySmall),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Hold your NFC card near the back of the phone...", style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppTheme.brandBlue),
            ],
          ),
        ),
      );

      await FlutterNfcKit.poll();
      final record = ndef.TextRecord(
        text: nfcKey,
        language: 'en',
        encoding: ndef.TextEncoding.UTF8,
      );
      await FlutterNfcKit.writeNDEFRecords([record]);
      await FlutterNfcKit.finish();
      Navigator.of(context).pop(); // Dismiss writing dialog

      await updateBookingWithKey();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppTheme.surfaceWhite),
              SizedBox(width: 8),
              Expanded(child: Text("NFC key written successfully!")),
            ],
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      await FlutterNfcKit.finish();
      Navigator.of(context).pop(); // Dismiss writing dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius2xl)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.error_outline, color: AppTheme.danger),
              ),
              SizedBox(width: 12),
              Text("Write Failed", style: Theme.of(context).textTheme.displaySmall),
            ],
          ),
          content: Text("Error: ${e.toString()}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel", style: TextStyle(color: AppTheme.textMuted)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                writeKeyToCard();
              },
              child: Text("Try Again", style: TextStyle(color: AppTheme.brandBlue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final canWrite = now.isAfter(widget.startDate);

    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surfaceWhite,
        iconTheme: IconThemeData(color: AppTheme.textMain),
        title: Text("Digital Car Key", style: Theme.of(context).textTheme.displaySmall),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.brandBlue))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppTheme.brandLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.directions_car_outlined,
                                size: 48,
                                color: AppTheme.brandBlue,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            _carDetails['marque'] ?? "Your Car",
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceGray,
                              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                            ),
                            child: Text(
                              _carDetails['matricule'] ?? "License Plate",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),

                    _buildSectionHeader("Booking Details", Icons.calendar_today_outlined),
                    SizedBox(height: 16),
                    _buildDetailCard(
                      title: "Pick-up Date",
                      value: DateFormat('EEE, MMM d, yyyy • h:mm a').format(widget.startDate),
                      icon: Icons.flight_takeoff_outlined,
                    ),
                    SizedBox(height: 12),
                    _buildDetailCard(
                      title: "Return Date",
                      value: DateFormat('EEE, MMM d, yyyy • h:mm a').format(widget.endDate),
                      icon: Icons.flight_land_outlined,
                    ),

                    SizedBox(height: 32),

                    _buildSectionHeader("Locations", Icons.location_on_outlined),
                    SizedBox(height: 16),
                    _buildDetailCard(
                      title: "Pick-up",
                      value: widget.pickupLocation,
                      icon: Icons.location_searching,
                    ),
                    SizedBox(height: 12),
                    _buildDetailCard(
                      title: "Drop-off",
                      value: widget.dropOffLocation,
                      icon: Icons.location_on,
                    ),

                    SizedBox(height: 32),

                    _buildSectionHeader("Price", Icons.attach_money_outlined),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.brandBlue,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.payment, color: AppTheme.surfaceWhite, size: 32),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Paid",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.surfaceWhite.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                "${widget.estimatedPrice.toStringAsFixed(2)} DT",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.surfaceWhite,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 48),

                    if (!canWrite && remaining.inSeconds > 0) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.textMain,
                          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceWhite.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.timer_outlined, color: AppTheme.surfaceWhite, size: 40),
                            ),
                            SizedBox(height: 24),
                            Text(
                              "Starts In",
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.surfaceWhite.withOpacity(0.6),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: AppTheme.surfaceWhite,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "NFC key writing unlocks at pickup time.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.surfaceWhite.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                          boxShadow: AppTheme.softShadow,
                          border: Border.all(color: AppTheme.success.withOpacity(0.3), width: 2),
                        ),
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    padding: EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.nfc, color: AppTheme.success, size: 48),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 24),
                            Text(
                              "Digital Key Ready",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMain,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Tap below to write the key to your NFC card to unlock the car.",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: writeKeyToCard,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.nfc),
                                  SizedBox(width: 8),
                                  Text("Write NFC Key"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 48),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textMuted),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceGray,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.textMain, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
