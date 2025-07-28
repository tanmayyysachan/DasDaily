// admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_manager.dart';
import 'user_management.dart';
import 'orders_view.dart';
import 'monthly_reports.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Data variables
  List<Map<String, dynamic>> _users = [];
  int _totalUsers = 0;
  int _todaysOrders = 0;
  int _monthlyRevenue = 0;
  bool _menuAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await Future.wait([
        _fetchUsersData(),
        _fetchTodaysOrders(),
        _fetchMonthlyRevenue(),
        _fetchMenuStatus(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUsersData() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      
      List<Map<String, dynamic>> usersList = [];
      
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        
        // Get today's order for this user
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        DocumentSnapshot? todayOrder;
        
        try {
          todayOrder = await _firestore
              .collection('users')
              .doc(userDoc.id)
              .collection('orders')
              .doc(today)
              .get();
        } catch (e) {
          print('Error fetching today\'s order for ${userDoc.id}: $e');
        }

        usersList.add({
          'id': userDoc.id,
          'name': userData['name'] ?? 'Unknown User',
          'tiffinCount': userData['totalTiffins'] ?? 0,
          'curryCount': userData['totalCurries'] ?? 0,
          'totalAmount': userData['totalBill'] ?? 0,
          'lastOrder': todayOrder?.exists == true 
              ? DateTime.now() // If they ordered today
              : DateTime.now().subtract(Duration(days: 1)), // Placeholder for last order
          'todayOrder': todayOrder?.exists == true ? todayOrder!.data() as Map<String, dynamic>? : null,
        });
      }

      // Sort by total amount descending
      usersList.sort((a, b) => (b['totalAmount'] as int).compareTo(a['totalAmount'] as int));

      setState(() {
        _users = usersList;
        _totalUsers = usersList.length;
      });
    } catch (e) {
      print('Error fetching users data: $e');
    }
  }

  Future<void> _fetchTodaysOrders() async {
    try {
      int todayOrderCount = 0;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        try {
          final todayOrder = await _firestore
              .collection('users')
              .doc(userDoc.id)
              .collection('orders')
              .doc(today)
              .get();
          
          if (todayOrder.exists) {
            todayOrderCount++;
          }
        } catch (e) {
          print('Error checking today\'s order for ${userDoc.id}: $e');
        }
      }

      setState(() {
        _todaysOrders = todayOrderCount;
      });
    } catch (e) {
      print('Error fetching today\'s orders: $e');
    }
  }

  Future<void> _fetchMonthlyRevenue() async {
    try {
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      
      final historyDoc = await _firestore
          .collection('history')
          .doc(currentMonth)
          .get();

      int totalRevenue = 0;
      
      if (historyDoc.exists) {
        final data = historyDoc.data() as Map<String, dynamic>;
        
        for (var userId in data.keys) {
          if (data[userId] is Map<String, dynamic>) {
            final userMonthlyData = data[userId] as Map<String, dynamic>;
            totalRevenue += (userMonthlyData['total'] as int? ?? 0);
          }
        }
      }

      setState(() {
        _monthlyRevenue = totalRevenue;
      });
    } catch (e) {
      print('Error fetching monthly revenue: $e');
    }
  }

  Future<void> _fetchMenuStatus() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final menuDoc = await _firestore
          .collection('menu')
          .doc(today)
          .get();

      setState(() {
        _menuAvailable = menuDoc.exists && 
                        (menuDoc.data()?['orderingOpen'] == true);
      });
    } catch (e) {
      print('Error fetching menu status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboardHome(),
      const MenuManager(),
      const UserManagement(),
      const OrdersView(),
      const MonthlyReports(),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF82B29A),
          unselectedItemColor: Colors.grey.shade600,
          selectedFontSize: 12,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Menu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHome() {
    if (_isLoading) {
      return const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF82B29A),
              ),
              SizedBox(height: 16),
              Text(
                'Loading dashboard data...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: const Color(0xFF82B29A),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
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
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Admin Dashboard",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _fetchDashboardData,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 20,
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
                            DateFormat.yMMMMEEEEd().format(DateTime.now()),
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

                  const SizedBox(height: 24),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Total Users",
                          "$_totalUsers",
                          Icons.people,
                          const Color(0xFF82B29A),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          "Today's Orders",
                          "$_todaysOrders",
                          Icons.shopping_cart,
                          const Color(0xFF6BAF92),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Monthly Revenue",
                          "₹$_monthlyRevenue",
                          Icons.currency_rupee,
                          const Color(0xFF98C5AB),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          "Menu Status",
                          _menuAvailable ? "Available" : "Closed",
                          Icons.restaurant_menu,
                          _menuAvailable ? const Color(0xFF82B29A) : Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Recent Activity
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF82B29A).withOpacity(0.1),
                                    const Color(0xFF98C5AB).withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF82B29A).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.people,
                                      color: Color(0xFF82B29A),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      "Top Customers",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Inter',
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _users.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No users found',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF6B7280),
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _users.length,
                                      itemBuilder: (context, index) {
                                        final user = _users[index];
                                        return _buildUserActivityTile(user);
                                      },
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
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActivityTile(Map<String, dynamic> user) {
    final bool hasOrderedToday = user['todayOrder'] != null;
    final String userName = user['name']?.toString() ?? 'Unknown User';
    final String userInitial = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasOrderedToday 
            ? const Color(0xFF82B29A).withOpacity(0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasOrderedToday 
              ? const Color(0xFF82B29A).withOpacity(0.3)
              : const Color(0xFF82B29A).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF82B29A).withOpacity(0.2),
                child: Text(
                  userInitial,
                  style: const TextStyle(
                    color: Color(0xFF82B29A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (hasOrderedToday)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    if (hasOrderedToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Total Tiffins: ${user['tiffinCount'] ?? 0} | Monthly: ₹${user['totalAmount'] ?? 0}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                    color: Colors.grey.shade600,
                  ),
                ),
                if (hasOrderedToday && user['todayOrder'] != null)
                  Text(
                    'Today: ${user['todayOrder']['tiffin'] ?? 0} tiffin, ${user['todayOrder']['curry'] ?? 0} curry',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                      color: Colors.green.shade700,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '₹${user['totalAmount'] ?? 0}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Color(0xFF82B29A),
            ),
          ),
        ],
      ),
    );
  }
}