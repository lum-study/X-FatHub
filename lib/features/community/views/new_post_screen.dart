import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/community_provider.dart';
import '../widgets/custom_video_player.dart';
import 'map_picker_screen.dart';
import 'activity_picker_screen.dart';
import '../../activity_health/models/activity_model.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isPublishing = false;
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedFiles = [];

  // Location variables
  String? _selectedLocationName;
  double? _selectedLat;
  double? _selectedLng;

  // Selected Activity variable
  ActivityModel? _selectedActivity;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultipleMedia();
      if (pickedFiles.isNotEmpty) {
        
        final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov', 'avi', 'mkv'];
        List<File> validFiles = [];

        for (var f in pickedFiles) {
          final ext = f.path.split('.').last.toLowerCase();
          if (allowedExtensions.contains(ext)) {
            validFiles.add(File(f.path));
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('File format .$ext is not supported')),
              );
            }
          }
        }

        if (validFiles.isNotEmpty) {
          final needed = 10 - _selectedFiles.length;
          
          setState(() {
            if (needed > 0) {
              _selectedFiles.addAll(validFiles.take(needed));
            }
          });

          if (mounted && validFiles.length > needed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You can only upload up to 10 media files. Exceeding files were discarded.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to pick media: $e')),
        );
      }
    }
  }

  void _removeMedia(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  void _publishPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedFiles.isEmpty) return;

    setState(() => _isPublishing = true);

    try {
      final supa = Supabase.instance.client;
      List<String> uploadedUrls = [];

      // Upload media if any
      if (_selectedFiles.isNotEmpty) {
        // Try uploading to a bucket named 'community_media'
        for (int i = 0; i < _selectedFiles.length; i++) {
          final file = _selectedFiles[i];
          final extension = file.path.split('.').last.toLowerCase();
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
          final path = '${supa.auth.currentUser?.id ?? 'public'}/$fileName';
          
          await supa.storage.from('community_media').upload(path, file);
          final url = supa.storage.from('community_media').getPublicUrl(path);
          uploadedUrls.add(url);
        }
      }

      await context.read<CommunityProvider>().createPost(
        content,
        mediaUrls: uploadedUrls,
        locationName: _selectedLocationName,
        locationLat: _selectedLat,
        locationLng: _selectedLng,
        activityId: _selectedActivity?.id,
        activityType: _selectedActivity?.activityType,
        activityTitle: _selectedActivity?.title,
        activityDurationSeconds: _selectedActivity?.totalDuration?.inSeconds,
        activityDistance: _selectedActivity?.distanceTraveled,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing post: $e\n(Make sure "community_media" bucket exists in Supabase!)')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Post',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 16.0,
              top: 10.0,
              bottom: 10.0,
            ),
            child: TextButton(
              onPressed: _isPublishing ? null : _publishPost,
              style: TextButton.styleFrom(
                backgroundColor: _isPublishing ? const Color(0xFF333333) : const Color(0xFF1A1000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
              ),
              child: _isPublishing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    )
                  : const Text(
                      'Publish',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.person, color: Colors.black),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Posting to All Members',
                      style: TextStyle(
                        color: const Color(0xFF777777),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Input Area
            Container(
              constraints: const BoxConstraints(minHeight: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                border: Border.all(color: const Color(0xFF2A2A2A)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText:
                      'Share your fitness journey, ask for advice, or post a workout...',
                  hintStyle: TextStyle(color: Color(0xFF555555)),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Add Tools Section
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    final ext = file.path.split('.').last.toLowerCase();
                    final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(ext);

                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: isVideo ? null : DecorationImage(
                              image: FileImage(file),
                              fit: BoxFit.cover,
                            ),
                            color: const Color(0xFF1E1E1E),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: isVideo 
                              ? CustomVideoPlayer(
                                  videoUrl: file.path, 
                                  isFile: true, 
                                  autoPlay: false, 
                                  showControls: false,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        Positioned(
                          top: 4,
                          right: 16,
                          child: GestureDetector(
                            onTap: () => _removeMedia(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 14),

            Row(
              children: [
                const Icon(Icons.attachment, color: Colors.orange, size: 14),
                const SizedBox(width: 5),
                Text(
                  'ADD TO YOUR POST',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 11,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tool Items
            GestureDetector(
              onTap: () => _pickMedia(),
              child: _buildToolRow(Icons.camera_alt, 'Photo / Video'),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final selected = await Navigator.push<ActivityModel>(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivityPickerScreen()),
                );
                if (selected != null) {
                  setState(() {
                    _selectedActivity = selected;
                  });
                }
              },
              child: _buildToolRow(
                Icons.fitness_center,
                _selectedActivity != null ? (_selectedActivity!.title ?? '${_selectedActivity!.activityType[0].toUpperCase()}${_selectedActivity!.activityType.substring(1)}') : 'Tag a Workout',
                iconColor: Colors.orange,
                textColor: _selectedActivity != null ? Colors.orange : const Color(0xFFAAAAAA),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPickerScreen()));
                if (result != null) {
                  setState(() {
                    _selectedLocationName = result['name'];
                    _selectedLat = result['lat'];
                    _selectedLng = result['lng'];
                  });
                }
              },
              child: _buildToolRow(
                Icons.location_on, 
                _selectedLocationName ?? 'Add a location',
                iconColor: Colors.orange,
                textColor: _selectedLocationName != null ? Colors.orange : const Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolRow(IconData icon, String text, {Color iconColor = Colors.orange, Color textColor = const Color(0xFFAAAAAA)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
