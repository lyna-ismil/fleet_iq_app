import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/car_provider.dart';
import '../../models/car.dart';
import '../../providers/notification_provider.dart';
import 'login_screen.dart';
import 'estimation_screen.dart';
import 'profile_screen.dart';
import 'reclamation_screen.dart';
import 'AboutUsScreen.dart';
import 'notifications_screen.dart';
import 'widgets/skeleton_loader.dart';
import 'widgets/error_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  LatLng? _userLocation;
  final MapController _mapController = MapController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _getUserLocation();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    // Auto-refresh paired cars every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(pairedCarsProvider);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_userLocation!, 13);
      }
    } catch (e) {
      print("Error fetching location: $e");
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

  Widget _buildMapWithMarkers(List<Car> availableCars) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? LatLng(36.8065, 10.1815),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.example.fleetiq',
              ),
              MarkerLayer(
                markers: availableCars
                    .where((car) => car.lastKnownLocation != null)
                    .map((car) {
                      final lat = car.lastKnownLocation!.latitude;
                      final lng = car.lastKnownLocation!.longitude;

                      return Marker(
                        point: LatLng(lat, lng),
                        width: 60,
                        height: 60,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            var pinColor = AppTheme.success;
                            var pinIcon = Icons.directions_car;
                            if (car.healthStatus == "WARN") {
                              pinColor = Colors.orange;
                              pinIcon = Icons.warning_amber_rounded;
                            } else if (car.healthStatus == "CRITICAL") {
                              pinColor = AppTheme.danger;
                              pinIcon = Icons.error_outline;
                            }
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
                                    border: Border.all(color: pinColor, width: 2),
                                  ),
                                  padding: EdgeInsets.all(8),
                                  child: Icon(pinIcon, color: pinColor, size: 24),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    })
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
                  if (_userLocation != null) {
                    _mapController.move(_userLocation!, 14);
                  } else {
                    _getUserLocation();
                  }
                },
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.softShadow,
              ),
              child: IconButton(
                icon: Icon(Icons.refresh, color: AppTheme.textMain),
                onPressed: () {
                  ref.invalidate(pairedCarsProvider);
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

  Widget _buildCarDetailsSheet(Car car) {
    String distanceStr = "Unknown dist";
    if (car.calculatedDistance != null) {
      double d = car.calculatedDistance!;
      if (d > 1000) {
        distanceStr = "${(d / 1000).toStringAsFixed(1)} km away";
      } else {
        distanceStr = "${d.toInt()} m away";
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                    // Premium Photo Frame
                    Center(
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceGray,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          child: (car.photo != null && car.photo!.isNotEmpty)
                            ? Image.network(
                                car.photo!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(Icons.directions_car, size: 80, color: AppTheme.textMuted),
                              )
                            : Icon(Icons.directions_car, size: 80, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    Text(
                      car.marque,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    Text(
                      car.matricule,
                      style: TextStyle(fontSize: 16, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.brandBlue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, color: AppTheme.brandBlue, size: 16),
                              SizedBox(width: 4),
                              Text(distanceStr, style: TextStyle(fontSize: 14, color: AppTheme.brandBlue, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: car.healthStatus == "OK" ? AppTheme.success.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(car.healthStatus, style: TextStyle(fontSize: 14, color: car.healthStatus == "OK" ? AppTheme.success : Colors.orange, fontWeight: FontWeight.w600)),
                        ),
                        SizedBox(width: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceGray,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(car.energyType, style: TextStyle(fontSize: 14, color: AppTheme.textMain, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    
                    if (car.cityRestriction) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.starRating.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.starRating),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppTheme.starRating),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "City Restrictions: ${car.allowedCities.isEmpty ? 'Regional only' : car.allowedCities.join(', ')}",
                                style: TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            )
                          ],
                        ),
                      )
                    ],

                    if (car.description != null && car.description!.isNotEmpty) ...[
                      SizedBox(height: 24),
                      Text("Description", style: Theme.of(context).textTheme.bodyLarge),
                      SizedBox(height: 8),
                      Text(car.description!, style: TextStyle(color: AppTheme.textMuted, height: 1.5)),
                    ],

                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        if (!mounted) return;
                        
                        String pickupLocation = car.lastKnownLocation != null
                            ? "${car.lastKnownLocation!.latitude},${car.lastKnownLocation!.longitude}"
                            : '';
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EstimationScreen(
                              carId: car.id,
                              pickupLocation: pickupLocation,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 56)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car),
                          SizedBox(width: 8),
                          Text('Book This Premium Car'),
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



  void _logout() async {
    await ref.read(authProvider.notifier).logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for user info (drawer)
    final authState = ref.watch(authProvider);
    final userName = authState.user?.fullName ?? "User";
    final userEmail = authState.user?.email ?? "email@example.com";

    // Watch paired cars
    final carsAsync = ref.watch(pairedCarsProvider);

    // Watch unread notification badge
    final badgeCount = ref.watch(unreadBadgeCountProvider);

    // Convert Car models back to Map for existing marker/sheet code
    final availableCars = carsAsync.when(
      data: (cars) {
        final filtered = cars.where((c) => c.isPaired && c.isAvailable).toList();
        for (var c in filtered) {
          if (_userLocation != null && c.lastKnownLocation != null) {
            final distance = const Distance();
            c.calculatedDistance = distance.as(
              LengthUnit.Meter, _userLocation!, c.lastKnownLocation!,
            ).toDouble();
          }
        }
        return filtered;
      },
      loading: () => <Car>[],
      error: (_, __) => <Car>[],
    );

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
            child: Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none, color: AppTheme.textMain),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  },
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: TextStyle(
                          color: AppTheme.surfaceWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, userName, userEmail),
      body: SafeArea(
        child: Column(
          children: [
            buildStepIndicator(),
            Expanded(
              child: carsAsync.when(
                data: (_) {
                  return Stack(
                    children: [
                      _buildMapWithMarkers(availableCars),
                      if (availableCars.isEmpty)
                        Positioned.fill(
                          child: Container(
                            color: AppTheme.surfaceWhite.withOpacity(0.7),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(28),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceWhite,
                                      shape: BoxShape.circle,
                                      boxShadow: AppTheme.softShadow,
                                    ),
                                    child: Icon(Icons.directions_car_outlined, size: 56, color: AppTheme.textMuted),
                                  ),
                                  SizedBox(height: 24),
                                  Text("No cars available near you", style: Theme.of(context).textTheme.displaySmall),
                                  SizedBox(height: 8),
                                  Text("Try zooming out or refreshing.", style: TextStyle(color: AppTheme.textMuted)),
                                  SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _mapController.move(
                                        _userLocation ?? LatLng(36.8065, 10.1815),
                                        10,
                                      );
                                      ref.invalidate(pairedCarsProvider);
                                    },
                                    icon: Icon(Icons.zoom_out_map),
                                    label: Text("Zoom Out"),
                                    style: ElevatedButton.styleFrom(minimumSize: Size(180, 48)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => SkeletonList(itemCount: 2, itemHeight: 160),
                error: (e, _) => ErrorState(
                  message: 'Failed to load cars. Please check your network.',
                  onRetry: () => ref.invalidate(pairedCarsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String userName, String userEmail) {
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
