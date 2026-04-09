import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/theme.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../services/api_service.dart';
import 'NFCKeyScreen.dart';

class BookingDashboardScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<BookingDashboardScreen> createState() => _BookingDashboardScreenState();
}

class _BookingDashboardScreenState extends ConsumerState<BookingDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch bookings via the provider
    Future.microtask(() {
      ref.read(bookingProvider.notifier).fetchBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(bookingProvider.notifier).fetchBookings();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: AppBar(
        title: Text("My Bookings", style: Theme.of(context).textTheme.displaySmall),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.brandBlue,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.brandBlue,
          indicatorWeight: 3,
          tabs: [
            Tab(text: "Active"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: bookingState.isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.brandBlue))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveTab(bookingState),
                _buildHistoryTab(bookingState),
              ],
            ),
    );
  }

  Widget _buildActiveTab(BookingState bookingState) {
    if (bookingState.active.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildEmptyState(Icons.car_rental, "No active rentals", "You don't have any ongoing or upcoming rentals."),
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 12),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: bookingState.active.length,
        itemBuilder: (ctx, i) => _buildBookingCard(bookingState.active[i], isActiveTab: true),
      ),
    );
  }

  Widget _buildHistoryTab(BookingState bookingState) {
     if (bookingState.history.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildEmptyState(Icons.history, "No rental history", "Your past trips will appear here."),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: bookingState.history.length,
        itemBuilder: (context, index) {
          var booking = bookingState.history[index];
          var formattedDate = DateFormat('MMM dd, yyyy').format(booking.startDate);
          
          bool isCompleted = booking.status == 'COMPLETED';
          var statusColor = isCompleted ? AppTheme.success : AppTheme.textMuted;
          if (booking.status == 'CANCELLED') statusColor = AppTheme.danger;

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            color: AppTheme.surfaceWhite,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                       booking.car != null && booking.car!['photo'] != null && booking.car!['photo'].isNotEmpty
                          ? Image.network(booking.car!['photo'], width: 60, height: 40, fit: BoxFit.contain, errorBuilder: (_,__,___) => Icon(Icons.directions_car, color: AppTheme.textMuted))
                          : Icon(Icons.directions_car, size: 40, color: AppTheme.textMuted),
                       SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(booking.car?['marque'] ?? 'Unknown Car', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                             Text(formattedDate, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                           ],
                         ),
                       ),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                           Text("${booking.payment?['amount'] ?? '--'} TND", style: TextStyle(fontWeight: FontWeight.w700)),
                           SizedBox(height: 4),
                           Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              booking.status,
                              style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                         ],
                       )
                    ],
                  ),
                  if (booking.status == 'COMPLETED' || booking.status == 'CONFIRMED') ...[
                    SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final url = await ApiService.getContractUrl(booking.id);
                        if (url != null && await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        } else {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not open contract.")));
                        }
                      },
                      icon: Icon(Icons.description, size: 18),
                      label: Text("View Contract"),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 44),
                        side: BorderSide(color: AppTheme.brandBlue),
                        foregroundColor: AppTheme.brandBlue,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, {bool isActiveTab = true}) {
    Duration remaining = booking.endDate.difference(DateTime.now());
    String timeRemaining = remaining.isNegative ? "Expired" : "${remaining.inDays}d ${remaining.inHours % 24}h ${remaining.inMinutes % 60}m";

    Color statusColor;
    String statusLabel;
    switch (booking.status.toUpperCase()) {
      case 'PENDING':
        statusColor = Colors.amber;
        statusLabel = 'Awaiting Confirmation';
        break;
      case 'CONFIRMED':
        statusColor = AppTheme.brandBlue;
        statusLabel = 'Confirmed';
        break;
      case 'ACTIVE':
        statusColor = AppTheme.success;
        statusLabel = 'Active Rental';
        break;
      case 'COMPLETED':
        statusColor = Colors.grey;
        statusLabel = 'Completed';
        break;
      case 'CANCELLED':
        statusColor = AppTheme.danger;
        statusLabel = 'Cancelled';
        break;
      case 'EXPIRED':
        statusColor = Colors.blueGrey;
        statusLabel = 'Expired';
        break;
      default:
        statusColor = AppTheme.textMuted;
        statusLabel = booking.status;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel.toUpperCase(),
                  style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w700),
                ),
              ),
              if (isActiveTab && !remaining.isNegative)
                Text(timeRemaining, style: TextStyle(fontSize: 14, color: AppTheme.danger, fontWeight: FontWeight.w700)),
              if (isActiveTab && remaining.isNegative)
                Text("Expired", style: TextStyle(fontSize: 14, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 20),
          booking.car != null && booking.car!['photo'] != null && booking.car!['photo'].isNotEmpty
              ? Image.network(booking.car!['photo'], height: 120, fit: BoxFit.contain, errorBuilder: (_,__,___) => Icon(Icons.directions_car, size: 80, color: AppTheme.textMuted))
              : Icon(Icons.directions_car, size: 80, color: AppTheme.textMuted),
          SizedBox(height: 16),
          Text(booking.car?['marque'] ?? 'Unknown Car', style: Theme.of(context).textTheme.displayMedium),
          Text(booking.car?['matricule'] ?? 'N/A', style: TextStyle(color: AppTheme.textMuted)),
          SizedBox(height: 24),
          
          Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.brandBlue, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pickup Location", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    Text(booking.pickupLocation ?? 'Location details not available', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.payment, color: AppTheme.success, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Price", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    Text("${booking.payment?['amount'] ?? '--'} DT", style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          
          if (isActiveTab && (booking.status.toUpperCase() == 'CONFIRMED' || booking.status.toUpperCase() == 'ACTIVE'))
            ElevatedButton.icon(
              onPressed: () async {
                final key = await ref.read(bookingProvider.notifier).generateNfcKey(booking.id);
                if (key != null) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => NFCKeyScreen(
                      bookingId: booking.id,
                      carId: booking.carId,
                      startDate: booking.startDate,
                      endDate: booking.endDate,
                      pickupLocation: booking.pickupLocation ?? 'N/A',
                      dropOffLocation: booking.dropoffLocation ?? 'N/A',
                      estimatedPrice: (booking.payment?['amount'] ?? 0).toDouble(),
                      nfcKey: key,
                    ),
                  ));
                } else {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to fetch NFC Key")));
                }
              },
              icon: Icon(Icons.nfc),
              label: Text("Access NFC Key"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 56),
                backgroundColor: AppTheme.brandBlue,
                foregroundColor: AppTheme.surfaceWhite,
              ),
            ),

          if (booking.status.toUpperCase() == 'COMPLETED' || booking.status.toUpperCase() == 'CONFIRMED' || booking.status.toUpperCase() == 'ACTIVE')
            Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final url = await ApiService.getContractUrl(booking.id);
                  if (url != null && await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  } else {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not open contract.")));
                  }
                },
                icon: Icon(Icons.description, color: AppTheme.brandBlue),
                label: Text("View Contract"),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56),
                  side: BorderSide(color: AppTheme.brandBlue, width: 2),
                  foregroundColor: AppTheme.brandBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: AppTheme.textMuted),
          ),
          SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.displaySmall),
          SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
