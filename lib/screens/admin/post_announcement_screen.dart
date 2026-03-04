import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/diablo_colors.dart';

class PostAnnouncementScreen extends StatefulWidget {
  const PostAnnouncementScreen({super.key});

  @override
  State<PostAnnouncementScreen> createState() => _PostAnnouncementScreenState();
}

class _PostAnnouncementScreenState extends State<PostAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _priority = 'normal';
  String _audience = 'all';
  bool _posting = false;

  static const _priorities = ['normal', 'urgent'];
  static const _audiences = ['all', 'varsity', 'jv', 'freshman'];

  static const _audienceLabels = {
    'all': 'All',
    'varsity': 'Varsity',
    'jv': 'JV',
    'freshman': 'Freshman',
  };

  static const _priorityLabels = {
    'normal': 'Normal',
    'urgent': 'Urgent',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: icon != null ? Icon(icon, color: DiabloColors.gold) : null,
      filled: true,
      fillColor: DiabloColors.darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: DiabloColors.gold),
      ),
    );
  }

  Future<void> _postAnnouncement() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and body are required'),
          backgroundColor: DiabloColors.red,
        ),
      );
      return;
    }

    setState(() => _posting = true);

    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'body': body,
        'priority': _priority,
        'audienceLevel': _audience,
        'author': 'Coach',
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': <String>[],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement posted'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: $e'),
            backgroundColor: DiabloColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _posting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'POST ANNOUNCEMENT',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                label: 'Title',
                icon: Icons.campaign,
              ),
            ),
            const SizedBox(height: 16),

            // Body
            TextField(
              controller: _bodyController,
              style: const TextStyle(color: Colors.white),
              maxLines: 5,
              decoration: _inputDecoration(label: 'Body'),
            ),
            const SizedBox(height: 16),

            // Priority
            DropdownButtonFormField<String>(
              value: _priority,
              dropdownColor: DiabloColors.darkCard,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                label: 'Priority',
                icon: Icons.priority_high,
              ),
              items: _priorities
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(_priorityLabels[p] ?? p),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 16),

            // Audience
            DropdownButtonFormField<String>(
              value: _audience,
              dropdownColor: DiabloColors.darkCard,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                label: 'Audience',
                icon: Icons.group,
              ),
              items: _audiences
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(_audienceLabels[a] ?? a),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _audience = value);
              },
            ),
            const SizedBox(height: 24),

            // Post button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _posting ? null : _postAnnouncement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiabloColors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: DiabloColors.red.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _posting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'POST',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
