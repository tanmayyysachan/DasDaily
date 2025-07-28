//landing_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_confirmation_page.dart';
import 'profile_page.dart'; // Add this import

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

// Fixed: Use today's date format that matches menu_manager.dart
Stream<Map<String, dynamic>> getMenuStream() {
  final today = DateTime.now();
  final todayString = "${today.year}-${_twoDigits(today.month)}-${_twoDigits(today.day)}";
  
  return FirebaseFirestore.instance
      .collection('menu')
      .doc(todayString)
      .snapshots()
      .map((doc) {
        final data = doc.data();
        if (data == null) return {'items': <String>[], 'orderingOpen': false};
        return {
          'items': List<String>.from(data['items'] ?? []),
          'orderingOpen': data['orderingOpen'] ?? false,
        };
      });
}

// Helper function to match the one in menu_manager.dart
String _twoDigits(int n) => n.toString().padLeft(2, '0');

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  int tiffinCount = 0;
  int curryCount = 0;
  int totalCost = 0;

  late AnimationController _headerController;
  late AnimationController _cardController;
  late AnimationController _buttonController;
  late AnimationController _bounceController;

  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );

    _cardScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticInOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    _headerController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _cardController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _buttonController.forward();
  }

  void _animateButton() {
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardController.dispose();
    _buttonController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  //firestore linking
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameField = TextEditingController();

  Future<void> submitTiffins() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not Logged in!");
      }

      final now = DateTime.now();
      final dateId = DateFormat('yyyy-MM-dd').format(now); // for orders
      final monthId = DateFormat('yyyy-MM').format(now); // for history

      final userDocRef = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid);
      final userSnapshot = await userDocRef.get();
      final previousData = userSnapshot.data();

      final prevTiffins = previousData?['totalTiffins'] ?? 0;
      final prevCurries = previousData?['totalCurries'] ?? 0;
      final prevTotal = previousData?['totalBill'] ?? 0;

      // 1. 🔄 Update main user doc summary
      await userDocRef.set({
        "email": user.email,
        "name": user.displayName ?? '',
        "role": "user",
        "lastUpdated": now,
        "totalTiffins": prevTiffins + tiffinCount,
        "totalCurries": prevCurries + curryCount,
        "totalBill": prevTotal + totalCost,
      }, SetOptions(merge: true));

      // 2. 🧾 Add daily order to user/orders/date
      final orderDoc = userDocRef.collection("orders").doc(dateId);
      await orderDoc.set({
        'tiffin': tiffinCount,
        'curry': curryCount,
        'total': totalCost,
        'timestamp': now,
      });

      // 3. 📆 Update history/2025-07 with cumulative totals per user
      final historyRef = FirebaseFirestore.instance
          .collection("history")
          .doc(monthId);
      await historyRef.set({
        user.uid: {
          'tiffins': (prevTiffins + tiffinCount),
          'curries': (prevCurries + curryCount),
          'total': (prevTotal + totalCost),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error submitting order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String today = DateFormat.yMMMMEEEEd().format(DateTime.now());
    totalCost = (tiffinCount * 70) + (curryCount * 30);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Animated Gradient Header with Profile Button
              SlideTransition(
                position: _headerSlideAnimation,
                child: FadeTransition(
                  opacity: _headerFadeAnimation,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6BAF92),
                          Color(0xFF82B29A),
                          Color(0xFF98C5AB),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF82B29A).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.restaurant_menu,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Today's Menu",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            // Profile Button
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfilePage(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            today,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Animated Menu Card with ScrollView
              Expanded(
                child: ScaleTransition(
                  scale: _cardScaleAnimation,
                  child: FadeTransition(
                    opacity: _cardFadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(
                                            0xFF82B29A,
                                          ).withOpacity(0.2),
                                          const Color(
                                            0xFF98C5AB,
                                          ).withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "🍲",
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Text(
                                      "What's Cooking",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Inter',
                                        color: Color(0xFF1F2937),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF82B29A).withOpacity(0.08),
                                      const Color(0xFF98C5AB).withOpacity(0.04),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF82B29A,
                                    ).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),

                                // Fixed: Updated StreamBuilder to use the corrected stream
                                child: StreamBuilder<Map<String, dynamic>>(
                                  stream: getMenuStream(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Text("Error loading menu: ${snapshot.error}");
                                    } else if (!snapshot.hasData) {
                                      return const Text(
                                        "Menu not available for today.",
                                      );
                                    } else {
                                      final menuData = snapshot.data!;
                                      final items = menuData['items'] as List<String>;
                                      final orderingOpen = menuData['orderingOpen'] as bool;
                                      
                                      if (items.isEmpty) {
                                        return const Text(
                                          "Menu not available for today.",
                                        );
                                      }
                                      
                                      // Show ordering closed message if needed
                                      if (!orderingOpen) {
                                        return Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.orange.shade300),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.info, color: Colors.orange.shade700),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      "Ordering is currently closed",
                                                      style: TextStyle(
                                                        color: Colors.orange.shade700,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: items.map((item) {
                                                return _buildMenuItem("🍽️", item);
                                              }).toList(),
                                            ),
                                          ],
                                        );
                                      }
                                      
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children:
                                            items.map((item) {
                                              return _buildMenuItem("🍽️", item);
                                            }).toList(),
                                      );
                                    }
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Fixed: Use StreamBuilder to check if ordering is open before showing quantity selectors
                              StreamBuilder<Map<String, dynamic>>(
                                stream: getMenuStream(),
                                builder: (context, snapshot) {
                                  final orderingOpen = snapshot.hasData ? 
                                    (snapshot.data!['orderingOpen'] as bool? ?? false) : false;
                                  
                                  if (!orderingOpen) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        "Ordering is currently closed for today",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }
                                  
                                  return Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      children: [
                                        _quantitySelector(
                                          label: "Tiffin",
                                          price: "₹70",
                                          count: tiffinCount,
                                          onChanged: (val) {
                                            setState(() {
                                              tiffinCount = val;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        _quantitySelector(
                                          label: "Extra Curry",
                                          price: "₹30",
                                          count: curryCount,
                                          onChanged: (val) {
                                            setState(() {
                                              curryCount = val;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 12),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF1F2937).withOpacity(0.05),
                                      const Color(0xFF374151).withOpacity(0.02),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF1F2937,
                                    ).withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Total Amount",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Inter',
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF82B29A),
                                            Color(0xFF98C5AB),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "₹$totalCost",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inter',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Animated Order Button - Fixed to check ordering status
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _bounceAnimation.value,
                        child: StreamBuilder<Map<String, dynamic>>(
                          stream: getMenuStream(),
                          builder: (context, snapshot) {
                            final orderingOpen = snapshot.hasData ? 
                              (snapshot.data!['orderingOpen'] as bool? ?? false) : false;
                            final canOrder = orderingOpen && totalCost > 0;
                            
                            return Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient:
                                    !canOrder
                                        ? LinearGradient(
                                          colors: [
                                            Colors.grey.shade300,
                                            Colors.grey.shade400,
                                          ],
                                        )
                                        : const LinearGradient(
                                          colors: [
                                            Color(0xFF6BAF92),
                                            Color(0xFF82B29A),
                                          ],
                                        ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow:
                                    !canOrder
                                        ? []
                                        : [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF82B29A,
                                            ).withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap:
                                      !canOrder
                                          ? null
                                          : () {
                                            _animateButton();
                                            submitTiffins();
                                            Future.delayed(
                                              const Duration(milliseconds: 100),
                                              () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (
                                                          context,
                                                        ) => OrderConfirmationPage(
                                                          tiffinCount: tiffinCount,
                                                          curryCount: curryCount,
                                                          totalCost: totalCost,
                                                        ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                      horizontal: 40,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shopping_cart,
                                          color:
                                              !canOrder
                                                  ? Colors.grey.shade600
                                                  : Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          !orderingOpen ? "Ordering Closed" : 
                                          totalCost == 0 ? "Select Items" : "Order Now",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Inter',
                                            color:
                                                !canOrder
                                                    ? Colors.grey.shade600
                                                    : Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String emoji, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantitySelector({
    required String label,
    required String price,
    required int count,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              count > 0
                  ? const Color(0xFF82B29A).withOpacity(0.3)
                  : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildQuantityButton(
                Icons.remove,
                () => onChanged(count > 0 ? count - 1 : 0),
                count > 0,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      count > 0
                          ? const Color(0xFF82B29A).withOpacity(0.1)
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color:
                        count > 0
                            ? const Color(0xFF82B29A)
                            : Colors.grey.shade600,
                  ),
                ),
              ),
              _buildQuantityButton(Icons.add, () => onChanged(count + 1), true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
    IconData icon,
    VoidCallback onPressed,
    bool enabled,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF82B29A) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
        boxShadow:
            enabled
                ? [
                  BoxShadow(
                    color: const Color(0xFF82B29A).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: enabled ? Colors.white : Colors.grey.shade500,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}