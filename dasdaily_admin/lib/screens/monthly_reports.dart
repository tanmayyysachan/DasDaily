import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DasDaily',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF82B29A)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const MonthlyReports(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MonthlyReports extends StatefulWidget {
  const MonthlyReports({super.key});

  @override
  State<MonthlyReports> createState() => _MonthlyReportsState();
}

class _MonthlyReportsState extends State<MonthlyReports> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  Map<String, dynamic> _currentData = {};
  bool _isLoading = true;
  List<String> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableMonths();
  }

  Future<void> _loadAvailableMonths() async {
    try {
      // Get all available months from history collection
      final historySnapshot = await FirebaseFirestore.instance
          .collection('history')
          .get();

      List<String> months = historySnapshot.docs.map((doc) => doc.id).toList();
      
      // Sort months in descending order (newest first)
      months.sort((a, b) => b.compareTo(a));
      
      setState(() {
        _availableMonths = months;
        if (months.isNotEmpty) {
          // Use current month if available, otherwise use the most recent month
          _selectedMonth = months.contains(_selectedMonth) ? _selectedMonth : months.first;
        }
        _isLoading = false;
      });

      if (months.isNotEmpty) {
        _loadMonthlyData(_selectedMonth);
      }
    } catch (e) {
      print('Error loading available months: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMonthlyData(String monthId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get history data for the selected month
      final historyDoc = await FirebaseFirestore.instance
          .collection('history')
          .doc(monthId)
          .get();

      if (!historyDoc.exists) {
        setState(() {
          _currentData = _getEmptyData();
          _isLoading = false;
        });
        return;
      }

      final historyData = historyDoc.data()!;
      
      // Get all users data to find names
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      Map<String, String> userNames = {};
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        userNames[userDoc.id] = userData['name'] ?? 'Unknown User';
      }

      // Calculate aggregated data
      int totalUsers = historyData.length;
      int totalTiffins = 0;
      int totalCurries = 0;
      int totalRevenue = 0;
      String topUser = 'N/A';
      int maxOrders = 0;

      historyData.forEach((userId, userData) {
        final userTiffins = userData['tiffins'] ?? 0;
        final userCurries = userData['curries'] ?? 0;
        final userTotal = userData['total'] ?? 0;

        totalTiffins += userTiffins as int;
        totalCurries += userCurries as int;
        totalRevenue += userTotal as int;

        // Find top user by total orders
        int userTotalOrders = userTiffins + userCurries;
        if (userTotalOrders > maxOrders) {
          maxOrders = userTotalOrders;
          topUser = userNames[userId] ?? 'Unknown User';
        }
      });

      // Calculate derived metrics
      int totalOrders = totalTiffins + totalCurries;
      double dailyAverage = totalOrders / _getDaysInMonth(monthId);
      double averageRevenue = totalRevenue / _getDaysInMonth(monthId);
      double completionRate = 99.0; // This would need to be calculated based on your order completion logic

      setState(() {
        _currentData = {
          'totalUsers': totalUsers,
          'totalTiffins': totalTiffins,
          'totalCurries': totalCurries,
          'totalRevenue': totalRevenue,
          'topUser': topUser,
          'dailyAverage': double.parse(dailyAverage.toStringAsFixed(1)),
          'averageRevenue': double.parse(averageRevenue.toStringAsFixed(1)),
          'totalOrders': totalOrders,
          'completionRate': completionRate,
        };
        _isLoading = false;
      });

    } catch (e) {
      print('Error loading monthly data: $e');
      setState(() {
        _currentData = _getEmptyData();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getEmptyData() {
    return {
      'totalUsers': 0,
      'totalTiffins': 0,
      'totalCurries': 0,
      'totalRevenue': 0,
      'topUser': 'N/A',
      'dailyAverage': 0.0,
      'averageRevenue': 0.0,
      'totalOrders': 0,
      'completionRate': 0.0,
    };
  }

  int _getDaysInMonth(String monthId) {
    try {
      final parts = monthId.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      return DateTime(year, month + 1, 0).day;
    } catch (e) {
      return 30; // Default fallback
    }
  }

  String _formatMonthDisplay(String monthId) {
    try {
      final parts = monthId.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);
      return DateFormat('MMMM yyyy').format(date);
    } catch (e) {
      return monthId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header with Month Selector
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
                            Icons.analytics,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Monthly Reports",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _loadMonthlyData(_selectedMonth);
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _availableMonths.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                "No data available",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : DropdownButton<String>(
                              value: _selectedMonth,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedMonth = newValue;
                                  });
                                  _loadMonthlyData(newValue);
                                }
                              },
                              dropdownColor: const Color(0xFF82B29A),
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                              ),
                              underline: Container(),
                              items: _availableMonths.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    _formatMonthDisplay(value),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Loading or Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF82B29A)),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            // Revenue and Users Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildReportCard(
                                    "Total Revenue",
                                    "₹${_formatNumber(_currentData['totalRevenue'])}",
                                    Icons.currency_rupee,
                                    const Color(0xFF82B29A),
                                    "Monthly earnings",
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildReportCard(
                                    "Active Users",
                                    "${_currentData['totalUsers']}",
                                    Icons.people,
                                    const Color(0xFF6BAF92),
                                    "Registered customers",
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Tiffins and Curries Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildReportCard(
                                    "Total Tiffins",
                                    "${_currentData['totalTiffins']}",
                                    Icons.restaurant,
                                    const Color(0xFF98C5AB),
                                    "Avg: ${_currentData['dailyAverage']}/day",
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildReportCard(
                                    "Extra Curries",
                                    "${_currentData['totalCurries']}",
                                    Icons.soup_kitchen,
                                    const Color(0xFF82B29A),
                                    _currentData['totalOrders'] > 0 
                                        ? "${((_currentData['totalCurries'] / _currentData['totalOrders']) * 100).toStringAsFixed(1)}% of orders"
                                        : "0% of orders",
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Top Performer and Average Revenue Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildReportCard(
                                    "Top Customer",
                                    _currentData['topUser'],
                                    Icons.star,
                                    const Color(0xFFFFD700),
                                    "Most orders this month",
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildReportCard(
                                    "Avg Daily Revenue",
                                    "₹${_formatNumber(_currentData['averageRevenue'])}",
                                    Icons.trending_up,
                                    const Color(0xFF6BAF92),
                                    "Per day average",
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Additional Stats
                            Row(
                              children: [
                                Expanded(
                                  child: _buildReportCard(
                                    "Total Orders",
                                    "${_currentData['totalOrders']}",
                                    Icons.receipt_long,
                                    const Color(0xFF98C5AB),
                                    "Tiffins + Curries",
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildReportCard(
                                    "Days Active",
                                    "${_getDaysInMonth(_selectedMonth)}",
                                    Icons.calendar_month,
                                    const Color(0xFF4CAF50),
                                    "Days in month",
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Monthly Summary Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF82B29A).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.summarize,
                                          color: Color(0xFF82B29A),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        "Monthly Summary",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inter',
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSummaryItem(
                                    "Revenue per User",
                                    _currentData['totalUsers'] > 0 
                                        ? "₹${(_currentData['totalRevenue'] / _currentData['totalUsers']).toStringAsFixed(0)}"
                                        : "₹0",
                                    Icons.person_pin,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildSummaryItem(
                                    "Average Order Value",
                                    _currentData['totalOrders'] > 0 
                                        ? "₹${(_currentData['totalRevenue'] / _currentData['totalOrders']).toStringAsFixed(0)}"
                                        : "₹0",
                                    Icons.receipt,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildSummaryItem(
                                    "Tiffin to Curry Ratio",
                                    _currentData['totalCurries'] > 0 
                                        ? "${(_currentData['totalTiffins'] / _currentData['totalCurries']).toStringAsFixed(1)}:1"
                                        : "∞:1",
                                    Icons.pie_chart,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildSummaryItem(
                                    "Orders per User",
                                    _currentData['totalUsers'] > 0 
                                        ? "${(_currentData['totalOrders'] / _currentData['totalUsers']).toStringAsFixed(1)}"
                                        : "0",
                                    Icons.person,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Export Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _exportReport();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF82B29A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.download, size: 20),
                                label: Text(
                                  "Export Report for ${_formatMonthDisplay(_selectedMonth)}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Icon(
                _currentData['totalRevenue'] > 0 ? Icons.trending_up : Icons.trending_flat,
                color: _currentData['totalRevenue'] > 0 ? Colors.green : Colors.grey,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF718096),
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF718096),
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF82B29A),
          size: 16,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5568),
              fontFamily: 'Inter',
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    return NumberFormat('#,##,###').format(number);
  }

  void _exportReport() {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF82B29A)),
        ),
      ),
    );

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Report exported for ${_formatMonthDisplay(_selectedMonth)}'),
            ],
          ),
          backgroundColor: const Color(0xFF82B29A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }
}