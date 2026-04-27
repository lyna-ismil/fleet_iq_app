import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import '../../constants/theme.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'estimation_screen.dart';

class KycVerificationScreen extends ConsumerStatefulWidget {
  final String? carId;
  final String? pickupLocation;

  const KycVerificationScreen({super.key, this.carId, this.pickupLocation});

  @override
  ConsumerState<KycVerificationScreen> createState() =>
      _KycVerificationScreenState();
}

class _KycVerificationScreenState
    extends ConsumerState<KycVerificationScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _cinFront;
  File? _cinBack;
  File? _permis;
  File? _selfie;

  bool _isProcessing = false;

  bool get _allCaptured =>
      _cinFront != null &&
      _cinBack != null &&
      _permis != null &&
      _selfie != null;

  Future<void> _pickImage(ImageSource source, String slot) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked == null) return;

      setState(() {
        switch (slot) {
          case 'cin_front':
            _cinFront = File(picked.path);
            break;
          case 'cin_back':
            _cinBack = File(picked.path);
            break;
          case 'permis':
            _permis = File(picked.path);
            break;
          case 'selfie':
            _selfie = File(picked.path);
            break;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture image: $e')),
      );
    }
  }

  Future<void> _processKyc() async {
    if (!_allCaptured) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Call the Python KYC microservice
      final result = await ApiService.processKyc(
        _cinFront!,
        _cinBack!,
        _permis!,
        _selfie!,
      );

      if (!mounted) return;

      final bool verified = result['verified'] ?? false;
      final List<dynamic> reasons = result['failure_reasons'] ?? [];
      final String? extractedCin = result['extracted_cin'];

      if (verified && extractedCin != null) {
        // 2. Persist verified status in the Node.js backend
        final userId = ref.read(authProvider).userId!;
        await ApiService.markUserAsVerified(userId, extractedCin);

        // 3. Refresh local auth state
        await ref.read(authProvider.notifier).refreshUserProfile();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Identity verified successfully!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
          ),
        );

        // 4. Navigate to next step
        if (widget.carId != null && widget.pickupLocation != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EstimationScreen(
                carId: widget.carId!,
                pickupLocation: widget.pickupLocation!,
              ),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      } else {
        // Show failure dialog with reasons from the API
        _showFailureDialog(reasons.map((e) => e.toString()).toList());
      }
    } catch (e) {
      if (!mounted) return;
      _showFailureDialog(['Connection error: $e']);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showFailureDialog(List<String> reasons) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        ),
        contentPadding: EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  color: AppTheme.danger, size: 48),
            ),
            SizedBox(height: 20),
            Text(
              'Verification Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
              ),
            ),
            SizedBox(height: 12),
            ...reasons.map(
              (r) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.close, color: AppTheme.danger, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surfaceWhite,
        iconTheme: IconThemeData(color: AppTheme.textMain),
        title: Text(
          'Identity Verification',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  FadeInDown(
                    duration: Duration(milliseconds: 600),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.brandBlue,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radius2xl),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceWhite.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_user_outlined,
                              size: 36,
                              color: AppTheme.surfaceWhite,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Quick AI Verification',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.surfaceWhite,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Takes less than 5 seconds using AI.\nCapture 4 photos to verify your identity.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.surfaceWhite.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 28),

                  // Document capture cards
                  FadeInUp(
                    duration: Duration(milliseconds: 650),
                    delay: Duration(milliseconds: 100),
                    child: _buildCaptureCard(
                      slot: 'cin_front',
                      title: 'Front of ID Card',
                      subtitle: 'CIN — face & info side',
                      icon: Icons.badge_outlined,
                      file: _cinFront,
                      useCamera: true,
                    ),
                  ),
                  SizedBox(height: 16),
                  FadeInUp(
                    duration: Duration(milliseconds: 650),
                    delay: Duration(milliseconds: 200),
                    child: _buildCaptureCard(
                      slot: 'cin_back',
                      title: 'Back of ID Card',
                      subtitle: 'CIN — barcode side',
                      icon: Icons.flip_outlined,
                      file: _cinBack,
                      useCamera: true,
                    ),
                  ),
                  SizedBox(height: 16),
                  FadeInUp(
                    duration: Duration(milliseconds: 650),
                    delay: Duration(milliseconds: 300),
                    child: _buildCaptureCard(
                      slot: 'permis',
                      title: "Driver's License",
                      subtitle: 'Permis de Conduire',
                      icon: Icons.drive_eta_outlined,
                      file: _permis,
                      useCamera: true,
                    ),
                  ),
                  SizedBox(height: 16),
                  FadeInUp(
                    duration: Duration(milliseconds: 650),
                    delay: Duration(milliseconds: 400),
                    child: _buildCaptureCard(
                      slot: 'selfie',
                      title: 'Live Selfie',
                      subtitle: 'Front camera — look straight',
                      icon: Icons.face_outlined,
                      file: _selfie,
                      useCamera: true,
                      isFrontCamera: true,
                    ),
                  ),

                  SizedBox(height: 32),

                  // Verify button
                  FadeInUp(
                    duration: Duration(milliseconds: 700),
                    delay: Duration(milliseconds: 500),
                    child: ElevatedButton(
                      onPressed: _allCaptured && !_isProcessing
                          ? _processKyc
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 56),
                        disabledBackgroundColor:
                            AppTheme.surfaceBorder,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_outlined),
                          SizedBox(width: 8),
                          Text('Verify Identity'),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 48),
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radius2xl),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          color: AppTheme.brandBlue,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'AI is analyzing your documents...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMain,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Cross-matching CIN, verifying face\nand checking liveness.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                          height: 1.5,
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

  Widget _buildCaptureCard({
    required String slot,
    required String title,
    required String subtitle,
    required IconData icon,
    required File? file,
    bool useCamera = true,
    bool isFrontCamera = false,
  }) {
    final bool captured = file != null;

    return GestureDetector(
      onTap: _isProcessing
          ? null
          : () => _pickImage(
                useCamera ? ImageSource.camera : ImageSource.gallery,
                slot,
              ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: captured
              ? AppTheme.success.withOpacity(0.05)
              : AppTheme.surfaceGray,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: captured ? AppTheme.success : AppTheme.surfaceBorder,
            width: captured ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail or icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: captured
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: captured
                      ? AppTheme.success.withOpacity(0.3)
                      : AppTheme.surfaceBorder,
                ),
              ),
              child: captured
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                        width: 64,
                        height: 64,
                      ),
                    )
                  : Icon(icon, color: AppTheme.textMuted, size: 28),
            ),
            SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMain,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    captured ? 'Captured ✓ — Tap to retake' : subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: captured ? AppTheme.success : AppTheme.textMuted,
                      fontWeight:
                          captured ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Action
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: captured
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.brandBlue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                captured ? Icons.check_circle : Icons.camera_alt_outlined,
                color: captured ? AppTheme.success : AppTheme.brandBlue,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
