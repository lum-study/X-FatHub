import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../../../routes/app_routes.dart';
import '../../../core/service/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final isEnabled = await NotificationService.areNotificationsEnabled();
    setState(() {
      _notificationsEnabled = isEnabled;
    });
  }

  void _showOfflineSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You are offline now. This feature is disabled.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Effective date: April 23, 2026',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 12),
              _buildPrivacySection(
                'Information We Collect',
                'We collect profile information you provide, including name, email, bio, birthdate, gender, height, and weight records.',
              ),
              _buildPrivacySection(
                'How We Use Information',
                'Your data is used to provide tracking features, calculate progress, personalize your dashboard, and improve app reliability.',
              ),
              _buildPrivacySection(
                'Storage and Security',
                'Data is stored in secure cloud services with access controls. We apply technical safeguards, but no service is absolutely risk-free.',
              ),
              _buildPrivacySection(
                'Data Sharing',
                'We do not sell your personal data. We share data only with infrastructure providers required to operate the app.',
              ),
              _buildPrivacySection(
                'Your Choices',
                'You can update your profile, update weight records, or request account deletion from inside the app settings.',
              ),
              _buildPrivacySection(
                'Contact',
                'For privacy questions, contact support at support@xfithub.app.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showTermsOfServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Terms of Service',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Effective date: April 23, 2026',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 12),
              _buildPrivacySection(
                'Use of Service',
                'You agree to use this app for lawful personal fitness and wellness tracking only.',
              ),
              _buildPrivacySection(
                'Account Responsibility',
                'You are responsible for keeping your login credentials secure and for activity under your account.',
              ),
              _buildPrivacySection(
                'Health Disclaimer',
                'This app provides informational tracking only and does not replace medical advice, diagnosis, or treatment.',
              ),
              _buildPrivacySection(
                'Content and Conduct',
                'You must not upload harmful, abusive, or illegal content through profile fields or community features.',
              ),
              _buildPrivacySection(
                'Termination',
                'We may suspend access for misuse. You may stop using the service at any time and delete your account.',
              ),
              _buildPrivacySection(
                'Changes',
                'We may update these terms and will publish the latest version in the app settings page.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(color: Colors.grey[300], fontSize: 12),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DeleteAccountDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final isOnline = profileVM.isOnline;

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outlined, 
                        color: isOnline ? Colors.orange : Colors.grey[600], 
                        size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Change Password',
                        style: TextStyle(color: isOnline ? Colors.white : Colors.grey[600]),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, 
                      color: isOnline ? Colors.grey : Colors.grey[800], 
                      size: 16),
                    onPressed: isOnline ? _showChangePasswordDialog : () => _showOfflineSnackBar(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Notifications Section
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildNotificationTile(
              title: 'Push Notifications',
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() => _notificationsEnabled = value);
                await NotificationService.setNotificationsEnabled(value);
              },
            ),
            const SizedBox(height: 32),

            // Privacy & Legal Section
            const Text(
              'Privacy & Legal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showPrivacyPolicyDialog,
              child: _buildLegalTile(
                title: 'Privacy Policy',
                icon: Icons.privacy_tip_outlined,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showTermsOfServiceDialog,
              child: _buildLegalTile(
                title: 'Terms of Service',
                icon: Icons.description_outlined,
              ),
            ),
            const SizedBox(height: 32),

            // App Info Section
            const Text(
              'App Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Version',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    '1.0.0',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Danger Zone Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOnline ? Colors.red.withOpacity(0.1) : Colors.grey[900],
                border: Border.all(color: isOnline ? Colors.red.withOpacity(0.5) : Colors.grey[800]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danger Zone',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOnline ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isOnline ? Colors.red : Colors.grey[800]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: isOnline ? _showDeleteAccountDialog : () => _showOfflineSnackBar(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Delete Account',
                          style: TextStyle(
                            color: isOnline ? Colors.red : Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Permanently delete your account and all associated data. This action cannot be undone.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOnline ? Colors.red : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.orange,
            inactiveThumbColor: Colors.grey[700],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalTile({
    required String title,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  int _step = 1; // 1: Password entry, 2: Final confirmation

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Password is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileVM = context.read<ProfileViewModel>();
      final email = profileVM.profile?.email;
      
      if (email == null) throw Exception('Email not found');

      // Try to sign in to verify password
      await profileVM.signIn(email, _passwordController.text);
      
      // If success, move to final step
      if (mounted) {
        setState(() {
          _step = 2;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Invalid password. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    setState(() => _isLoading = true);
    
    try {
      final profileVM = context.read<ProfileViewModel>();
      await profileVM.deleteAccount();
      
      if (mounted) {
        // Use the root navigator to replace EVERYTHING with home/login
        // This prevents the black screen caused by multiple nested navigators being destroyed
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          AppRoutes.home, 
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to delete account. Please try again later.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 1) {
      return AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Verify your Identity',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please enter your password to continue with account deletion.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                errorText: _errorMessage,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyPassword,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Verify', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    // Final Confirmation Step
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Text('Final Warning', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This action is PERMANENT.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 12),
          Text(
            'By confirming, all your profiles, tracking data, history, and active packages will be deleted forever. There is no way to recover your data.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Wait, I changed my mind', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleDelete,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirm Deletion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Change Password',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_currentPasswordController.text.isEmpty ||
                      _newPasswordController.text.isEmpty ||
                      _confirmPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (_newPasswordController.text != _confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('New passwords do not match'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (_newPasswordController.text == _currentPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('New password cannot be the same as current password'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (_newPasswordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password must be at least 6 characters'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  try {
                    final provider = context.read<ProfileViewModel>();
                    await provider.changePassword(
                      currentPassword: _currentPasswordController.text,
                      newPassword: _newPasswordController.text,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password changed successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      final errorMessage = context.read<ProfileViewModel>().error ?? e.toString();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.orange),
                  ),
                )
              : const Text('Change', style: TextStyle(color: Colors.orange)),
        ),
      ],
    );
  }
}
