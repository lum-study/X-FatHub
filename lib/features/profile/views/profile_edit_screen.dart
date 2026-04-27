import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../viewmodels/profile_viewmodel.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _birthdateController;
  late final TextEditingController _heightController;
  late final TextEditingController _initialWeightController;
  late final TextEditingController _goalWeightController;
  String? _selectedGender;
  DateTime? _selectedBirthdate;
  String? _pendingProfileImagePath;

  bool _isLoading = false;

  String _formatDateForInput(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    // Validate: only ensure above 12 age
    final firstDate = DateTime(1900);
    final lastDate = DateTime(now.year - 12, now.month, now.day);

    if (firstDate.isAfter(lastDate)) {
      return;
    }

    final initialDate = _selectedBirthdate != null && 
                        _selectedBirthdate!.isAfter(firstDate) && 
                        _selectedBirthdate!.isBefore(lastDate)
        ? _selectedBirthdate!
        : lastDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.orange,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E1E1E),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedBirthdate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
      _birthdateController.text = _formatDateForInput(_selectedBirthdate!);
    });
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Change Profile Picture',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.orange),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.orange),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 80);
    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _pendingProfileImagePath = image.path;
    });
  }

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileViewModel>().profile;
    
    _nameController = TextEditingController(text: profile?.name ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _birthdateController = TextEditingController(
      text: profile?.birthdate != null ? _formatDateForInput(profile!.birthdate!) : '',
    );
    _selectedBirthdate = profile?.birthdate != null
        ? DateTime(
            profile!.birthdate!.year,
            profile.birthdate!.month,
            profile.birthdate!.day,
          )
        : null;
    _heightController = TextEditingController(text: profile?.height?.toString() ?? '');
    _initialWeightController = TextEditingController(text: profile?.initialWeight?.toString() ?? '');
    _goalWeightController = TextEditingController(text: profile?.weightGoal?.toString() ?? '');
    final normalizedGender = profile?.gender?.toLowerCase();
    _selectedGender = const ['male', 'female', 'other', 'prefer not to say'].contains(normalizedGender)
        ? normalizedGender
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _birthdateController.dispose();
    _heightController.dispose();
    _initialWeightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    setState(() => _isLoading = true);

    try {
      final nameText = _nameController.text.trim();
      if (nameText.isEmpty) {
        throw Exception('Name is required');
      }
      if (nameText.length > 15) {
        throw Exception('Name must be 15 characters or less');
      }

      final bioText = _bioController.text.trim();
      if (bioText.isEmpty) {
        throw Exception('Bio is required');
      }
      if (bioText.length > 30) {
        throw Exception('Bio must be 30 characters or less');
      }

      if (_selectedBirthdate == null) {
        throw Exception('Birthdate is required');
      }

      if (_selectedGender == null) {
        throw Exception('Gender is required');
      }

      if (_heightController.text.trim().isEmpty) {
        throw Exception('Height is required');
      }
      final height = double.tryParse(_heightController.text);
      if (height == null || height <= 0) {
         throw Exception('Enter a valid height');
      }

      if (_initialWeightController.text.trim().isEmpty) {
        throw Exception('Initial Weight is required');
      }
      final initialWeight = double.tryParse(_initialWeightController.text);
      if (initialWeight == null || initialWeight <= 0) {
         throw Exception('Enter a valid initial weight');
      }

      if (_goalWeightController.text.trim().isEmpty) {
        throw Exception('Goal Weight is required');
      }
      final goalWeight = double.tryParse(_goalWeightController.text);
      if (goalWeight == null || goalWeight <= 0) {
         throw Exception('Enter a valid goal weight');
      }

      if (initialWeight == goalWeight) {
        throw Exception('Goal weight cannot be the same as initial weight');
      }

      final provider = context.read<ProfileViewModel>();
      
      // Calculate age from birthdate
      int? calculatedAge;
      if (_selectedBirthdate != null) {
        final now = DateTime.now();
        calculatedAge = now.year - _selectedBirthdate!.year;
        if (now.month < _selectedBirthdate!.month || (now.month == _selectedBirthdate!.month && now.day < _selectedBirthdate!.day)) {
          calculatedAge--;
        }
      }

      await provider.updateProfile(
        name: nameText,
        bio: bioText,
        age: calculatedAge,
        gender: _selectedGender,
        birthdate: _selectedBirthdate,
        height: height,
        initialWeight: initialWeight,
        weightGoal: goalWeight,
      );

      if (_pendingProfileImagePath != null) {
        await provider.uploadProfilePicture(_pendingProfileImagePath!);
        _pendingProfileImagePath = null;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileViewModel = context.watch<ProfileViewModel>();
    final profile = profileViewModel.profile;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            // Profile Picture Section
            Center(
              child: GestureDetector(
                onTap: _showImagePicker,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.withOpacity(0.2),
                        border: Border.all(color: Colors.orange, width: 2),
                        image: _pendingProfileImagePath != null
                            ? DecorationImage(
                                image: FileImage(File(_pendingProfileImagePath!)),
                                fit: BoxFit.cover,
                              )
                            : (profile?.profilePictureUrl != null &&
                                    profile!.profilePictureUrl!.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(profile.profilePictureUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: (_pendingProfileImagePath == null &&
                              (profile?.profilePictureUrl == null ||
                                  profile!.profilePictureUrl!.isEmpty))
                          ? const Icon(Icons.person, size: 50, color: Colors.orange)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Personal Information'),
            
            // Name Field
            Text(
              'Name',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              maxLength: 15,
              inputFormatters: [
                LengthLimitingTextInputFormatter(15),
              ],
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                counterText: "", // Hide counter
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bio Field
            Text(
              'Bio',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              maxLength: 30,
              inputFormatters: [
                LengthLimitingTextInputFormatter(30),
              ],
              decoration: InputDecoration(
                hintText: 'Tell us about yourself',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Birthdate Field
            Text(
              'Birthdate (YYYY-MM-DD)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _birthdateController,
              readOnly: true,
              onTap: _pickBirthdate,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pick your birthdate',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                suffixIcon: IconButton(
                  onPressed: _pickBirthdate,
                  icon: const Icon(Icons.calendar_month, color: Colors.orange),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gender Field
            Text(
              'Gender',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Select your gender',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
                DropdownMenuItem(value: 'prefer not to say', child: Text('Prefer not to say')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Body Information'),

            // Height Field
            Text(
              'Height (cm)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your height in cm',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Initial Weight Field
            Text(
              'Initial Weight (kg)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _initialWeightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your initial weight in kg',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Goal Weight Field
            Text(
              'Goal Weight (kg)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _goalWeightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your goal weight in kg',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Update Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Update Profile',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
