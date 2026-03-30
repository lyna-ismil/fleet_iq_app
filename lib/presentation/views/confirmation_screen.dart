import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/api_config.dart';

import '../../constants/theme.dart';
import 'payment_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  final String carId;
  final DateTime startDate;
  final DateTime endDate;
  final String pickupLocation;
  final String dropOffLocation;
  final double estimatedPrice;

  const ConfirmationScreen({
    Key? key,
    required this.carId,
    required this.startDate,
    required this.endDate,
    required this.pickupLocation,
    required this.dropOffLocation,
    required this.estimatedPrice,
  }) : super(key: key);

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? carDetails;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  String _errorMessage = '';

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
    fetchCarDetails(widget.carId);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchCarDetails(String carId) async {
    final url = Uri.parse("$carEndpoint/$carId");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          carDetails = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load car details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('EEE, MMM d, yyyy • h:mm a').format(dateTime);
  }

  String _formatDuration() {
    final diff = widget.endDate.difference(widget.startDate);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    String result = "";
    if (days > 0) result += "$days day${days > 1 ? 's' : ''} ";
    if (hours > 0) result += "$hours hour${hours > 1 ? 's' : ''} ";
    if (minutes > 0) result += "$minutes minute${minutes > 1 ? 's' : ''}";
    return result.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surfaceWhite,
        iconTheme: IconThemeData(color: AppTheme.textMain),
        title: Text(
          "Confirm Booking",
          style: Theme.of(context).textTheme.displaySmall,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.brandBlue))
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                                  Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: AppTheme.brandLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.receipt_long_outlined,
                                        size: 48,
                                        color: AppTheme.brandBlue,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "Booking Summary",
                                    style: Theme.of(context).textTheme.displaySmall,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Please review your booking details before proceeding to payment",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 32),

                            _buildSectionHeader("Car Details", Icons.directions_car_outlined),
                            SizedBox(height: 16),
                            carDetails == null
                                ? Center(child: CircularProgressIndicator())
                                : Column(
                                    children: [
                                      _buildDetailCard(
                                        title: "Selected Car",
                                        value: carDetails!['marque'] ?? "Unknown Car",
                                        icon: Icons.car_rental,
                                      ),
                                      SizedBox(height: 12),
                                      _buildDetailCard(
                                        title: "License Plate",
                                        value: carDetails!['matricule'] ?? "N/A",
                                        icon: Icons.credit_card_outlined,
                                      ),
                                    ],
                                  ),

                            SizedBox(height: 32),

                            _buildSectionHeader("Rental Period", Icons.calendar_today_outlined),
                            SizedBox(height: 16),
                            _buildDetailCard(
                              title: "Pick-up Date",
                              value: _formatDate(widget.startDate),
                              icon: Icons.flight_takeoff_outlined,
                            ),
                            SizedBox(height: 12),
                            _buildDetailCard(
                              title: "Return Date",
                              value: _formatDate(widget.endDate),
                              icon: Icons.flight_land_outlined,
                            ),
                            SizedBox(height: 12),
                            _buildDetailCard(
                              title: "Duration",
                              value: _formatDuration(),
                              icon: Icons.timelapse_outlined,
                            ),

                            SizedBox(height: 32),

                            _buildSectionHeader("Locations", Icons.location_on_outlined),
                            SizedBox(height: 16),
                            _buildDetailCard(
                              title: "Pick-up Location",
                              value: widget.pickupLocation,
                              icon: Icons.location_searching,
                            ),
                            SizedBox(height: 12),
                            _buildDetailCard(
                              title: "Drop-off Location",
                              value: widget.dropOffLocation,
                              icon: Icons.location_on,
                            ),

                            SizedBox(height: 32),

                            _buildSectionHeader("Price Details", Icons.attach_money_outlined),
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceWhite,
                                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                                boxShadow: AppTheme.softShadow,
                                border: Border.all(color: AppTheme.brandBlue.withOpacity(0.1)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Base Rate", style: Theme.of(context).textTheme.bodyMedium),
                                      Text("${(widget.estimatedPrice * 0.8).toStringAsFixed(2)} DT", style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Taxes & Fees", style: Theme.of(context).textTheme.bodyMedium),
                                      Text("${(widget.estimatedPrice * 0.2).toStringAsFixed(2)} DT", style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Divider(color: AppTheme.surfaceBorder),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Total Price", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                                      Text(
                                        "${widget.estimatedPrice.toStringAsFixed(2)} DT",
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PaymentScreen(
                                      carId: widget.carId,
                                      startDate: widget.startDate,
                                      endDate: widget.endDate,
                                      pickupLocation: widget.pickupLocation,
                                      dropOffLocation: widget.dropOffLocation,
                                      totalAmount: widget.estimatedPrice,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 56),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.payment_outlined),
                                  SizedBox(width: 8),
                                  Text("Proceed to Payment"),
                                ],
                              ),
                            ),
                            SizedBox(height: 48),
                          ],
                        ),
                      ),
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
