import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../../constants/api_config.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import './widgets/custom_text_field.dart';
import 'login_screen.dart';
import 'kyc_verification_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  File? _profileImage;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isVerified = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authState = ref.read(authProvider);
    final userId = authState.userId;

    if (userId == null) {
      setState(() {
        _errorMessage = "Session expired. Please log in again.";
      });
      return;
    }

    // If we already have user data from the provider, populate fields
    if (authState.user != null) {
      setState(() {
        _fullNameController.text = authState.user!.fullName;
        _emailController.text = authState.user!.email;
        _phoneController.text = authState.user!.phone ?? "";
        _isVerified = authState.user!.isVerified;
      });
      return;
    }

    // Otherwise fetch fresh
    try {
      final response = await http.get(Uri.parse("$userEndpoint/$userId"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data["user"] ?? data;

        setState(() {
          _fullNameController.text = user["fullName"] ?? "";
          _emailController.text = user["email"] ?? "";
          _phoneController.text = user["phone"] ?? "";
          _isVerified = user["isVerified"] ?? false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load profile";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Server connection failed. Check your network.";
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }



  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = ref.read(authProvider).userId;

      if (userId == null) {
        setState(() {
          _errorMessage = "Session expired. Please log in again.";
          _isLoading = false;
        });
        return;
      }

      try {
        const String baseUrl = "$userEndpoint";
        var uri = Uri.parse("$baseUrl/$userId");

        var request = http.MultipartRequest('PUT', uri);
        request.fields['phone'] = _phoneController.text.trim();

        if (_profileImage != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'photo',
            _profileImage!.path,
          ));
        }

        var response = await request.send();
        var responseData = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          // Clear the local selected file so the UI switches to loading the network image
          setState(() {
            _profileImage = null;
            _isLoading = false;
          });

          // Refresh user profile in the auth provider (this updates the UI automatically)
          await ref.read(authProvider.notifier).refreshUserProfile();
          await _loadUserProfile(); // Re-populate the text fields

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile Updated Successfully! ✅")),
            );
          }
        } else {
          var errorData = jsonDecode(responseData);
          setState(() {
            _errorMessage = "Profile update failed: ${errorData['message']}";
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = "Server connection failed. Check your network.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: AppBar(
        title: Text("My Profile", style: Theme.of(context).textTheme.displaySmall),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textMain),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_errorMessage != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                                SizedBox(width: 8),
                                Expanded(child: Text(_errorMessage!, style: TextStyle(color: AppTheme.danger, fontSize: 13))),
                              ],
                            ),
                          ),
                        ),

                      // Blacklist warning banner
                      if (user != null && user.isBlacklisted)
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                            border: Border.all(color: AppTheme.danger, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.block, color: AppTheme.danger, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Account Suspended", style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 16)),
                                    SizedBox(height: 4),
                                    Text("Your account has been flagged. Please contact support.", style: TextStyle(color: AppTheme.danger, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: 16),
                      _buildProfilePicture(),
                      SizedBox(height: 16),

                      // User name & email
                      if (user != null) ...[
                        Text(user.fullName, style: Theme.of(context).textTheme.displayMedium),
                        SizedBox(height: 4),
                        Text(user.email, style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                      ],

                      SizedBox(height: 16),
                      _buildVerificationBadge(),
                      SizedBox(height: 16),

                      // Stats row
                      if (user != null)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceWhite,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat("${user.nbrFoisAllocation}", "Rentals"),
                              Container(width: 1, height: 40, color: AppTheme.surfaceBorder),
                              _buildStat("${user.age}", "Age"),
                              Container(width: 1, height: 40, color: AppTheme.surfaceBorder),
                              _buildStat(
                                user.isBlacklisted ? "SUSPENDED" : "ACTIVE",
                                "Status",
                                color: user.isBlacklisted ? AppTheme.danger : AppTheme.success,
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: 24),

                      // KYC Upload Section
                      _buildKycSection(user),

                      SizedBox(height: 24),
                      _buildInfoCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.textMain,
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildKycSection(user) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 20, color: AppTheme.textMuted),
              SizedBox(width: 8),
              Text("KYC Verification", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textMain)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Complete your AI identity verification to start booking cars.",
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: (user?.isVerified == true) ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KycVerificationScreen()),
              );
            },
            icon: Icon(user?.isVerified == true ? Icons.check_circle : Icons.camera_alt),
            label: Text(user?.isVerified == true ? "Account Verified ✓" : "Start AI Verification"),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 48),
              backgroundColor: user?.isVerified == true ? AppTheme.success : AppTheme.brandBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    final user = ref.read(authProvider).user;
    return Hero(
      tag: 'profilePicture',
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceWhite,
                boxShadow: AppTheme.softShadow,
                border: Border.all(color: AppTheme.brandLight, width: 4),
              ),
              child: ClipOval(
                child: _profileImage != null
                    ? Image.file(_profileImage!, fit: BoxFit.cover)
                    : (user?.profilePicture != null && user!.profilePicture!.isNotEmpty
                        ? Image.network(user.profilePicture!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person_outline, size: 48, color: AppTheme.brandBlue))
                        : Icon(Icons.person_outline, size: 48, color: AppTheme.brandBlue)),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surfaceWhite, width: 2),
                ),
                child: Icon(Icons.camera_alt, color: AppTheme.surfaceWhite, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isVerified ? AppTheme.success.withOpacity(0.1) : AppTheme.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isVerified ? Icons.verified : Icons.error_outline,
            color: _isVerified ? AppTheme.success : AppTheme.danger,
            size: 18,
          ),
          SizedBox(width: 8),
          Text(
            _isVerified ? "Verified User" : "Not Verified",
            style: TextStyle(
              color: _isVerified ? AppTheme.success : AppTheme.danger,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Personal Information", style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: 24),
          _buildTextField(Icons.person_outline, "Full Name", _fullNameController, "Enter your full name"),
          SizedBox(height: 20),
          _buildTextField(Icons.email_outlined, "Email", _emailController, "Enter your email", readOnly: true),
          SizedBox(height: 20),
          _buildTextField(Icons.phone_outlined, "Phone Number", _phoneController, "Enter your phone number"),
          SizedBox(height: 32),
          _buildSaveButton(),
          SizedBox(height: 16),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildTextField(IconData icon, String label, TextEditingController controller, String hint, {bool readOnly = false}) {
    return CustomTextField(
      controller: controller,
      hintText: label,
      icon: icon,
      readOnly: readOnly,
      validator: (value) => value == null || value.isEmpty ? "$label is required" : null,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveProfile,
      child: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: AppTheme.surfaceWhite, strokeWidth: 2),
            )
          : Text("Save Changes"),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 56),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
              title: Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text("Are you sure you want to logout?"),
              actions: [
                TextButton(
                  child: Text("Cancel", style: TextStyle(color: AppTheme.textMuted)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text("Logout", style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _logout();
                  },
                ),
              ],
            );
          },
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.danger,
        side: BorderSide(color: AppTheme.danger.withOpacity(0.5)),
        minimumSize: Size(double.infinity, 56),
      ),
      child: Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppTheme.surfaceWhite,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.brandLight, shape: BoxShape.circle),
                    child: Icon(Icons.camera_alt_outlined, color: AppTheme.brandBlue),
                  ),
                  title: Text("Take Photo", style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    _pickImage(ImageSource.camera);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.brandLight, shape: BoxShape.circle),
                    child: Icon(Icons.photo_library_outlined, color: AppTheme.brandBlue),
                  ),
                  title: Text("Choose from Gallery", style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
