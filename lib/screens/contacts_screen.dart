import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io'; // Added for SocketException
import 'dart:async'; // Added for TimeoutException

import '../theme/app_theme.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../screens/contact_details_screen.dart'; // Add this import
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isLoadingSearch = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Use hardcoded team members with additional contact information
      final teamMembers = [
        {
          'id': '1',
          'name': 'Madhurya Telang',
          'status': 'Team Lead',
          'isOnline': true,
          'mobile': '+91 9016333960',
          'email': '23ituoz133@ddu.ac.in',
          'linkedin': 'https://linkedin.com/in/madhurya-telang-8bb2772bb',
        },
        {
          'id': '2',
          'name': 'Krish Thakker',
          'status': 'AWS',
          'isOnline': true,
          'mobile': '+91 9429984468',
          'email': '23ituos134@ddu.ac.in',
          'linkedin': 'https://linkedin.com/in/krishthakker08',
        },
        {
          'id': '3',
          'name': 'Shyam Kundalia',
          'status': 'Designer',
          'isOnline': false,
          'mobile': '+91 9510747350',
          'email': '23ituoz125@ddu.ac.in',
          'linkedin': 'https://linkedin.com/in/shyam-k-245271294',
        },
        {
          'id': '4',
          'name': 'Sarthak Tandel',
          'status': 'Backend Developer',
          'isOnline': true,
          'mobile': '+91 8140046213',
          'email': '23ituos131@ddu.ac.in',
          'linkedin': 'https://linkedin.com/in/sarthak-tandel-b705692b4',
        },
        {
          'id': '5',
          'name': 'Garima Chotai',
          'status': 'QA Engineer',
          'isOnline': true,
          'mobile': '+91 9054286490',
          'email': '23ituoz017@ddu.ac.in',
          'linkedin': 'https://linkedin.com/in/garima-chotai-b4bb0a386',
        },
        {
          'id': '6',
          'name': 'Jiya Patel',
          'status': 'UI/UX Designer',
          'isOnline': true,
          'mobile': '+91 9316996835',
          'email': '23ituoz057@ddu.ac.in',
          'linkedin': 'https://linkedin.com/in/jiya-patel',
        },
      ];

      if (mounted) {
        setState(() {
          _contacts = teamMembers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _showErrorSnackBar('Failed to load contacts: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  Future<void> _searchContacts(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoadingSearch = false;
      });
      return;
    }

    setState(() {
      _isLoadingSearch = true;
    });

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final results = await chatService.searchUsers(query);

      setState(() {
        _searchResults = results;
        _isLoadingSearch = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSearch = false;
      });
      _showErrorSnackBar('Search failed: ${e.toString()}');
    }
  }

  void _startChat(Map<String, dynamic> contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailsScreen(contact: contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),

            // Contacts List
            Expanded(
              child: _buildContactsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          if (value.trim().isEmpty) {
            setState(() {
              _isSearching = false;
              _searchResults = [];
            });
          } else {
            setState(() {
              _isSearching = true;
            });
            // Debounce search
            Future.delayed(const Duration(milliseconds: 300), () {
              if (_searchController.text == value) {
                _searchContacts(value);
              }
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'Search contacts...',
          labelStyle: const TextStyle(
            color: AppTheme.greyColor,
            fontSize: 14,
          ),
          hintText: 'Type a name or phone number...',
          hintStyle: const TextStyle(
            color: AppTheme.greyColor,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppTheme.primaryColor,
          ),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.greyColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                      _searchResults = [];
                    });
                  },
                )
              : null,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: AppTheme.mediumRadius,
            borderSide:
                BorderSide(color: AppTheme.greyColor.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppTheme.mediumRadius,
            borderSide:
                BorderSide(color: AppTheme.greyColor.withValues(alpha: 0.3)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppTheme.mediumRadius,
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    final List<Map<String, dynamic>> displayList =
        _isSearching ? _searchResults : _contacts;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (displayList.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadContacts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayList.length,
        itemBuilder: (context, index) {
          final contact = displayList[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.mediumRadius,
              boxShadow: AppTheme.softShadow,
            ),
            clipBehavior: Clip.hardEdge,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        contact['avatar']?.toString() ??
                            (contact['name']?.toString().isNotEmpty == true
                                ? contact['name']![0].toUpperCase()
                                : 'U'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Online status indicator
                  if (contact['isOnline'] == true)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                contact['name']?.toString() ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['status']?.toString() ?? 'Team Member',
                    style: AppTheme.captionStyle.copyWith(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (contact['mobile'] != null)
                    Text(
                      contact['mobile'],
                      style: AppTheme.captionStyle.copyWith(
                        fontSize: 11,
                        color: AppTheme.greyColor,
                      ),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.info_outline,
                    color: AppTheme.primaryColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ContactDetailsScreen(contact: contact),
                    ),
                  );
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ContactDetailsScreen(contact: contact),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 80,
            color: AppTheme.greyColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No contacts found',
            style: AppTheme.headingStyle,
          ),
          const SizedBox(height: 8),
          const Text(
            'Try searching for someone or refresh the list',
            style: AppTheme.captionStyle,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadContacts,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: AppTheme.mediumRadius,
              ),
            ),
            child: const Text('Refresh Contacts'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
