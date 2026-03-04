import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game.dart';
import '../../models/hudl_film.dart';
import '../../providers/auth_provider.dart';
import '../../providers/games_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/diablo_colors.dart';
import '../../widgets/diamond_divider.dart';

class HudlImportScreen extends ConsumerStatefulWidget {
  const HudlImportScreen({super.key});

  @override
  ConsumerState<HudlImportScreen> createState() => _HudlImportScreenState();
}

class _HudlImportScreenState extends ConsumerState<HudlImportScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Game Selection
  Game? _selectedGame;

  // Step 2: Data Entry
  final _hudlUrlController = TextEditingController();
  final _totalPlaysController = TextEditingController();
  String? _csvFileName;

  // Step 3: Processing
  bool _isImporting = false;
  bool _importComplete = false;
  String? _importError;
  String? _createdFilmId;

  @override
  void dispose() {
    _pageController.dispose();
    _hudlUrlController.dispose();
    _totalPlaysController.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    switch (_currentStep) {
      case 0:
        return _selectedGame != null;
      case 1:
        return _totalPlaysController.text.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _runImport() async {
    setState(() {
      _isImporting = true;
      _importError = null;
    });

    try {
      final uid = ref.read(currentUidProvider);
      final game = _selectedGame!;
      final totalPlays =
          int.tryParse(_totalPlaysController.text.trim()) ?? 0;

      final film = HudlFilm(
        id: '',
        gameId: game.id,
        opponent: game.opponent,
        gameDate: game.date,
        season: game.season,
        level: game.level,
        hudlVideoUrl: _hudlUrlController.text.trim().isNotEmpty
            ? _hudlUrlController.text.trim()
            : null,
        totalPlays: totalPlays,
        importedBy: uid,
        importedAt: DateTime.now(),
        status: FilmStatus.pending,
      );

      final filmId = await FirestoreService().createHudlFilm(film);

      if (filmId != null) {
        setState(() {
          _isImporting = false;
          _importComplete = true;
          _createdFilmId = filmId;
        });
      } else {
        setState(() {
          _isImporting = false;
          _importError = 'Failed to create film record. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
        _importError = e.toString();
      });
    }
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  void _onNext() {
    if (_currentStep == 0 && _canAdvance) {
      _goToStep(1);
    } else if (_currentStep == 1 && _canAdvance) {
      _goToStep(2);
      _runImport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'IMPORT FILM',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: Column(
        children: [
          // Gold progress bar
          _buildProgressBar(),

          // Step content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1GameSelection(),
                _buildStep2DataEntry(),
                _buildStep3Processing(),
              ],
            ),
          ),

          // Bottom button
          if (_currentStep < 2) _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4,
      color: DiabloColors.darkCard,
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 2 : 0),
              color: index <= _currentStep
                  ? DiabloColors.gold
                  : Colors.white.withValues(alpha: 0.1),
            ),
          );
        }),
      ),
    );
  }

  // ── Step 1: Game Selection ──

  Widget _buildStep1GameSelection() {
    final gamesAsync = ref.watch(gamesProvider(null));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepLabel(step: 1, title: 'SELECT GAME'),
          const SizedBox(height: 8),
          const Text(
            'Choose which game to import film for.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const DiamondDivider(color: DiabloColors.gold),
          const SizedBox(height: 20),

          gamesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: DiabloColors.gold),
              ),
            ),
            error: (_, __) => const Center(
              child: Text(
                'Could not load games',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            data: (games) {
              if (games.isEmpty) {
                return const Center(
                  child: Text(
                    'No games found',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: DiabloColors.darkCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Game>(
                    value: _selectedGame,
                    isExpanded: true,
                    hint: const Text(
                      'Select a game...',
                      style: TextStyle(color: Colors.white54),
                    ),
                    dropdownColor: DiabloColors.darkCard,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: DiabloColors.gold,
                    ),
                    items: games.map((game) {
                      final label =
                          'Wk ${game.week} — ${game.isHome ? "vs" : "@"} ${game.opponent}';
                      return DropdownMenuItem<Game>(
                        value: game,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (game) {
                      setState(() => _selectedGame = game);
                    },
                  ),
                ),
              );
            },
          ),

          if (_selectedGame != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DiabloColors.darkCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DiabloColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sports_football,
                    color: DiabloColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedGame!.isHome ? "vs" : "@"} ${_selectedGame!.opponent}'
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedGame!.season}  •  Week ${_selectedGame!.week}  •  ${_selectedGame!.level.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 2: Data Entry ──

  Widget _buildStep2DataEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepLabel(step: 2, title: 'FILM DATA'),
          const SizedBox(height: 8),
          const Text(
            'Enter Hudl video details and upload data.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const DiamondDivider(color: DiabloColors.gold),
          const SizedBox(height: 20),

          // Hudl Video URL
          const _FieldLabel(text: 'HUDL VIDEO URL (OPTIONAL)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _hudlUrlController,
            hint: 'https://www.hudl.com/video/...',
            icon: Icons.link,
          ),
          const SizedBox(height: 20),

          // CSV Upload placeholder
          const _FieldLabel(text: 'HUDL CSV EXPORT'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              // Placeholder for file picker integration
              setState(() => _csvFileName = 'hudl_export_week3.csv');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File picker coming soon'),
                  backgroundColor: DiabloColors.darkCard,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DiabloColors.darkCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _csvFileName != null
                      ? Colors.green.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.15),
                  style: _csvFileName != null
                      ? BorderStyle.solid
                      : BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _csvFileName != null
                        ? Icons.description
                        : Icons.upload_file,
                    color: _csvFileName != null
                        ? Colors.green
                        : Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _csvFileName ?? 'TAP TO UPLOAD CSV',
                    style: TextStyle(
                      color: _csvFileName != null
                          ? Colors.white
                          : Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: _csvFileName != null ? 0 : 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Total Plays
          const _FieldLabel(text: 'TOTAL PLAYS'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _totalPlaysController,
            hint: 'e.g. 65',
            icon: Icons.format_list_numbered,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DiabloColors.darkCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.white54, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: DiabloColors.gold),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  // ── Step 3: Processing ──

  Widget _buildStep3Processing() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isImporting) ...[
              const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  color: DiabloColors.gold,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'IMPORTING FILM...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Creating game film record',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ] else if (_importError != null) ...[
              const Icon(
                Icons.error_outline,
                color: DiabloColors.red,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'IMPORT FAILED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _importError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _runImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DiabloColors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'RETRY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ] else if (_importComplete) ...[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.green, width: 3),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'IMPORT COMPLETE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_selectedGame?.opponent ?? "Game"} film imported successfully',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(_createdFilmId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DiabloColors.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'VIEW IN FILM ROOM',
                    style: TextStyle(
                      color: DiabloColors.dark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Bottom Button ──

  Widget _buildBottomButton() {
    final isLastDataStep = _currentStep == 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DiabloColors.darkBackground,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _canAdvance ? _onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _canAdvance ? DiabloColors.gold : DiabloColors.darkCard,
              disabledBackgroundColor: DiabloColors.darkCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isLastDataStep ? 'IMPORT' : 'NEXT',
              style: TextStyle(
                color: _canAdvance ? DiabloColors.dark : Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared Widgets ──

class _StepLabel extends StatelessWidget {
  final int step;
  final String title;

  const _StepLabel({required this.step, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: DiabloColors.gold,
          ),
          alignment: Alignment.center,
          child: Text(
            step.toString(),
            style: const TextStyle(
              color: DiabloColors.dark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}
