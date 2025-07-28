// orders_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _todaysOrders = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTodaysOrders();
  }

  Future<void> _fetchTodaysOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Get today's date in the format used in your database
      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      List<Map<String, dynamic>> orders = [];

      // Get all users - try with role filter first, then without if no results
      QuerySnapshot usersSnapshot;
      try {
        usersSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'user')
            .get();
        
        // If no users found with role filter, try getting all users
        if (usersSnapshot.docs.isEmpty) {
          print('No users found with role=user, trying to get all users...');
          usersSnapshot = await _firestore
              .collection('users')
              .get();
        }
      } catch (e) {
        print('Error with role filter, trying to get all users: $e');
        usersSnapshot = await _firestore
            .collection('users')
            .get();
      }

      print('Found ${usersSnapshot.docs.length} users in total');

      // For each user, check if they have an order for today
      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        try {
          // Check if user has an order for today
          DocumentSnapshot orderDoc = await userDoc.reference
              .collection('orders')
              .doc(todayDate)
              .get();

          if (orderDoc.exists) {
            Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            
            // Debug: Print user data to see what fields are available
            print('User ${userDoc.id} data: $userData');
            print('Available fields: ${userData.keys.toList()}');
            
            // Safe way to get userName with fallback
            String userName = 'Unknown User';
            String userEmail = '';
            
            try {
              // Try different possible name fields in order of preference
              if (userData.containsKey('name') && userData['name'] != null && userData['name'].toString().trim().isNotEmpty) {
                userName = userData['name'].toString().trim();
              } else if (userData.containsKey('displayName') && userData['displayName'] != null && userData['displayName'].toString().trim().isNotEmpty) {
                userName = userData['displayName'].toString().trim();
              } else if (userData.containsKey('display_name') && userData['display_name'] != null && userData['display_name'].toString().trim().isNotEmpty) {
                userName = userData['display_name'].toString().trim();
              } else if (userData.containsKey('email') && userData['email'] != null && userData['email'].toString().trim().isNotEmpty) {
                userEmail = userData['email'].toString().trim();
                // Extract name part from email (before @)
                userName = userEmail.split('@')[0];
              } else if (userData.containsKey('uid') && userData['uid'] != null) {
                userName = 'User ${userData['uid'].toString().substring(0, 6)}';
              } else {
                // Last fallback: use document ID
                userName = 'User ${userDoc.id.substring(0, 6)}';
              }
              
              // If userName is still empty or just whitespace, use fallback
              if (userName.trim().isEmpty) {
                userName = 'User ${userDoc.id.substring(0, 6)}';
              }
              
            } catch (e) {
              print('Error getting user name for ${userDoc.id}: $e');
              userName = 'User ${userDoc.id.substring(0, 6)}';
            }
            
            orders.add({
              'userId': userDoc.id,
              'userName': userName,
              'tiffinCount': orderData['tiffin'] ?? 0,
              'curryCount': orderData['curry'] ?? 0,
              'totalAmount': orderData['total'] ?? 0,
              'orderTime': orderData['timestamp'] != null 
                  ? (orderData['timestamp'] as Timestamp).toDate()
                  : DateTime.now(),
              'status': orderData['status'] ?? 'confirmed', // Default to confirmed
              'orderId': todayDate, // Using date as order ID
            });
          }
        } catch (e) {
          print('Error fetching order for user ${userDoc.id}: $e');
          // Continue with other users even if one fails
        }
      }

      // Sort orders by order time (most recent first)
      orders.sort((a, b) => (b['orderTime'] as DateTime).compareTo(a['orderTime'] as DateTime));

      setState(() {
        _todaysOrders = orders;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load orders: $e';
        _isLoading = false;
      });
      print('Error fetching today\'s orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF82B29A),
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchTodaysOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF82B29A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    int totalTiffins = _todaysOrders.fold(0, (sum, order) => sum + (order['tiffinCount'] as int? ?? 0));
    int totalCurries = _todaysOrders.fold(0, (sum, order) => sum + (order['curryCount'] as int? ?? 0));
    int totalRevenue = _todaysOrders.fold(0, (sum, order) => sum + (order['totalAmount'] as int? ?? 0));

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchTodaysOrders,
        color: const Color(0xFF82B29A),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Today's Orders",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
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
                        "${_todaysOrders.length} Orders",
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

              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      "Total Tiffins",
                      totalTiffins.toString(),
                      Icons.restaurant,
                      const Color(0xFF82B29A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      "Extra Curries",
                      totalCurries.toString(),
                      Icons.soup_kitchen,
                      const Color(0xFF6BAF92),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      "Revenue",
                      "₹$totalRevenue",
                      Icons.currency_rupee,
                      const Color(0xFF98C5AB),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Orders List
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
                          child: const Row(
                            children: [
                              Text(
                                "Order Details",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _todaysOrders.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No orders for today',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Orders will appear here when customers place them',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _todaysOrders.length,
                                  itemBuilder: (context, index) {
                                    final order = _todaysOrders[index];
                                    return _buildOrderTile(order, index);
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
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to safely get the first character of a string
  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    return name.trim().substring(0, 1).toUpperCase();
  }

  Widget _buildOrderTile(Map<String, dynamic> order, int index) {
    final statusColor = order['status'] == 'confirmed' 
        ? const Color(0xFF82B29A) 
        : Colors.orange;

    // Safely get userName
    final userName = order['userName']?.toString() ?? 'Unknown User';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.2),
                child: Text(
                  _getInitial(userName), // Using the safe helper function
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(order['orderTime'] ?? DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (order['status']?.toString() ?? 'confirmed').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildOrderDetailChip("Tiffin", (order['tiffinCount'] ?? 0).toString(), Icons.restaurant),
              const SizedBox(width: 8),
              _buildOrderDetailChip("Curry", (order['curryCount'] ?? 0).toString(), Icons.soup_kitchen),
              const SizedBox(width: 8),
              _buildOrderDetailChip("Total", "₹${order['totalAmount'] ?? 0}", Icons.currency_rupee),
            ],
          ),
          if (order['status'] == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmOrder(index),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF82B29A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _cancelOrder(index),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderDetailChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: const Color(0xFF82B29A),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmOrder(int index) async {
    try {
      final order = _todaysOrders[index];
      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Update the order status in Firestore
      await _firestore
          .collection('users')
          .doc(order['userId'])
          .collection('orders')
          .doc(todayDate)
          .update({'status': 'confirmed'});

      setState(() {
        _todaysOrders[index]['status'] = 'confirmed';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order confirmed successfully!'),
            backgroundColor: Color(0xFF82B29A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelOrder(int index) async {
    try {
      final order = _todaysOrders[index];
      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Delete the order from Firestore
      await _firestore
          .collection('users')
          .doc(order['userId'])
          .collection('orders')
          .doc(todayDate)
          .delete();

      setState(() {
        _todaysOrders.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}