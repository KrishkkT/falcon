import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class ContactDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> contact;

  const ContactDetailsScreen({super.key, required this.contact});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Handle error - couldn't launch URL
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Member'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.largeRadius,
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  children: [
                    // Profile avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          contact['name']?.toString().isNotEmpty == true
                              ? contact['name']![0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name and status
                    Text(
                      contact['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      contact['status'] ?? 'Team Member',
                      style: AppTheme.captionStyle.copyWith(
                        fontSize: 16,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Online status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: contact['isOnline'] == true
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: AppTheme.mediumRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            contact['isOnline'] == true
                                ? Icons.circle
                                : Icons.circle_outlined,
                            size: 12,
                            color: contact['isOnline'] == true
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            contact['isOnline'] == true ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: contact['isOnline'] == true
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Contact information
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.largeRadius,
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Phone number
                    if (contact['mobile'] != null) ...[
                      _buildContactInfoItem(
                        icon: Icons.phone,
                        title: 'Phone',
                        value: contact['mobile'],
                        onTap: () => _launchUrl('tel:${contact['mobile']}'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Email
                    if (contact['email'] != null) ...[
                      _buildContactInfoItem(
                        icon: Icons.email,
                        title: 'Email',
                        value: contact['email'],
                        onTap: () => _launchUrl('mailto:${contact['email']}'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // LinkedIn
                    if (contact['linkedin'] != null) ...[
                      _buildContactInfoItem(
                        icon: Icons.link,
                        title: 'LinkedIn',
                        value: contact['linkedin'],
                        onTap: () => _launchUrl(contact['linkedin']),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16), // Add some space at the bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfoItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: AppTheme.mediumRadius,
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.captionStyle.copyWith(
                    fontSize: 12,
                    color: AppTheme.greyColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.darkColor,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.greyColor,
            ),
        ],
      ),
    );
  }
}
