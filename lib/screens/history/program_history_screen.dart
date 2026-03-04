import 'package:flutter/material.dart';
import '../../data/program_history.dart';
import '../../theme/diablo_colors.dart';

class ProgramHistoryScreen extends StatefulWidget {
  const ProgramHistoryScreen({super.key});

  @override
  State<ProgramHistoryScreen> createState() => _ProgramHistoryScreenState();
}

class _ProgramHistoryScreenState extends State<ProgramHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'PROGRAM HISTORY',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DiabloColors.gold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
          tabs: const [
            Tab(text: 'CATEGORY'),
            Tab(text: 'TIMELINE'),
            Tab(text: 'PLAYERS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryTab(),
          _buildTimelineTab(),
          _buildPlayersTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: BY CATEGORY
  // ---------------------------------------------------------------------------

  Widget _buildCategoryTab() {
    final records = ProgramHistory.records;
    final categories = ProgramHistory.allCategories;

    // Group records by category.
    final recordsByCategory = <String, List<ProgramRecord>>{};
    for (final r in records) {
      recordsByCategory.putIfAbsent(r.category, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // --- Records section ---
        if (records.isNotEmpty) ...[
          _sectionHeader('RECORDS', Icons.emoji_events),
          const SizedBox(height: 8),
          ...recordsByCategory.entries.map((entry) {
            return _buildRecordCategoryTile(entry.key, entry.value);
          }),
          const SizedBox(height: 16),
        ],

        // --- Honor categories ---
        _sectionHeader('HONORS & AWARDS', Icons.military_tech),
        const SizedBox(height: 8),
        ...categories.map((category) {
          final honorsForCategory =
              ProgramHistory.honors.where((h) => h.category == category).toList();
          return _buildHonorCategoryTile(category, honorsForCategory);
        }),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: DiabloColors.gold, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: DiabloColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(height: 1, color: DiabloColors.gold.withAlpha(60)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCategoryTile(String category, List<ProgramRecord> records) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        color: DiabloColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            collapsedIconColor: Colors.white54,
            iconColor: DiabloColors.gold,
            title: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: DiabloColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: DiabloColors.gold.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${records.length}',
                    style: TextStyle(
                      color: DiabloColors.gold.withAlpha(200),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              const Divider(color: Colors.white12, height: 1),
              ...records.map((r) => _buildRecordItem(r)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordItem(ProgramRecord record) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Value badge
          Container(
            constraints: const BoxConstraints(minWidth: 56),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DiabloColors.red.withAlpha(40),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: DiabloColors.red.withAlpha(80)),
            ),
            child: Text(
              record.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (record.holder != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    record.holder!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
                if (record.year != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${record.year}',
                    style: TextStyle(
                      color: DiabloColors.gold.withAlpha(180),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHonorCategoryTile(String category, List<HistoryHonor> honors) {
    // Group by year within the category.
    final byYear = <int, List<HistoryHonor>>{};
    for (final h in honors) {
      byYear.putIfAbsent(h.year, () => []).add(h);
    }
    final sortedYears = byYear.keys.toList()..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        color: DiabloColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            collapsedIconColor: Colors.white54,
            iconColor: DiabloColors.gold,
            title: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: DiabloColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: DiabloColors.gold.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${honors.length}',
                    style: TextStyle(
                      color: DiabloColors.gold.withAlpha(200),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              const Divider(color: Colors.white12, height: 1),
              ...sortedYears.map((year) {
                final yearHonors = byYear[year]!;
                return _buildYearGroupInCategory(year, yearHonors);
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearGroupInCategory(int year, List<HistoryHonor> honors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 12, bottom: 4),
          child: Text(
            '$year',
            style: TextStyle(
              color: DiabloColors.gold.withAlpha(200),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...honors.map((h) => _buildHonorItem(h, showCategory: false)),
      ],
    );
  }

  Widget _buildHonorItem(HistoryHonor honor, {bool showCategory = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: DiabloColors.gold.withAlpha(150),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  honor.playerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _buildHonorSubtitle(honor, showCategory: showCategory),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildHonorSubtitle(HistoryHonor honor, {bool showCategory = true}) {
    final parts = <String>[];
    if (showCategory) parts.add(honor.category);
    parts.add(honor.level);
    parts.add(honor.side);
    if (honor.position != null && honor.position!.isNotEmpty) {
      parts.add(honor.position!);
    }
    return parts.join('  ·  ');
  }

  // ---------------------------------------------------------------------------
  // TAB 2: BY YEAR (Timeline)
  // ---------------------------------------------------------------------------

  Widget _buildTimelineTab() {
    final years = ProgramHistory.allYears;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final yearHonors =
            ProgramHistory.honors.where((h) => h.year == year).toList();

        // Group honors by category within the year.
        final byCategory = <String, List<HistoryHonor>>{};
        for (final h in yearHonors) {
          byCategory.putIfAbsent(h.category, () => []).add(h);
        }
        final sortedCategories = byCategory.keys.toList()..sort();

        return _buildTimelineYearCard(year, byCategory, sortedCategories,
            isFirst: index == 0, isLast: index == years.length - 1);
      },
    );
  }

  Widget _buildTimelineYearCard(
    int year,
    Map<String, List<HistoryHonor>> byCategory,
    List<String> sortedCategories, {
    required bool isFirst,
    required bool isLast,
  }) {
    final totalHonors =
        byCategory.values.fold<int>(0, (sum, list) => sum + list.length);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline line + dot
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  if (!isFirst)
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: 2,
                        color: DiabloColors.gold.withAlpha(60),
                      ),
                    ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: DiabloColors.gold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: DiabloColors.gold.withAlpha(80),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: 2,
                        color: DiabloColors.gold.withAlpha(60),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Year card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: DiabloColors.darkCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: DiabloColors.gold.withAlpha(180), width: 3),
                  ),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    collapsedIconColor: Colors.white54,
                    iconColor: DiabloColors.gold,
                    title: Row(
                      children: [
                        Text(
                          '$year',
                          style: const TextStyle(
                            color: DiabloColors.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: DiabloColors.red.withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$totalHonors honor${totalHonors == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      const Divider(color: Colors.white12, height: 1),
                      ...sortedCategories.map((cat) {
                        final catHonors = byCategory[cat]!;
                        return _buildTimelineCategoryGroup(cat, catHonors);
                      }),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCategoryGroup(
      String category, List<HistoryHonor> honors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 10, bottom: 4),
          child: Text(
            category.toUpperCase(),
            style: TextStyle(
              color: DiabloColors.gold.withAlpha(180),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...honors.map((h) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: h.playerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text:
                                '  ${h.level} · ${h.side}${h.position != null && h.position!.isNotEmpty ? ' · ${h.position}' : ''}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: BY PLAYER
  // ---------------------------------------------------------------------------

  Widget _buildPlayersTab() {
    final allPlayers = ProgramHistory.allPlayers;
    final filteredPlayers = _searchQuery.isEmpty
        ? allPlayers
        : allPlayers
            .where(
                (p) => p.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    // Group by first letter for section headers.
    final grouped = <String, List<String>>{};
    for (final player in filteredPlayers) {
      final letter =
          player.isNotEmpty ? player[0].toUpperCase() : '#';
      grouped.putIfAbsent(letter, () => []).add(player);
    }
    final sortedLetters = grouped.keys.toList()..sort();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search players...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon:
                  Icon(Icons.search, color: DiabloColors.gold.withAlpha(180)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: DiabloColors.darkCard,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: DiabloColors.gold.withAlpha(120), width: 1),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),

        // Player count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${filteredPlayers.length} player${filteredPlayers.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),

        // Player list
        Expanded(
          child: filteredPlayers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, color: Colors.white24, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'No players found',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: _buildPlayerListItems(sortedLetters, grouped).length,
                  itemBuilder: (context, index) {
                    return _buildPlayerListItems(sortedLetters, grouped)[index];
                  },
                ),
        ),
      ],
    );
  }

  List<Widget> _buildPlayerListItems(
      List<String> sortedLetters, Map<String, List<String>> grouped) {
    final items = <Widget>[];
    for (final letter in sortedLetters) {
      // Letter header
      items.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: DiabloColors.darkSurface,
          child: Text(
            letter,
            style: TextStyle(
              color: DiabloColors.gold.withAlpha(200),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
      );

      for (final player in grouped[letter]!) {
        final honorCount =
            ProgramHistory.honors.where((h) => h.playerName == player).length;
        items.add(
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showPlayerBottomSheet(player),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Player avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: DiabloColors.red.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          player.isNotEmpty ? player[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: DiabloColors.red,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        player,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: DiabloColors.gold.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$honorCount',
                        style: TextStyle(
                          color: DiabloColors.gold.withAlpha(200),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right,
                        color: Colors.white24, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }
    return items;
  }

  void _showPlayerBottomSheet(String playerName) {
    final playerHonors =
        ProgramHistory.honors.where((h) => h.playerName == playerName).toList();

    // Group by year.
    final byYear = <int, List<HistoryHonor>>{};
    for (final h in playerHonors) {
      byYear.putIfAbsent(h.year, () => []).add(h);
    }
    final sortedYears = byYear.keys.toList()..sort((a, b) => b.compareTo(a));

    // Determine year range.
    final yearRange = sortedYears.isNotEmpty
        ? (sortedYears.length == 1
            ? '${sortedYears.first}'
            : '${sortedYears.last} – ${sortedYears.first}')
        : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: DiabloColors.darkCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: DiabloColors.red.withAlpha(60),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              playerName.isNotEmpty
                                  ? playerName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: DiabloColors.red,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$yearRange  ·  ${playerHonors.length} honor${playerHonors.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(color: Colors.white12, height: 1),
                  ),

                  // Honors list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: sortedYears.map((year) {
                        final yearHonors = byYear[year]!;
                        return _buildPlayerYearSection(year, yearHonors);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerYearSection(int year, List<HistoryHonor> honors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Row(
            children: [
              Text(
                '$year',
                style: const TextStyle(
                  color: DiabloColors.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  color: DiabloColors.gold.withAlpha(40),
                ),
              ),
            ],
          ),
        ),
        ...honors.map((h) => Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: DiabloColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${h.level}  ·  ${h.side}${h.position != null && h.position!.isNotEmpty ? '  ·  ${h.position}' : ''}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
