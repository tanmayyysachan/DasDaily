import 'package:dasdaily/authentication/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'landing_page.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  int totalTiffins = 0;
  int totalCurries = 0;
  int totalSpent = 0;
  String userName = "Food Lover";
  String userEmail = "foodie@example.com";
  String? profileImageBase64;
  bool isLoading = true;
  bool isUploadingImage = false;

  late AnimationController _headerController;
  late AnimationController _statsController;
  late AnimationController _achievementController;
  late AnimationController _actionController;

  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _statsScaleAnimation;
  late Animation<double> _achievementFadeAnimation;
  late Animation<double> _actionSlideAnimation;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _achievementController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _actionController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );

    _statsScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.elasticOut),
    );

    _achievementFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _achievementController, curve: Curves.easeOut),
    );

    _actionSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _actionController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() async {
    _headerController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _statsController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _achievementController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _actionController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _statsController.dispose();
    _achievementController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  // Updated to fetch data from Firestore including profile image
  Future<void> _loadProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No user logged in");
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Get user document from Firestore
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          totalTiffins = userData['totalTiffins'] ?? 0;
          totalCurries = userData['totalCurries'] ?? 0;
          totalSpent = userData['totalBill'] ?? 0;
          userName = userData['name'] ?? user.displayName ?? "Food Lover";
          userEmail = userData['email'] ?? user.email ?? "foodie@example.com";
          profileImageBase64 = userData['profileImageBase64'];
          isLoading = false;
        });
      } else {
        // If user document doesn't exist, create it with default values
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': user.displayName ?? "Food Lover",
          'email': user.email ?? "",
          'totalTiffins': 0,
          'totalCurries': 0,
          'totalBill': 0,
          'role': 'user',
          'profileImageBase64': null,
          'lastUpdated': DateTime.now(),
        });

        setState(() {
          totalTiffins = 0;
          totalCurries = 0;
          totalSpent = 0;
          userName = user.displayName ?? "Food Lover";
          userEmail = user.email ?? "foodie@example.com";
          profileImageBase64 = null;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading profile data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // FIXED: Simplified and more reliable logout function
  Future<void> _logout() async {
    try {
      // Show confirmation dialog
      final bool shouldLogout = await _showLogoutDialog();
      if (!shouldLogout) return;

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF82B29A),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Logging out...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to your login/auth screen
      // Replace 'LoginPage' with your actual login page class name
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print("Error logging out: $e");

      // Close loading dialog if it's showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      _showErrorSnackBar("Failed to log out. Please try again.");
    }
  }

  // FIXED: Order Food navigation function
  void _navigateToOrderPage() {
    try {
      // Since ProfilePage is opened from LandingPage, just pop back
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        // Fallback: Navigate to LandingPage if somehow there's no previous route
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LandingPage()),
        );
      }
    } catch (e) {
      print("Order navigation error: $e");
      _showErrorSnackBar("Failed to navigate to order page.");
    }
  }

  Future<bool> _showLogoutDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.logout, color: Color(0xFFDC2626), size: 24),
                  SizedBox(width: 12),
                  Text(
                    "Log Out",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              content: const Text(
                "Are you sure you want to log out? You'll need to sign in again to access your account.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Log Out",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Function to show image picker options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Select Profile Picture',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _imagePickerOption(
                              icon: Icons.camera_alt,
                              title: 'Camera',
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _imagePickerOption(
                              icon: Icons.photo_library,
                              title: 'Gallery',
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                          ),
                        ],
                      ),
                      if (profileImageBase64 != null) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: _imagePickerOption(
                            icon: Icons.delete,
                            title: 'Remove Photo',
                            color: Colors.red,
                            onTap: () {
                              Navigator.pop(context);
                              _removeProfileImage();
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _imagePickerOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final optionColor = color ?? const Color(0xFF82B29A);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: optionColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: optionColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: optionColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: optionColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Reduced quality for smaller size
        maxWidth: 400, // Smaller dimensions to reduce Base64 size
        maxHeight: 400,
      );

      if (image != null) {
        setState(() {
          isUploadingImage = true;
        });

        await _convertImageToBase64(File(image.path));
      }
    } catch (e) {
      print("Error picking image: $e");
      _showErrorSnackBar("Failed to pick image. Please try again.");
    }
  }

  // Function to convert image to Base64 and save to Firestore
  Future<void> _convertImageToBase64(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Read image file as bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Convert to Base64 string
      final String base64String = base64Encode(imageBytes);

      // Check if the Base64 string is too large (Firestore has 1MB document limit)
      if (base64String.length > 800000) {
        // ~800KB limit for safety
        setState(() {
          isUploadingImage = false;
        });
        _showErrorSnackBar(
          "Image is too large. Please choose a smaller image.",
        );
        return;
      }

      // Update Firestore with new profile image Base64
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profileImageBase64': base64String, 'lastUpdated': DateTime.now()},
      );

      setState(() {
        profileImageBase64 = base64String;
        isUploadingImage = false;
      });

      _showSuccessSnackBar("Profile picture updated successfully!");
    } catch (e) {
      print("Error converting image: $e");
      setState(() {
        isUploadingImage = false;
      });
      _showErrorSnackBar("Failed to upload image. Please try again.");
    }
  }

  // Function to remove profile image
  Future<void> _removeProfileImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() {
        isUploadingImage = true;
      });

      // Update Firestore to remove profile image Base64
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profileImageBase64': null, 'lastUpdated': DateTime.now()},
      );

      setState(() {
        profileImageBase64 = null;
        isUploadingImage = false;
      });

      _showSuccessSnackBar("Profile picture removed successfully!");
    } catch (e) {
      print("Error removing profile image: $e");
      setState(() {
        isUploadingImage = false;
      });
      _showErrorSnackBar("Failed to remove image. Please try again.");
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  String _getFoodieLevel() {
    final totalOrders = totalTiffins + totalCurries;
    if (totalOrders >= 50) return "Master Chef";
    if (totalOrders >= 25) return "Food Enthusiast";
    if (totalOrders >= 10) return "Regular Foodie";
    return "New Explorer";
  }

  Color _getLevelColor() {
    final totalOrders = totalTiffins + totalCurries;
    if (totalOrders >= 50) return const Color(0xFFDC2626);
    if (totalOrders >= 25) return const Color(0xFF7C3AED);
    if (totalOrders >= 10) return const Color(0xFF059669);
    return const Color(0xFF2563EB);
  }

  List<Map<String, dynamic>> _getAchievements() {
    List<Map<String, dynamic>> achievements = [];

    if (totalTiffins >= 5) {
      achievements.add({
        'icon': '🍱',
        'title': 'Tiffin Master',
        'description': 'Ordered 5+ tiffins',
        'color': const Color(0xFF059669),
      });
    }

    if (totalCurries >= 3) {
      achievements.add({
        'icon': '🍛',
        'title': 'Curry Lover',
        'description': 'Ordered 3+ extra curries',
        'color': const Color(0xFF7C3AED),
      });
    }

    if (totalSpent >= 500) {
      achievements.add({
        'icon': '💎',
        'title': 'Loyal Customer',
        'description': 'Spent ₹500+',
        'color': const Color(0xFFDC2626),
      });
    }

    if ((totalTiffins + totalCurries) >= 10) {
      achievements.add({
        'icon': '🏆',
        'title': 'Food Explorer',
        'description': '10+ total orders',
        'color': const Color(0xFFF59E0B),
      });
    }

    return achievements;
  }

  @override
  Widget build(BuildContext context) {
    final achievements = _getAchievements();

    // Show loading indicator while fetching data
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6BAF92), Color(0xFF82B29A), Color(0xFFF8FAFC)],
              stops: [0.0, 0.3, 1.0],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6BAF92), Color(0xFF82B29A), Color(0xFFF8FAFC)],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header with Profile
              SlideTransition(
                position: _headerSlideAnimation,
                child: FadeTransition(
                  opacity: _headerFadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                "Your Profile",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // Refresh data
                                setState(() {
                                  isLoading = true;
                                });
                                _loadProfileData();
                              },
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Profile Photo Section with Upload Functionality
                        GestureDetector(
                          onTap: _showImagePickerOptions,
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Colors.white, Color(0xFFF3F4F6)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child:
                                      isUploadingImage
                                          ? const Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF82B29A),
                                                  ),
                                            ),
                                          )
                                          : profileImageBase64 != null
                                          ? Image.memory(
                                            base64Decode(profileImageBase64!),
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Center(
                                                child: Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Color(0xFF82B29A),
                                                ),
                                              );
                                            },
                                          )
                                          : const Center(
                                            child: Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Color(0xFF82B29A),
                                            ),
                                          ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Color(0xFF82B29A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelColor(),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _getLevelColor().withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            _getFoodieLevel(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          "${_getGreeting()}!",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Stats Section
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Action Buttons - FIXED NAVIGATION
                        FadeTransition(
                          opacity: _actionSlideAnimation,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _actionButton(
                                    icon: Icons.restaurant_menu,
                                    label: "Order Food",
                                    color: const Color(0xFF82B29A),
                                    onTap:
                                        _navigateToOrderPage, // FIXED: Use proper navigation function
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _actionButton(
                                    icon: Icons.logout,
                                    label: "Log Out",
                                    color: const Color(0xFFDC2626),
                                    onTap: _logout,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Stats Cards
                        const Text(
                          "Your Food Journey",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                            fontFamily: 'Inter',
                          ),
                        ),

                        const SizedBox(height: 20),

                        ScaleTransition(
                          scale: _statsScaleAnimation,
                          child: Column(
                            children: [
                              _profileCard(
                                "Total Tiffins Ordered",
                                totalTiffins,
                                Icons.lunch_dining,
                                const Color(0xFF059669),
                              ),
                              const SizedBox(height: 16),
                              _profileCard(
                                "Extra Curries Ordered",
                                totalCurries,
                                Icons.ramen_dining,
                                const Color(0xFF7C3AED),
                              ),
                              const SizedBox(height: 16),
                              _profileCard(
                                "Total Money Spent",
                                "₹$totalSpent",
                                Icons.account_balance_wallet,
                                const Color(0xFFDC2626),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Quick Stats Row
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF82B29A).withOpacity(0.1),
                                const Color(0xFF98C5AB).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF82B29A).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              _quickStat(
                                "Avg/Order",
                                totalTiffins > 0
                                    ? "₹${(totalSpent / (totalTiffins + totalCurries)).round()}"
                                    : "₹0",
                              ),
                              _quickStat(
                                "Total Orders",
                                "${totalTiffins + totalCurries}",
                              ),
                              _quickStat("Email", userEmail.split('@')[0]),
                            ],
                          ),
                        ),

                        if (achievements.isNotEmpty) ...[
                          const SizedBox(height: 32),

                          // Achievements Section
                          FadeTransition(
                            opacity: _achievementFadeAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Your Achievements",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                    fontFamily: 'Inter',
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children:
                                      achievements
                                          .map(
                                            (achievement) =>
                                                _achievementBadge(achievement),
                                          )
                                          .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Recent Activity
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Account Info",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 16),
                              _activityItem("Email", userEmail, Icons.email),
                              _activityItem(
                                "Status",
                                "Active Member",
                                Icons.verified,
                              ),
                              _activityItem(
                                "User ID",
                                FirebaseAuth.instance.currentUser?.uid
                                        .substring(0, 8) ??
                                    "N/A",
                                Icons.person,
                              ),
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
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(String label, dynamic value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF82B29A),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementBadge(Map<String, dynamic> achievement) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: achievement['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: achievement['color'].withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(achievement['icon'], style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement['title'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: achievement['color'],
                ),
              ),
              Text(
                achievement['description'],
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF82B29A)),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
                fontFamily: 'Inter',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}