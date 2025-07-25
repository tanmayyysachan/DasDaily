import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final Map<String, Map<String, dynamic>> _monthlyData = {
    'January 2025': {
      'totalUsers': 15,
      'totalTiffins': 450,
      'totalCurries': 180,
      'totalRevenue': 36900,
      'topUser': 'Raj Kumar',
      'dailyAverage': 23.5,
      'averageRevenue': 1890.5,
      'totalOrders': 630,
      'completionRate': 98.2,
    },
    'February 2025': {
      'totalUsers': 18,
      'totalTiffins': 520,
      'totalCurries': 200,
      'totalRevenue': 42400,
      'topUser': 'Priya Singh',
      'dailyAverage': 26.8,
      'averageRevenue': 2122.0,
      'totalOrders': 720,
      'completionRate': 97.8,
    },
    'December 2024': {
      'totalUsers': 12,
      'totalTiffins': 380,
      'totalCurries': 150,
      'totalRevenue': 31100,
      'topUser': 'Amit Sharma',
      'dailyAverage': 19.2,
      'averageRevenue': 1672.5,
      'totalOrders': 530,
      'completionRate': 96.5,
    },
    'July 2025': {
      'totalUsers': 22,
      'totalTiffins': 680,
      'totalCurries': 250,
      'totalRevenue': 55200,
      'topUser': 'Anita Patel',
      'dailyAverage': 30.0,
      'averageRevenue': 2760.0,
      'totalOrders': 930,
      'completionRate': 99.1,
    },
  };

  late String _selectedMonth;

  @override
  void initState() {
    super.initState();
    // Initialize with the current month if data exists, otherwise use the first available month
    String currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
    _selectedMonth = _monthlyData.containsKey(currentMonth) 
        ? currentMonth 
        : _monthlyData.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _monthlyData[_selectedMonth] ?? {
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedMonth,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedMonth = newValue;
                            });
                          }
                        },
                        dropdownColor: const Color(0xFF82B29A),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                        underline: Container(),
                        items: _monthlyData.keys.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
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

              // Monthly Stats
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Revenue and Users Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildReportCard(
                              "Total Revenue",
                              "₹${_formatNumber(currentData['totalRevenue'])}",
                              Icons.currency_rupee,
                              const Color(0xFF82B29A),
                              "+12.5% from last month",
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildReportCard(
                              "Active Users",
                              "${currentData['totalUsers']}",
                              Icons.people,
                              const Color(0xFF6BAF92),
                              "+3 new this month",
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
                              "${currentData['totalTiffins']}",
                              Icons.restaurant,
                              const Color(0xFF98C5AB),
                              "Avg: ${currentData['dailyAverage']}/day",
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildReportCard(
                              "Extra Curries",
                              "${currentData['totalCurries']}",
                              Icons.soup_kitchen,
                              const Color(0xFF82B29A),
                              "${((currentData['totalCurries'] / (currentData['totalTiffins'] + currentData['totalCurries']) * 100)).toStringAsFixed(1)}% of orders",
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
                              currentData['topUser'],
                              Icons.star,
                              const Color(0xFFFFD700),
                              "Most orders this month",
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildReportCard(
                              "Avg Daily Revenue",
                              "₹${_formatNumber(currentData['averageRevenue'])}",
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
                              "${currentData['totalOrders']}",
                              Icons.receipt_long,
                              const Color(0xFF98C5AB),
                              "Tiffins + Curries",
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildReportCard(
                              "Success Rate",
                              "${currentData['completionRate']}%",
                              Icons.check_circle,
                              const Color(0xFF4CAF50),
                              "Orders completed",
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
                              "₹${(currentData['totalRevenue'] / currentData['totalUsers']).toStringAsFixed(0)}",
                              Icons.person_pin,
                            ),
                            const SizedBox(height: 8),
                            _buildSummaryItem(
                              "Average Order Value",
                              "₹${(currentData['totalRevenue'] / currentData['totalOrders']).toStringAsFixed(0)}",
                              Icons.receipt,
                            ),
                            const SizedBox(height: 8),
                            _buildSummaryItem(
                              "Tiffin to Curry Ratio",
                              "${(currentData['totalTiffins'] / currentData['totalCurries']).toStringAsFixed(1)}:1",
                              Icons.pie_chart,
                            ),
                            const SizedBox(height: 8),
                            _buildSummaryItem(
                              "Daily Participation",
                              "${((currentData['totalOrders'] / (currentData['totalUsers'] * 30)) * 100).toStringAsFixed(1)}%",
                              Icons.calendar_today,
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
                            "Export Report for $_selectedMonth",
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
              const Icon(
                Icons.trending_up,
                color: Colors.green,
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
              Text('Report exported for $_selectedMonth'),
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