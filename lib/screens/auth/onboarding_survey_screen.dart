import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/diablo_colors.dart';
import '../../widgets/diamond_divider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class OnboardingSurveyScreen extends ConsumerStatefulWidget {
  const OnboardingSurveyScreen({super.key});

  @override
  ConsumerState<OnboardingSurveyScreen> createState() =>
      _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState
    extends ConsumerState<OnboardingSurveyScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Q1: Goals (multi-select)
  final Set<String> _selectedGoals = {};
  // Q2: Recruiting interest
  String? _recruitingInterest;
  // Q3: Top priority
  String? _topPriority;
  // Q4: Dream school
  final _dreamSchoolController = TextEditingController();
  // Q5: Agent tone
  String? _agentTone;

  @override
  void dispose() {
    _pageController.dispose();
    _dreamSchoolController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final uid = ref.read(currentUidProvider);
    final appUser =
        ref.read(appUserProvider).whenOrNull(data: (u) => u);
    final playerId = appUser?.linkedPlayerId ?? uid;

    try {
      await FirebaseFirestore.instance
          .collection('playerPreferences')
          .doc(playerId)
          .set({
        'selectedGoals': _selectedGoals.toList(),
        'recruitingInterest': _recruitingInterest,
        'topPriority': _topPriority,
        'dreamSchool': _dreamSchoolController.text,
        'agentTone': _agentTone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    // Mark onboarding as complete
    try {
      await FirestoreService().updateUser(uid, {
        'onboardingSurveyComplete': true,
      });
    } catch (_) {}

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.dark,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'GET STARTED',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentPage + 1) / 5,
            backgroundColor: DiabloColors.dark,
            color: DiabloColors.gold,
            minHeight: 3,
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _buildGoalsPage(),
                _buildRecruitingPage(),
                _buildPriorityPage(),
                _buildDreamSchoolPage(),
                _buildTonePage(),
              ],
            ),
          ),

          // Next button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _next,
                child: Text(_currentPage == 4 ? 'FINISH' : 'NEXT'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyPage({
    required String question,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const DiamondDivider(
            color: DiabloColors.gold,
            alignment: MainAxisAlignment.start,
            lineWidth: 40,
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    final goals = {
      'start_varsity': 'Start on Varsity',
      'get_stronger': 'Get Stronger / Hit New PRs',
      'play_college': 'Play College Football',
      'earn_scholarship': 'Earn a Scholarship',
      'be_leader': 'Be a Team Leader',
    };

    return _buildSurveyPage(
      question: 'What are your goals this season?',
      child: Column(
        children: goals.entries.map((entry) {
          final selected = _selectedGoals.contains(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedGoals.remove(entry.key);
                  } else {
                    _selectedGoals.add(entry.key);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected
                      ? DiabloColors.red.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? DiabloColors.red : Colors.white24,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: selected ? DiabloColors.gold : Colors.white54,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      entry.value,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecruitingPage() {
    final options = {
      'high': 'High — actively reaching out',
      'some': 'Some — exploring options',
      'notYet': 'Not yet — focused on this season',
    };

    return _buildSurveyPage(
      question: 'How interested are you in recruiting right now?',
      child: _buildSingleSelect(options, _recruitingInterest, (v) {
        setState(() => _recruitingInterest = v);
      }),
    );
  }

  Widget _buildPriorityPage() {
    final options = {
      'recruiting': 'Recruiting & College Outreach',
      'strength': 'Strength & Conditioning',
      'gamePrep': 'Game Prep & Film',
      'academics': 'Academics & Eligibility',
    };

    return _buildSurveyPage(
      question: 'What do you want help with most?',
      child: _buildSingleSelect(options, _topPriority, (v) {
        setState(() => _topPriority = v);
      }),
    );
  }

  Widget _buildDreamSchoolPage() {
    return _buildSurveyPage(
      question: 'Dream school?',
      child: Column(
        children: [
          TextField(
            controller: _dreamSchoolController,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'e.g., USC, UCLA, Oregon...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Optional — you can always add this later',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTonePage() {
    final options = {
      'coach': 'Like a coach — direct, push me hard',
      'buddy': 'Like a teammate — supportive, casual',
      'allBusiness': 'All business — just the facts',
    };

    return _buildSurveyPage(
      question: 'How should your assistant talk to you?',
      child: _buildSingleSelect(options, _agentTone, (v) {
        setState(() => _agentTone = v);
      }),
    );
  }

  Widget _buildSingleSelect(
    Map<String, String> options,
    String? selected,
    ValueChanged<String> onSelect,
  ) {
    return Column(
      children: options.entries.map((entry) {
        final isSelected = selected == entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => onSelect(entry.key),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? DiabloColors.red.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? DiabloColors.red : Colors.white24,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? DiabloColors.gold : Colors.white54,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
