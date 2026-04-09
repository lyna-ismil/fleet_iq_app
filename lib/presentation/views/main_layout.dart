import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/theme.dart';
import '../../providers/notification_provider.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'booking_dashboard_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    _WalletPlaceholder(),
    BookingDashboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final badgeCount = ref.watch(unreadBadgeCountProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Current screen
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Floating bottom navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              margin: EdgeInsets.only(bottom: 24, left: 24, right: 24),
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(50),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    index: 0,
                    activeIcon: Icons.home_filled,
                    inactiveIcon: Icons.home_outlined,
                    label: "Home",
                  ),
                  _buildNavItem(
                    index: 1,
                    activeIcon: Icons.account_balance_wallet,
                    inactiveIcon: Icons.account_balance_wallet_outlined,
                    label: "Wallet",
                  ),
                  _buildNavItem(
                    index: 2,
                    activeIcon: Icons.history,
                    inactiveIcon: Icons.history,
                    label: "Bookings",
                    badgeCount: badgeCount,
                  ),
                  _buildNavItem(
                    index: 3,
                    activeIcon: Icons.person,
                    inactiveIcon: Icons.person_outline,
                    label: "Profile",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    int badgeCount = 0,
  }) {
    bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.2 : 1.0,
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Icon(
                    isActive ? activeIcon : inactiveIcon,
                    color: isActive ? AppTheme.brandBlue : AppTheme.textMuted,
                    size: 26,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: TextStyle(
                          color: AppTheme.surfaceWhite,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.brandBlue : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder screen for Wallet tab
class _WalletPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: AppBar(
        title: Text("Wallet", style: Theme.of(context).textTheme.displaySmall),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.brandLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppTheme.brandBlue,
                  size: 48,
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Wallet",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              SizedBox(height: 8),
              Text(
                "Payment methods & transactions\ncoming soon.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
