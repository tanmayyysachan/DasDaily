// user_management.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // ✅ Enhanced _loadUsers function with better name handling
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      List<Map<String, dynamic>> usersList = [];

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();

        // Enhanced name handling
        String userName = 'Unknown User';
        if (userData['name'] != null &&
            userData['name'].toString().trim().isNotEmpty) {
          userName = userData['name'].toString().trim();
        } else if (userData['email'] != null) {
          // Extract name from email if no name is provided
          String email = userData['email'].toString();
          userName = email
              .split('@')[0]
              .replaceAll('.', ' ')
              .replaceAll('_', ' ');
          // Capitalize first letter of each word
          userName = userName
              .split(' ')
              .map(
                (word) =>
                    word.isNotEmpty
                        ? word[0].toUpperCase() +
                            word.substring(1).toLowerCase()
                        : '',
              )
              .join(' ');
        }

        usersList.add({
          'id': userDoc.id,
          'name': userName,
          'email': userData['email'] ?? 'No email',
          'phone': userData['phone'] ?? 'No phone',
          'tiffinCount': userData['totalTiffins'] ?? 0,
          'curryCount': userData['totalCurries'] ?? 0,
          'totalAmount': userData['totalBill'] ?? 0,
          'isActive': userData['isActive'] ?? true,
          'role': userData['role'] ?? 'user',
          'joinDate':
              userData['createdAt'] != null
                  ? (userData['createdAt'] as Timestamp).toDate()
                  : (userData['lastUpdated'] != null
                      ? (userData['lastUpdated'] as Timestamp).toDate()
                      : DateTime.now()),
        });
      }

      // Sort users by total amount (highest first)
      usersList.sort(
        (a, b) => (b['totalAmount'] as int).compareTo(a['totalAmount'] as int),
      );

      setState(() {
        _users = usersList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading users: $e');
    }
  }

  // ✅ New migration function to fix existing users
  Future<void> _migrateExistingUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      int migratedCount = 0;

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();

        // Check if user document is missing essential fields
        if (userData['name'] == null ||
            userData['name'] == '' ||
            userData['name'] == 'Unknown User' ||
            userData['name'].toString().trim().isEmpty) {
          // Create a better default name
          String defaultName = 'User';
          if (userData['email'] != null) {
            String email = userData['email'].toString();
            defaultName = email
                .split('@')[0]
                .replaceAll('.', ' ')
                .replaceAll('_', ' ');
            defaultName = defaultName
                .split(' ')
                .map(
                  (word) =>
                      word.isNotEmpty
                          ? word[0].toUpperCase() +
                              word.substring(1).toLowerCase()
                          : '',
                )
                .join(' ');
          } else {
            defaultName = 'User ${userDoc.id.substring(0, 6)}';
          }

          // Update with default values
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id)
              .update({
                'name': defaultName,
                'email': userData['email'] ?? 'No email',
                'totalTiffins': userData['totalTiffins'] ?? 0,
                'totalCurries': userData['totalCurries'] ?? 0,
                'totalBill': userData['totalBill'] ?? 0,
                'isActive': userData['isActive'] ?? true,
                'role': userData['role'] ?? 'user',
                'lastUpdated': FieldValue.serverTimestamp(),
              });

          migratedCount++;
        }
      }

      _showSuccessSnackBar(
        'Migration completed! Updated $migratedCount users.',
      );
      await _loadUsers(); // Refresh the list
    } catch (e) {
      _showErrorSnackBar('Migration failed: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetUserCount(String userId, int index) async {
    try {
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Reset User Count'),
              content: Text(
                'Are you sure you want to reset all counts for ${_users[index]['name']}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Reset'),
                ),
              ],
            ),
      );

      if (confirm != true) return;

      // Reset in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'totalTiffins': 0,
        'totalCurries': 0,
        'totalBill': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update local state
      setState(() {
        _users[index]['tiffinCount'] = 0;
        _users[index]['curryCount'] = 0;
        _users[index]['totalAmount'] = 0;
      });

      _showSuccessSnackBar('User count reset successfully!');
    } catch (e) {
      _showErrorSnackBar('Error resetting user count: $e');
    }
  }

  Future<void> _toggleUserStatus(String userId, int index) async {
    try {
      final newStatus = !_users[index]['isActive'];

      // Update in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update local state
      setState(() {
        _users[index]['isActive'] = newStatus;
      });

      _showSuccessSnackBar(
        newStatus
            ? 'User activated successfully!'
            : 'User deactivated successfully!',
      );
    } catch (e) {
      _showErrorSnackBar('Error updating user status: $e');
    }
  }

  Future<void> _deleteUser(String userId, int index) async {
    try {
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Delete User'),
              content: Text(
                'Are you sure you want to delete ${_users[index]['name']}? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
      );

      if (confirm != true) return;

      // Delete from Firestore (you might want to keep the data and just mark as deleted)
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      // Update local state
      setState(() {
        _users.removeAt(index);
      });

      _showSuccessSnackBar('User deleted successfully!');
    } catch (e) {
      _showErrorSnackBar('Error deleting user: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;

    return _users.where((user) {
      return user['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          user['email'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  // Helper method to safely get first character of a name
  String _getNameInitial(String name) {
    if (name.isEmpty || name == 'Unknown User') {
      return 'U'; // Default to 'U' for Unknown
    }
    return name.trim().substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;

    return SafeArea(
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
                      Icons.people,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "User Management",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // ✅ Updated header buttons with migration option
                  Row(
                    children: [
                      IconButton(
                        onPressed: _loadUsers,
                        tooltip: 'Refresh Users',
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      IconButton(
                        onPressed: _migrateExistingUsers,
                        tooltip: 'Fix Missing Names',
                        icon: const Icon(
                          Icons.sync,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search users by name or email...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF82B29A)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Users List
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
                            const Text(
                              "Registered Users",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "${filteredUsers.length} Total",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child:
                            _isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF82B29A),
                                    ),
                                  ),
                                )
                                : filteredUsers.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'No users found'
                                            : 'No users match your search',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = filteredUsers[index];
                                    return _buildUserTile(user, index);
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
    );
  }

  // ✅ Inline UserTile widget with proper error handling
  Widget _buildUserTile(Map<String, dynamic> user, int index) {
    final String userName = user['name']?.toString() ?? 'Unknown User';
    final String userInitial = _getNameInitial(userName);
    final bool isActive = user['isActive'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive 
            ? Colors.white
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive 
              ? const Color(0xFF82B29A).withOpacity(0.2)
              : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // User Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isActive 
                        ? const Color(0xFF82B29A).withOpacity(0.2)
                        : Colors.grey.shade300,
                    child: Text(
                      userInitial,
                      style: TextStyle(
                        color: isActive 
                            ? const Color(0xFF82B29A)
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (!isActive)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                              color: isActive 
                                  ? const Color(0xFF1F2937)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (user['role'] == 'admin')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive 
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 10,
                              color: isActive 
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email']?.toString() ?? 'No email',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions Menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'reset':
                      _resetUserCount(user['id'], index);
                      break;
                    case 'toggle':
                      _toggleUserStatus(user['id'], index);
                      break;
                    case 'delete':
                      _deleteUser(user['id'], index);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 16, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Reset Count'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.block : Icons.check_circle,
                          size: 16,
                          color: isActive ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildUserInfoCard(
                  'Total Tiffins',
                  '${user['tiffinCount'] ?? 0}',
                  Icons.restaurant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUserInfoCard(
                  'Total Curries',
                  '${user['curryCount'] ?? 0}',
                  Icons.soup_kitchen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUserInfoCard(
                  'Total Amount',
                  '₹${user['totalAmount'] ?? 0}',
                  Icons.currency_rupee,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF82B29A)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF82B29A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}