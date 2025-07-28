// import 'package:flutter/material.dart';

// Widget UserTile(Map<String, dynamic> user, int index) {
//   final isAdmin = user['role'] == 'admin';
//   final userName = user['name']?.toString() ?? 'Unknown User';

//   return Container(
//     margin: const EdgeInsets.only(bottom: 12),
//     decoration: BoxDecoration(
//       color: const Color(0xFFF8FAFC),
//       borderRadius: BorderRadius.circular(16),
//       border: Border.all(
//         color:
//             isAdmin
//                 ? Colors.orange.withOpacity(0.3)
//                 : const Color(0xFF82B29A).withOpacity(0.2),
//         width: 1,
//       ),
//     ),
//     child: ExpansionTile(
//       leading: CircleAvatar(
//         backgroundColor:
//             isAdmin
//                 ? Colors.orange.withOpacity(0.2)
//                 : const Color(0xFF82B29A).withOpacity(0.2),
//         child:
//             isAdmin
//                 ? const Icon(Icons.admin_panel_settings, color: Colors.orange)
//                 : Text(
//                   _getNameInitial(userName),
//                   style: const TextStyle(
//                     color: Color(0xFF82B29A),
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//       ),
//       title: Row(
//         children: [
//           Expanded(
//             child: Text(
//               userName,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 fontFamily: 'Inter',
//                 color: Color(0xFF1F2937),
//               ),
//             ),
//           ),
//           if (isAdmin)
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//               decoration: BoxDecoration(
//                 color: Colors.orange.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Text(
//                 'Admin',
//                 style: TextStyle(
//                   fontSize: 10,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.orange,
//                 ),
//               ),
//             ),
//         ],
//       ),
//       subtitle: Text(
//         'Total: ₹${user['totalAmount']} | Tiffins: ${user['tiffinCount']}',
//         style: TextStyle(
//           fontSize: 14,
//           fontWeight: FontWeight.w500,
//           fontFamily: 'Inter',
//           color: Colors.grey.shade600,
//         ),
//       ),
//       trailing: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color:
//               user['isActive']
//                   ? const Color(0xFF82B29A).withOpacity(0.2)
//                   : Colors.red.withOpacity(0.2),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Text(
//           user['isActive'] ? 'Active' : 'Inactive',
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w600,
//             color: user['isActive'] ? const Color(0xFF82B29A) : Colors.red,
//           ),
//         ),
//       ),
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildUserInfoCard(
//                       "Email",
//                       user['email']?.toString() ?? 'No email',
//                       Icons.email,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildUserInfoCard(
//                       "Join Date",
//                       DateFormat('MMM dd, yyyy').format(user['joinDate']),
//                       Icons.calendar_today,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildUserInfoCard(
//                       "Tiffin Count",
//                       "${user['tiffinCount']}",
//                       Icons.restaurant,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildUserInfoCard(
//                       "Curry Count",
//                       "${user['curryCount']}",
//                       Icons.soup_kitchen,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildUserInfoCard(
//                       "Total Amount",
//                       "₹${user['totalAmount']}",
//                       Icons.account_balance_wallet,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildUserInfoCard(
//                       "User ID",
//                       user['id'].length > 8
//                           ? user['id'].substring(0, 8)
//                           : user['id'],
//                       Icons.fingerprint,
//                     ),
//                   ),
//                 ],
//               ),
//               if (!isAdmin) ...[
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: () => _resetUserCount(user['id'], index),
//                         icon: const Icon(Icons.refresh),
//                         label: const Text('Reset Count'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF82B29A),
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: () => _toggleUserStatus(user['id'], index),
//                         icon: Icon(
//                           user['isActive'] ? Icons.block : Icons.check_circle,
//                         ),
//                         label: Text(
//                           user['isActive'] ? 'Deactivate' : 'Activate',
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor:
//                               user['isActive']
//                                   ? Colors.red
//                                   : const Color(0xFF82B29A),
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     IconButton(
//                       onPressed: () => _deleteUser(user['id'], index),
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       style: IconButton.styleFrom(
//                         backgroundColor: Colors.red.withOpacity(0.1),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }






















import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final int index;

  final void Function(String userId, int index) onResetUserCount;
  final void Function(String userId, int index) onToggleUserStatus;
  final void Function(String userId, int index) onDeleteUser;

  const UserTile({
    super.key,
    required this.user,
    required this.index,
    required this.onResetUserCount,
    required this.onToggleUserStatus,
    required this.onDeleteUser,
  });

  String _getNameInitial(String name) {
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _buildUserInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    )),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = user['role'] == 'admin';
    final userName = user['name']?.toString() ?? 'Unknown User';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAdmin ? Colors.orange.withOpacity(0.3) : const Color(0xFF82B29A).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isAdmin ? Colors.orange.withOpacity(0.2) : const Color(0xFF82B29A).withOpacity(0.2),
          child: isAdmin
              ? const Icon(Icons.admin_panel_settings, color: Colors.orange)
              : Text(
                  _getNameInitial(userName),
                  style: const TextStyle(
                    color: Color(0xFF82B29A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                userName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            if (isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          'Total: ₹${user['totalAmount']} | Tiffins: ${user['tiffinCount']}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: user['isActive'] ? const Color(0xFF82B29A).withOpacity(0.2) : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            user['isActive'] ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: user['isActive'] ? const Color(0xFF82B29A) : Colors.red,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildUserInfoCard("Email", user['email'] ?? 'No email', Icons.email),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildUserInfoCard("Join Date", DateFormat('MMM dd, yyyy').format(user['joinDate']), Icons.calendar_today),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildUserInfoCard("Tiffin Count", "${user['tiffinCount']}", Icons.restaurant),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildUserInfoCard("Curry Count", "${user['curryCount']}", Icons.soup_kitchen),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildUserInfoCard("Total Amount", "₹${user['totalAmount']}", Icons.account_balance_wallet),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildUserInfoCard("User ID", user['id'].toString().substring(0, 8), Icons.fingerprint),
                    ),
                  ],
                ),
                if (!isAdmin) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => onResetUserCount(user['id'], index),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Count'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF82B29A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => onToggleUserStatus(user['id'], index),
                          icon: Icon(user['isActive'] ? Icons.block : Icons.check_circle),
                          label: Text(user['isActive'] ? 'Deactivate' : 'Activate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: user['isActive'] ? Colors.red : const Color(0xFF82B29A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => onDeleteUser(user['id'], index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
