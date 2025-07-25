// menu_manager.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MenuManager extends StatefulWidget {
  const MenuManager({super.key});

  @override
  State<MenuManager> createState() => _MenuManagerState();
}

class _MenuManagerState extends State<MenuManager> {
  final List<String> _menuItems = [
    "Fresh Roti",
    "Basmati Rice",
    "Traditional Dal",
    "Mix Veg Curry",
    "Salad & Curd",
  ];

  final List<String> _selectedItems = [];
  bool _isMenuActive = true;
  final TextEditingController _customItemController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Menu Management",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isMenuActive,
                    onChanged: (value) {
                      setState(() {
                        _isMenuActive = value;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isMenuActive 
                                ? 'Menu activated for users' 
                                : 'Menu deactivated',
                          ),
                          backgroundColor: const Color(0xFF82B29A),
                        ),
                      );
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Menu Items
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
                              "Today's Menu Items",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _showAddItemDialog,
                              icon: const Icon(
                                Icons.add_circle,
                                color: Color(0xFF82B29A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _menuItems.length,
                          itemBuilder: (context, index) {
                            final item = _menuItems[index];
                            final isSelected = _selectedItems.contains(item);
                            return _buildMenuItemTile(item, isSelected, index);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Update Menu Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6BAF92),
                    Color(0xFF82B29A),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF82B29A).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _updateMenu,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 40,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.update,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Update Menu for Users",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemTile(String item, bool isSelected, int index) {
    final emojis = ["🫓", "🍚", "🥘", "🥬", "🥗"];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF82B29A).withOpacity(0.1) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF82B29A) : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Text(
          index < emojis.length ? emojis[index] : "🍽️",
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          item,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            color: isSelected ? const Color(0xFF82B29A) : const Color(0xFF1F2937),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value!) {
                    _selectedItems.add(item);
                  } else {
                    _selectedItems.remove(item);
                  }
                });
              },
              activeColor: const Color(0xFF82B29A),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeMenuItem(index),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Menu Item'),
        content: TextField(
          controller: _customItemController,
          decoration: const InputDecoration(
            hintText: 'Enter item name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_customItemController.text.isNotEmpty) {
                setState(() {
                  _menuItems.add(_customItemController.text);
                  _customItemController.clear();
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF82B29A),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeMenuItem(int index) {
    setState(() {
      final item = _menuItems[index];
      _selectedItems.remove(item);
      _menuItems.removeAt(index);
    });
  }

  void _updateMenu() {
    // Here you would update the menu in your backend/database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menu updated successfully!'),
        backgroundColor: Color(0xFF82B29A),
      ),
    );
  }
}