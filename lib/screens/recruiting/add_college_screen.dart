import 'package:flutter/material.dart';
import '../../theme/diablo_colors.dart';

class AddCollegeScreen extends StatefulWidget {
  const AddCollegeScreen({super.key});

  @override
  State<AddCollegeScreen> createState() => _AddCollegeScreenState();
}

class _AddCollegeScreenState extends State<AddCollegeScreen> {
  final _schoolController = TextEditingController();
  final _coachController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedLevel = 'D1';

  static const _levels = ['D1', 'D2', 'D3', 'NAIA', 'JUCO'];

  @override
  void dispose() {
    _schoolController.dispose();
    _coachController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: DiabloColors.gold),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'ADD COLLEGE',
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
            // School name
            TextField(
              controller: _schoolController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                label: 'School Name',
                icon: Icons.school,
              ),
            ),
            const SizedBox(height: 16),

            // Level dropdown
            DropdownButtonFormField<String>(
              value: _selectedLevel,
              dropdownColor: DiabloColors.darkCard,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                label: 'Level',
                icon: Icons.sports_football,
              ),
              items: _levels
                  .map(
                    (level) => DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLevel = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Coach contact
            TextField(
              controller: _coachController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                label: 'Coach Contact (optional)',
                icon: Icons.person,
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: _inputDecoration(
                label: 'Notes (optional)',
                icon: Icons.note,
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiabloColors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'SAVE',
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
