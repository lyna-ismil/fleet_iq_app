import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../../constants/api_config.dart';
import '../../constants/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/api_service.dart';
import './widgets/custom_text_field.dart';
import './widgets/skeleton_loader.dart';

class ReclamationScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ReclamationScreen> createState() => _ReclamationScreenState();
}

class _ReclamationScreenState extends ConsumerState<ReclamationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  bool _loadingTickets = false;
  String? _errorMessage;
  String? _selectedBookingId;

  late TabController _tabController;
  List<Map<String, dynamic>> _existingTickets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch bookings for dropdown and existing tickets
    Future.microtask(() {
      ref.read(bookingProvider.notifier).fetchBookings();
      _loadExistingTickets();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingTickets() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;
    setState(() => _loadingTickets = true);
    try {
      final tickets = await ApiService.getMyReclamations(userId);
      setState(() {
        _existingTickets = tickets;
        _loadingTickets = false;
      });
    } catch (e) {
      setState(() => _loadingTickets = false);
    }
  }

  // Select an image
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Submit Reclamation
  void _submitReclamation() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userId = ref.read(authProvider).userId;

        if (userId == null || userId.isEmpty) {
          setState(() {
            _errorMessage = "User session expired. Please log in again.";
            _isLoading = false;
          });
          return;
        }

        const String baseUrl = "$userEndpoint/reclamations";
        var uri = Uri.parse(baseUrl);
        var request = http.MultipartRequest("POST", uri);

        request.fields["id_user"] = userId;
        request.fields["message"] = _descriptionController.text.trim();
        request.fields["title"] = _titleController.text.trim();
        if (_selectedBookingId != null) {
          request.fields["bookingId"] = _selectedBookingId!;
        }

        if (_image != null) {
          request.files.add(
            await http.MultipartFile.fromPath('image', _image!.path),
          );
        }

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          setState(() {
            _descriptionController.clear();
            _titleController.clear();
            _image = null;
            _selectedBookingId = null;
            _isLoading = false;
          });

          _showSuccessDialog();
          _loadExistingTickets();
        } else {
          var errorData = jsonDecode(response.body);
          setState(() {
            _errorMessage = "Reclamation failed: ${errorData['message']}";
            _isLoading = false;
          });
          _showErrorSnackBar(_errorMessage!);
        }
      } catch (e) {
        print("Error: $e");
        setState(() {
          _errorMessage = "Server connection failed. Check your network.";
          _isLoading = false;
        });
        _showErrorSnackBar(_errorMessage!);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          ),
          backgroundColor: AppTheme.surfaceWhite,
          child: Container(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.success,
                    size: 64,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  "Success!",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.success,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Your request has been submitted successfully.\nWe'll get back to you soon.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _tabController.animateTo(1); // Switch to tickets tab
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 56),
                  ),
                  child: Text("View My Tickets"),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Color _ticketStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'OPEN': return Colors.amber;
      case 'IN_PROGRESS': return AppTheme.brandBlue;
      case 'RESOLVED': return AppTheme.success;
      case 'CLOSED': return AppTheme.textMuted;
      default: return AppTheme.textMuted;
    }
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
          "Support",
          style: Theme.of(context).textTheme.displaySmall,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.brandBlue,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.brandBlue,
          indicatorWeight: 3,
          tabs: [
            Tab(text: "New Request"),
            Tab(text: "My Tickets"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewRequestTab(),
          _buildTicketsTab(),
        ],
      ),
    );
  }

  Widget _buildNewRequestTab() {
    final bookingState = ref.watch(bookingProvider);

    // Get all bookings (active + history) for dropdown
    final allBookings = [...bookingState.active, ...bookingState.history];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card with illustration
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
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.brandLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.support_agent_outlined,
                        size: 48,
                        color: AppTheme.brandBlue,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "How Can We Help You?",
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Fill out the form below and our support team will get back to you as soon as possible",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Form card
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                boxShadow: AppTheme.softShadow,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Request Details", Icons.description_outlined),
                    SizedBox(height: 24),

                    // Booking ID dropdown
                    if (allBookings.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedBookingId,
                        decoration: InputDecoration(
                          hintText: "Related Booking (optional)",
                          prefixIcon: Icon(Icons.confirmation_number_outlined, color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.surfaceGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: allBookings.map((b) {
                          final carName = b.car?['marque'] ?? 'Unknown';
                          final dateLabel = '${b.startDate.day}/${b.startDate.month}';
                          return DropdownMenuItem<String>(
                            value: b.id,
                            child: Text("$carName — $dateLabel", overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedBookingId = val),
                      ),
                      SizedBox(height: 20),
                    ],

                    // Title field
                    CustomTextField(
                      controller: _titleController,
                      hintText: "Title (e.g., App Crash)",
                      icon: Icons.title,
                      validator: (value) =>
                          value == null || value.isEmpty ? "Title is required" : null,
                    ),
                    SizedBox(height: 20),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Please describe your issue in detail...",
                        filled: true,
                        fillColor: AppTheme.surfaceGray,
                        contentPadding: EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          borderSide: BorderSide(color: AppTheme.brandBlue, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          borderSide: BorderSide(color: AppTheme.danger, width: 1),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Description is required" : null,
                    ),
                    
                    SizedBox(height: 32),

                    // Image attachment section
                    _buildSectionHeader("Attachments", Icons.attach_file),
                    SizedBox(height: 8),
                    Text(
                      "Add photos to help us understand your issue better (optional)",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SizedBox(height: 16),
                    _buildImagePicker(),
                    SizedBox(height: 40),

                    // Submit button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitReclamation,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 56),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppTheme.surfaceWhite,
                                strokeWidth: 2,
                              ),
                            )
                          : Text("Submit Request"),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Contact info card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.brandBlue,
                borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.phone_in_talk_outlined,
                        color: AppTheme.surfaceWhite, size: 28),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Need urgent help?",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.surfaceWhite,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Call us at +(216) 94 971 606",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.surfaceWhite.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsTab() {
    if (_loadingTickets) {
      return SkeletonList(itemCount: 3, itemHeight: 100);
    }

    if (_existingTickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadExistingTickets,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
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
                    child: Icon(Icons.support_agent_outlined, size: 56, color: AppTheme.textMuted),
                  ),
                  SizedBox(height: 24),
                  Text("No tickets submitted", style: Theme.of(context).textTheme.displaySmall),
                  SizedBox(height: 8),
                  Text("Your support requests will appear here.", style: TextStyle(color: AppTheme.textMuted)),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(0),
                    icon: Icon(Icons.add),
                    label: Text("Submit One"),
                    style: ElevatedButton.styleFrom(minimumSize: Size(200, 48)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExistingTickets,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _existingTickets.length,
        itemBuilder: (ctx, i) {
          final ticket = _existingTickets[i];
          final status = (ticket['status'] ?? 'OPEN').toString().toUpperCase();
          final statusColor = _ticketStatusColor(status);
          final adminName = ticket['assignedAdminName'] ?? ticket['assignedAdminId'];
          final title = ticket['title'] ?? ticket['message'] ?? 'Untitled';
          final createdAt = ticket['createdAt'] != null
              ? DateTime.tryParse(ticket['createdAt'].toString())
              : null;

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            color: AppTheme.surfaceWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    ticket['message'] ?? '',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      if (createdAt != null) ...[
                        Icon(Icons.access_time, size: 14, color: AppTheme.textMuted),
                        SizedBox(width: 4),
                        Text(
                          "${createdAt.day}/${createdAt.month}/${createdAt.year}",
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                      Spacer(),
                      if (adminName != null) ...[
                        Icon(Icons.person_outline, size: 14, color: AppTheme.brandBlue),
                        SizedBox(width: 4),
                        Text(
                          "Handled by: $adminName",
                          style: TextStyle(fontSize: 12, color: AppTheme.brandBlue, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceGray,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: _image != null ? AppTheme.brandBlue : AppTheme.surfaceBorder,
              width: _image != null ? 2 : 1,
            ),
          ),
          child: _image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl - 2),
                  child: Image.file(
                    _image!,
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: AppTheme.textMuted,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "No image selected",
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.photo_library_outlined),
                label: Text("Gallery"),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, 48),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: Icon(Icons.camera_alt_outlined),
                label: Text("Camera"),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, 48),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
