import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../constants/theme.dart';

class AboutUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surfaceWhite,
        iconTheme: IconThemeData(color: AppTheme.textMain),
        title: Text(
          "About Us",
          style: Theme.of(context).textTheme.displaySmall,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildHeader(context),
              SizedBox(height: 32),
              _buildContent(context),
              SizedBox(height: 40),
              _buildSocialLinks(context),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.brandBlue,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car,
              size: 48,
              color: AppTheme.surfaceWhite,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          SizedBox(height: 24),
          Text(
            "Fleet IQ",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.surfaceWhite,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2),
          SizedBox(height: 8),
          Text(
            "Revolutionizing Premium Mobility",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.surfaceWhite.withOpacity(0.8),
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        boxShadow: AppTheme.softShadow,
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSection(
            context,
            "Our Mission",
            "Fleet IQ is dedicated to providing a seamless, secure, and smart car rental experience through cutting-edge AIoT technology and exceptional customer service.",
            Icons.rocket_launch_outlined,
          ),
          SizedBox(height: 24),
          Divider(color: AppTheme.surfaceBorder),
          SizedBox(height: 24),
          _buildSection(
            context,
            "Our Vision",
            "To be the leading global platform for innovative and reliable transportation solutions, empowering people to explore the world with ease and confidence.",
            Icons.remove_red_eye_outlined,
          ),
          SizedBox(height: 24),
          Divider(color: AppTheme.surfaceBorder),
          SizedBox(height: 24),
          _buildSection(
            context,
            "Why Choose Us?",
            "• Quick and easy bookings\n• Wide range of premium vehicles\n• Competitive prices\n• 24/7 dedicated support\n• Contactless NFC rentals",
            Icons.check_circle_outline,
          ),
          SizedBox(height: 24),
          Divider(color: AppTheme.surfaceBorder),
          SizedBox(height: 24),
          _buildSection(
            context,
            "Contact Us",
            "Email: contact@NexDrive.com\nPhone: +216 123 456 789\nAddress: Tunis, Tunisia",
            Icons.contact_mail_outlined,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.brandLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              ),
              child: Icon(icon, color: AppTheme.brandBlue, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textMain,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Text(
            content,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinks(BuildContext context) {
    return Column(
      children: [
        Text(
          "Connect With Us",
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(FontAwesomeIcons.facebookF, Color(0xFF1877F2)),
            SizedBox(width: 24),
            _buildSocialIcon(FontAwesomeIcons.twitter, Color(0xFF1DA1F2)),
            SizedBox(width: 24),
            _buildSocialIcon(FontAwesomeIcons.instagram, Color(0xFFE4405F)),
          ],
        ).animate().fadeIn(duration: 600.ms, delay: 800.ms),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        shape: BoxShape.circle,
        boxShadow: AppTheme.softShadow,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
