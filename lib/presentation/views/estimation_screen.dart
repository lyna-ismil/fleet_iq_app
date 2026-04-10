import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../constants/theme.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'confirmation_screen.dart';

class EstimationScreen extends ConsumerStatefulWidget {
  final String carId;
  final String pickupLocation;

  const EstimationScreen({
    Key? key,
    required this.carId,
    required this.pickupLocation,
  }) : super(key: key);

  @override
  ConsumerState<EstimationScreen> createState() => _EstimationScreenState();
}

class _EstimationScreenState extends ConsumerState<EstimationScreen>
    with SingleTickerProviderStateMixin {
  DateTime? startDate;
  DateTime? endDate;
  double? estimatedCost;
  PriceEstimate? _priceEstimate;
  bool isLoading = false;
  String dropOffLocation = "";
  late String pickupLocation;
  
  bool _superCdwSelected = false;
  bool _additionalDriverSelected = false;
  List<String> _availableLocations = [];
  String? _selectedLocation;

  static const Map<String, String> _locationKeyMap = {
    "Tunis Aouina": "downtown",
    "Aéroport Tunis": "airport",
    "Ariana": "ariana",
    "Sfax": "sfax",
    "Monastir": "monastir",
    "Djerba": "djerba",
    "Hammamet": "hammamet",
  };

  String _mapLocationToKey(String label) =>
      _locationKeyMap[label] ?? "downtown";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    pickupLocation = widget.pickupLocation;

    ApiService.getPricingLocations().then((locs) {
      if (mounted) {
        setState(() {
          _availableLocations = locs;
          if (_availableLocations.isNotEmpty) {
            // Optional: preselect or leave null
          }
        });
      }
    }).catchError((e) {
      // Fallback locations if backend fails
      if (mounted) {
        setState(() {
          _availableLocations = _locationKeyMap.keys.toList();
        });
      }
    });

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.brandBlue,
              onPrimary: AppTheme.surfaceWhite,
              onSurface: AppTheme.textMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: AppTheme.brandBlue,
                onPrimary: AppTheme.surfaceWhite,
                onSurface: AppTheme.textMain,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStart) {
            startDate = fullDateTime;
            endDate = null;
          } else {
            endDate = fullDateTime;
          }
          estimatedCost = null; // reset estimate if dates change
          _priceEstimate = null;
        });
      }
    }
  }

  Future<void> _estimateCost() async {
    if (startDate == null || endDate == null) {
      _showErrorSnackBar('Please select both start and end time');
      return;
    }

    final diff = endDate!.difference(startDate!);
    if (diff.isNegative || diff.inMinutes == 0) {
      _showErrorSnackBar('Return time must be after Pick-up time');
      return;
    }

    if (_selectedLocation == null) {
      _showErrorSnackBar('Please select a drop-off location');
      return;
    }

    setState(() => isLoading = true);
    try {
      final car = await ApiService.getCarById(widget.carId);
      final user = ref.read(authProvider).user!;
      final userAge = user.age;
      // final bookingCount = user.nbrFoisAllocation;

      final req = EstimateRequest(
        vehicleName: car.marque,
        pickupDate: startDate!,
        dropoffDate: endDate!,
        location: _mapLocationToKey(_selectedLocation!),
        driverAgeGroup: userAge < 26 ? "young" : "adult",
        superCdw: _superCdwSelected,
        additionalDriver: _additionalDriverSelected,
      );

      final result = await ApiService.estimatePrice(req);
      
      setState(() {
        _priceEstimate = result;
        estimatedCost = result.total;
        dropOffLocation = _selectedLocation!;
        _animationController.reset();
        _animationController.forward();
      });
    } catch (e) {
      print('Error: $e');
      _showErrorSnackBar('Failed to estimate price from server.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _navigateToConfirmation() {
    if (startDate != null &&
        endDate != null &&
        estimatedCost != null &&
        dropOffLocation.isNotEmpty &&
        pickupLocation.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(
            carId: widget.carId,
            startDate: startDate!,
            endDate: endDate!,
            pickupLocation: pickupLocation,
            dropOffLocation: dropOffLocation,
            estimatedPrice: estimatedCost!,
          ),
        ),
      );
    } else {
      _showErrorSnackBar("Please complete all required fields including drop-off location");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.surfaceWhite),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
      ),
    );
  }

  String _formatDate(DateTime? dt) => dt == null
      ? 'Select Date & Time'
      : DateFormat('EEE, MMM d, yyyy • h:mm a').format(dt);

  String _formatDuration() {
    if (startDate == null || endDate == null) return "";
    final diff = endDate!.difference(startDate!);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    String result = "";
    if (days > 0) result += "$days day${days > 1 ? 's' : ''} ";
    if (hours > 0) result += "$hours hour${hours > 1 ? 's' : ''} ";
    if (minutes > 0) result += "$minutes minute${minutes > 1 ? 's' : ''}";
    return result.trim();
  }

  double _calculateProgress() {
    if (startDate == null && endDate == null) return 0.0;
    if (startDate != null && endDate == null) return 0.33;
    if (startDate != null && endDate != null && _selectedLocation == null) return 0.66;
    return 1.0;
  }

  Widget _buildBreakdownRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.surfaceWhite.withOpacity(isTotal ? 1.0 : 0.8),
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "${amount > 0 && !isTotal ? '+' : ''}${amount.toStringAsFixed(2)} DT",
            style: TextStyle(
              color: AppTheme.surfaceWhite,
              fontSize: isTotal ? 22 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
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
          "Rental Estimate",
          style: Theme.of(context).textTheme.displaySmall,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
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
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.brandLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.calculate_outlined,
                          size: 40,
                          color: AppTheme.brandBlue,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Plan Your Trip",
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Select pick-up/return times to calculate your estimated rental price.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 24),

                    // Progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Booking Completion", // FIXED: using "Booking Completion" literally
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          "${(_calculateProgress() * 100).toInt()}%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandBlue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _calculateProgress(),
                        backgroundColor: AppTheme.surfaceBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandBlue),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 20, color: AppTheme.textMuted),
                  SizedBox(width: 8),
                  Text(
                    "Rental Period",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMain,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Start date
              _buildDateTimeCard(
                title: "Pick-up",
                subtitle: "When will you get the car?",
                icon: Icons.flight_takeoff_outlined,
                date: startDate,
                onTap: () => _pickDateTime(isStart: true),
              ),

              if (startDate != null)
                Container(
                  margin: EdgeInsets.only(left: 36),
                  width: 2,
                  height: 24,
                  color: AppTheme.surfaceBorder,
                ),

              // End date
              _buildDateTimeCard(
                title: "Return",
                subtitle: "When will you return the car?",
                icon: Icons.flight_land_outlined,
                date: endDate,
                onTap: startDate == null ? null : () => _pickDateTime(isStart: false),
                disabled: startDate == null,
              ),

              SizedBox(height: 24),

              if (startDate != null && endDate != null) ...[
                // Drop-off location
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 20, color: AppTheme.textMuted),
                    SizedBox(width: 8),
                    Text(
                      "Drop-off Location",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    hint: Text("Select drop-off location..."),
                    decoration: InputDecoration(border: InputBorder.none),
                    isExpanded: true,
                    items: _availableLocations.map((loc) {
                      return DropdownMenuItem<String>(
                        value: loc,
                        child: Text(loc),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                         _selectedLocation = value;
                         dropOffLocation = value ?? "";
                         estimatedCost = null;
                         _priceEstimate = null;
                      });
                    },
                  ),
                ),
                
                SizedBox(height: 24),
                // Options
                Row(
                  children: [
                    Icon(Icons.tune_outlined, size: 20, color: AppTheme.textMuted),
                    SizedBox(width: 8),
                    Text(
                      "Options",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text("Super CDW Insurance"),
                        subtitle: Text("Full coverage with no deductible"),
                        value: _superCdwSelected,
                        activeColor: AppTheme.brandBlue,
                        onChanged: (val) => setState(() {
                          _superCdwSelected = val;
                          estimatedCost = null;
                          _priceEstimate = null;
                        }),
                      ),
                      Divider(height: 1),
                      SwitchListTile(
                        title: Text("Additional Driver"),
                        subtitle: Text("Add a second driver for this trip"),
                        value: _additionalDriverSelected,
                        activeColor: AppTheme.brandBlue,
                        onChanged: (val) => setState(() {
                          _additionalDriverSelected = val;
                          estimatedCost = null;
                          _priceEstimate = null;
                        }),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 32),

              // Estimate Button
              ElevatedButton(
                onPressed: isLoading ? null : _estimateCost,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppTheme.surfaceWhite,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calculate_outlined),
                          SizedBox(width: 8),
                          Text("Calculate Estimate"),
                        ],
                      ),
              ),

              SizedBox(height: 32),

              // Results Section
              if (_priceEstimate != null)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
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
                              color: AppTheme.success.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_outline,
                              color: AppTheme.success,
                              size: 40,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Ready to Book",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.surfaceWhite,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "for ${_formatDuration()}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.surfaceWhite.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: 24),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceWhite.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                            ),
                            child: Column(
                              children: [
                                _buildBreakdownRow("Base Rental", _priceEstimate!.basePrice),
                                if (_priceEstimate!.seasonAdjustment != 0)
                                  _buildBreakdownRow("Season Adj.", _priceEstimate!.seasonAdjustment),
                                if (_priceEstimate!.superCdw > 0)
                                  _buildBreakdownRow("Super CDW", _priceEstimate!.superCdw),
                                if (_priceEstimate!.additionalDriver > 0)
                                  _buildBreakdownRow("Add. Driver", _priceEstimate!.additionalDriver),
                                if (_priceEstimate!.youngDriverSurcharge > 0)
                                  _buildBreakdownRow("Young Driver", _priceEstimate!.youngDriverSurcharge),
                                _buildBreakdownRow("Admin Fee", _priceEstimate!.adminFee),
                                _buildBreakdownRow("VAT (19%)", _priceEstimate!.vat),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Colors.white54),
                                ),
                                _buildBreakdownRow("Total", _priceEstimate!.total, isTotal: true),
                              ],
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _navigateToConfirmation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceWhite,
                              foregroundColor: AppTheme.textMain,
                              minimumSize: Size(double.infinity, 56),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Continue to Booking"),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required DateTime? date,
    required VoidCallback? onTap,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: disabled ? AppTheme.surfaceGray : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: disabled ? [] : AppTheme.softShadow,
          border: date != null
              ? Border.all(color: AppTheme.brandBlue, width: 1.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: disabled
                    ? AppTheme.surfaceBorder
                    : (date != null ? AppTheme.brandLight : AppTheme.surfaceGray),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: disabled
                    ? AppTheme.textMuted
                    : (date != null ? AppTheme.brandBlue : AppTheme.textMain),
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: disabled ? AppTheme.textMuted : AppTheme.textMain,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    date != null ? _formatDate(date) : subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: disabled
                          ? AppTheme.textMuted
                          : (date != null ? AppTheme.brandBlue : AppTheme.textMuted),
                      fontWeight: date != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: disabled
                  ? AppTheme.textMuted
                  : (date != null ? AppTheme.brandBlue : AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
