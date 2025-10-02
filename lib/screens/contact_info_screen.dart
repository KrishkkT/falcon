import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ContactInfoScreen extends StatelessWidget {
  final Map<String, dynamic>? contact; // Add contact parameter

  const ContactInfoScreen({super.key, this.contact}); // Update constructor

  @override
  Widget build(BuildContext context) {
    // If contact is provided, show specific contact info, otherwise show team info
    if (contact != null) {
      return _buildContactInfo(context);
    } else {
      return _buildTeamInfo(context);
    }
  }

  Widget _buildContactInfo(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Information'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    contact!['name']?.toString().isNotEmpty == true
                        ? contact!['name']![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  contact!['name'] ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  contact!['status'] ?? 'Team Member',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.greyColor,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.mediumRadius,
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (contact!['mobile'] != null) ...[
                      _buildContactInfoRow(Icons.phone, contact!['mobile']),
                      const SizedBox(height: 10),
                    ],
                    if (contact!['email'] != null) ...[
                      _buildContactInfoRow(Icons.email, contact!['email']),
                      const SizedBox(height: 10),
                    ],
                    if (contact!['linkedin'] != null)
                      _buildContactInfoRow(Icons.link, contact!['linkedin']),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamInfo(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Information'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(
                    Icons.group,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Falcon Chat Development Team',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Our Team',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkColor,
                ),
              ),
              const SizedBox(height: 20),
              _buildTeamMemberCard(
                context,
                name: 'Krish Thakker',
                role: 'Lead Developer & Project Manager',
                mobile: '+91 98765 43210',
                email: 'krish.thakker@example.com',
                linkedin: 'linkedin.com/in/krisht',
              ),
              const SizedBox(height: 15),
              _buildTeamMemberCard(
                context,
                name: 'Alice Johnson',
                role: 'UI/UX Designer',
                mobile: '+1 555 123 4567',
                email: 'alice.johnson@example.com',
                linkedin: 'linkedin.com/in/alicej',
              ),
              const SizedBox(height: 15),
              _buildTeamMemberCard(
                context,
                name: 'Bob Smith',
                role: 'Backend Developer',
                mobile: '+44 7700 900123',
                email: 'bob.smith@example.com',
                linkedin: 'linkedin.com/in/bobsmith',
              ),
              const SizedBox(height: 15),
              _buildTeamMemberCard(
                context,
                name: 'Charlie Brown',
                role: 'Mobile Developer',
                mobile: '+61 412 345 678',
                email: 'charlie.brown@example.com',
                linkedin: 'linkedin.com/in/charlieb',
              ),
              const SizedBox(height: 15),
              _buildTeamMemberCard(
                context,
                name: 'Diana Wilson',
                role: 'Security Specialist',
                mobile: '+33 6 12 34 56 78',
                email: 'diana.wilson@example.com',
                linkedin: 'linkedin.com/in/dianaw',
              ),
              const SizedBox(height: 15),
              _buildTeamMemberCard(
                context,
                name: 'Ethan Davis',
                role: 'QA Engineer',
                mobile: '+1 416 555 9876',
                email: 'ethan.davis@example.com',
                linkedin: 'linkedin.com/in/ethand',
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.mediumRadius,
                  boxShadow: AppTheme.softShadow,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About This Project',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Falcon Chat is a secure messaging application developed by a team of 6 professionals. '
                      'The application features end-to-end encryption, biometric authentication, '
                      'secure file sharing, and military-grade security protocols.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.darkColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(
    BuildContext context, {
    required String name,
    required String role,
    required String mobile,
    required String email,
    required String linkedin,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.mediumRadius,
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            role,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.greyColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          _buildContactInfoRow(Icons.phone, mobile),
          const SizedBox(height: 8),
          _buildContactInfoRow(Icons.email, email),
          const SizedBox(height: 8),
          _buildContactInfoRow(Icons.link, linkedin),
        ],
      ),
    );
  }

  Widget _buildContactInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.darkColor,
            ),
          ),
        ),
      ],
    );
  }
}
