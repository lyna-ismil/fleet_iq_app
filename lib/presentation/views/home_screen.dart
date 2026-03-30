import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../constants/theme.dart';
import 'login_screen.dart';
import 'estimation_screen.dart';
import 'profile_screen.dart';
import 'reclamation_screen.dart';
import 'AboutUsScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String userName = "User";
  String userEmail = "email@example.com";
  List<Map<String, dynamic>> availableCars = [];
  late AnimationController _animationController;
  late Animation<double> _animation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchAvailableCars();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("userId");

      if (userId == null) {
        setState(() {
          userName = "User";
          userEmail = "email@example.com";
        });
        return;
      }

      var userData = await ApiService.getUserProfile(userId);

      if (userData != null) {
        setState(() {
          userName = userData["fullName"] ?? "User";
          userEmail = userData["email"] ?? "email@example.com";
        });
      }
    } catch (e) {
      print("❌ Error loading user data: $e");
    }
  }

  Future<void> fetchAvailableCars() async {
    try {
      List<Map<String, dynamic>> cars = await ApiService.getAvailableCars();
      setState(() => availableCars = cars);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading available cars'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget buildStepIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepItem(Icons.directions_car, 'Car', true),
          _buildStepDivider(),
          _buildStepItem(Icons.date_range, 'Date', false),
          _buildStepDivider(),
          _buildStepItem(Icons.info_outline, 'Info', false),
          _buildStepDivider(),
          _buildStepItem(Icons.check_circle_outline, 'Confirm', false),
          _buildStepDivider(),
          _buildStepItem(Icons.payment, 'Pay', false),
        ],
      ),
    );
  }

  Widget _buildStepItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.brandBlue : AppTheme.surfaceGray,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? AppTheme.surfaceWhite : AppTheme.textMuted,
            size: 20,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppTheme.brandBlue : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 10,
      height: 1,
      color: AppTheme.surfaceBorder,
    );
  }

  Widget _buildMapWithMarkers() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(36.8065, 10.1815),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fleetiq',
              ),
              MarkerLayer(
                markers: availableCars
                    .where((car) =>
                        car['location'] != null && car['car_work'] == true)
                    .map((car) {
                      double latitude = 0.0;
                      double longitude = 0.0;

                      if (car['location'] is Map) {
                        latitude = double.tryParse(
                                car['location']['latitude'].toString()) ??
                            0.0;
                        longitude = double.tryParse(
                                car['location']['longitude'].toString()) ??
                            0.0;
                      } else if (car['location'] is String) {
                        var parts = car['location'].split(',');
                        if (parts.length == 2) {
                          latitude = double.tryParse(parts[0].trim()) ?? 0.0;
                          longitude = double.tryParse(parts[1].trim()) ?? 0.0;
                        }
                      }

                      if (latitude == 0.0 && longitude == 0.0) return null;

                      return Marker(
                        point: LatLng(latitude, longitude),
                        width: 60,
                        height: 60,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (ctx) =>
                                        _buildCarDetailsSheet(car),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceWhite,
                                    shape: BoxShape.circle,
                                    boxShadow: AppTheme.softShadow,
                                  ),
                                  padding: EdgeInsets.all(8),
                                  child: Image.network(
                                    'https://cdn-icons-png.flaticon.com/512/5385/5385430.png',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.directions_car,
                                          color: AppTheme.brandBlue, size: 40);
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    })
                    .whereType<Marker>()
                    .toList(),
              ),
            ],
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.softShadow,
              ),
              child: IconButton(
                icon: Icon(Icons.my_location, color: AppTheme.textMain),
                onPressed: () {
                  // Center map on user location
                },
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, 1),
                    end: Offset.zero,
                  ).animate(_animation),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.brandBlue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Tap on a car to view details and book",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarDetailsSheet(Map<String, dynamic> car) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 5,
            width: 40,
            margin: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBorder,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.brandLight,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.directions_car_outlined,
                              size: 60,
                              color: AppTheme.brandBlue,
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                car['marque'] ?? 'Unknown Car',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: AppTheme.success, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      "Available",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.success,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    _buildDetailItem(Icons.credit_card, "Matricule",
                        car['matricule'] ?? 'N/A'),
                    Divider(height: 32, color: AppTheme.surfaceBorder),
                    _buildDetailItem(
                        Icons.location_on, "Location", "Current location"),
                    SizedBox(height: 24),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceGray,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      ),
                      child: Center(
                        child: Text(
                          "Map Preview Placeholder",
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setString("selectedCarId", car['_id']);

                        if (!mounted) return;

                        String pickupLocation = '';
                        if (car['location'] is String) {
                          pickupLocation = car['location'];
                        } else if (car['location'] is Map &&
                            car['location']['latitude'] != null &&
                            car['location']['longitude'] != null) {
                          pickupLocation =
                              "${car['location']['latitude']},${car['location']['longitude']}";
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EstimationScreen(
                              carId: car['_id'],
                              pickupLocation: pickupLocation,
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
                          Icon(Icons.directions_car),
                          SizedBox(width: 8),
                          Text('Book This Car'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.brandLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.brandBlue),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
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
      ],
    );
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("userId");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.surfaceGray,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surfaceWhite,
        iconTheme: IconThemeData(color: AppTheme.textMain),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.brandLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.directions_car, color: AppTheme.brandBlue),
            ),
            SizedBox(width: 8),
            Text(
              "NexDrive",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMain,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: AppTheme.textMain),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceGray,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.notifications_none, color: AppTheme.textMain),
              onPressed: () {
                // Show notifications
              },
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            buildStepIndicator(),
            Expanded(
              child: _buildMapWithMarkers(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppTheme.surfaceWhite,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGray,
                border: Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.brandBlue, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: AppTheme.brandLight,
                      child: Icon(Icons.person, color: AppTheme.brandBlue, size: 36),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    userName,
                    style: TextStyle(
                      color: AppTheme.textMain,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, color: AppTheme.textMuted, size: 16),
                      SizedBox(width: 8),
                      Text(
                        userEmail,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            _buildDrawerItem(context, Icons.person_outline, 'Profile', ProfileScreen()),
            _buildDrawerItem(
                context, Icons.headset_mic_outlined, 'Support', ReclamationScreen()),
            Divider(color: AppTheme.surfaceBorder),
            _buildDrawerItem(context, Icons.info_outline, 'About Us', AboutUsScreen()),
            Divider(color: AppTheme.surfaceBorder),
            _buildDrawerItem(context, Icons.exit_to_app, 'Logout', null,
                onTap: _logout),
            SizedBox(height: 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.brandLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.support_agent, color: AppTheme.brandBlue),
                        SizedBox(width: 8),
                        Text(
                          "Need Help?",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandBlue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Our team is available 24/7",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.brandBlue,
                      ),
                    ),
                    SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ReclamationScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.brandBlue,
                        side: BorderSide(color: AppTheme.brandBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                        ),
                        minimumSize: Size(double.infinity, 40),
                      ),
                      child: Text("Contact Support"),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, Widget? screen,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.textMain, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textMain,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
      onTap: () {
        if (onTap != null) {
          onTap();
        } else if (screen != null) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => screen));
        }
      },
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
