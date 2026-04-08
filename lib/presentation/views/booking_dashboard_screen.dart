import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class BookingDashboardScreen extends StatefulWidget {
  @override
  _BookingDashboardScreenState createState() => _BookingDashboardScreenState();
}

class _BookingDashboardScreenState extends State<BookingDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _activeBookings = [];
  List<dynamic> _historyBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("userId");
      
      if (userId == null) {
         setState(() => _isLoading = false);
         return;
      }

      var bookingData = await ApiService.getMyBookings(userId);

      setState(() {
        _activeBookings = bookingData['active'] ?? [];
        _historyBookings = bookingData['history'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching bookings: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: AppTheme.brandBlue))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildActiveTab() {
    if (_activeBookings.isEmpty) {
      return _buildEmptyState(Icons.car_rental, "No active rentals", "You don't have any ongoing or upcoming rentals.");
    }
    
    // For simplicity, just display the first active booking
    var booking = _activeBookings.first;
    var car = booking['car'] ?? {};
    
    // Countdown logic dummy
    DateTime endDate = DateTime.parse(booking['endDate']);
    Duration remaining = endDate.difference(DateTime.now());
    String timeRemaining = remaining.isNegative ? "Expired" : "${remaining.inDays}d ${remaining.inHours % 24}h ${remaining.inMinutes % 60}m";

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: AppTheme.softShadow,
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "ACTIVE RENTAL",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      timeRemaining,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                car['photo'] != null && car['photo'].isNotEmpty
                    ? Image.network(car['photo'], height: 120, fit: BoxFit.contain, errorBuilder: (_,__,___) => Icon(Icons.directions_car, size: 80, color: AppTheme.textMuted))
                    : Icon(Icons.directions_car, size: 80, color: AppTheme.textMuted),
                SizedBox(height: 16),
                Text(
                  car['marque'] ?? 'Unknown Car',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                Text(
                  car['matricule'] ?? 'N/A',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
                SizedBox(height: 24),
                
                // Location Details
                Row(
                  children: [
                    Icon(Icons.location_on, color: AppTheme.brandBlue, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pickup Location", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          Text(booking['pickupLocation'] ?? 'Location details not available', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to NFCKeyScreen if exists, or show placeholder
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Accessing NFC Key...")));
                  },
                  icon: Icon(Icons.nfc),
                  label: Text("Access NFC Key"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 56),
                    backgroundColor: AppTheme.brandBlue,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
     if (_historyBookings.isEmpty) {
      return _buildEmptyState(Icons.history, "No rental history", "Your past trips will appear here.");
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _historyBookings.length,
      itemBuilder: (context, index) {
        var booking = _historyBookings[index];
        var car = booking['car'] ?? {};
        var startDate = DateTime.parse(booking['startDate']);
        var formattedDate = DateFormat('MMM dd, yyyy').format(startDate);
        
        bool isCompleted = booking['status'] == 'COMPLETED';
        var statusColor = isCompleted ? AppTheme.success : AppTheme.textMuted;

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                 car['photo'] != null && car['photo'].isNotEmpty
                    ? Image.network(car['photo'], width: 60, height: 40, fit: BoxFit.contain, errorBuilder: (_,__,___) => Icon(Icons.directions_car, color: AppTheme.textMuted))
                    : Icon(Icons.directions_car, size: 40, color: AppTheme.textMuted),
                 SizedBox(width: 16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(car['marque'] ?? 'Unknown Car', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                       Text(formattedDate, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                     ],
                   ),
                 ),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     Text("${booking['payment']?['amount'] ?? '--'} TND", style: TextStyle(fontWeight: FontWeight.w700)),
                     SizedBox(height: 4),
                     Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking['status'] ?? 'N/A',
                        style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                   ],
                 )
              ],
            ),
          ),
        );
      },
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
