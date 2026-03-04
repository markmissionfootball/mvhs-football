import '../models/hudl_film.dart';
import '../models/user.dart';
import '../models/player.dart';
import '../models/game.dart';
import '../models/announcement.dart';
import '../models/coach.dart';
import '../models/max_entry.dart';
import '../models/workout.dart';
import '../models/calendar_event.dart';

/// Static demo data used for offline/development mode and as fallback
/// when Firebase is not initialized or the user is not authenticated.
class DemoData {
  DemoData._();

  // ── User ──────────────────────────────────────────────────────────

  static final AppUser user = AppUser(
    uid: 'demo_user',
    username: 'mcoleman',
    email: 'mcoleman@mvhs.example.com',
    role: UserRole.player,
    linkedPlayerId: 'demo_player',
    displayName: 'Marcus Coleman',
    mustChangePassword: false,
    mfaComplete: true,
    onboardingSurveyComplete: true,
    createdAt: DateTime(2025, 1, 15),
  );

  static final AppUser masterAdmin = AppUser(
    uid: 'master_admin',
    username: 'mark',
    email: 'mark@missionfootball.com',
    role: UserRole.admin,
    displayName: 'Mark Coleman',
    mustChangePassword: false,
    mfaComplete: true,
    onboardingSurveyComplete: true,
    createdAt: DateTime(2025, 1, 1),
  );

  // ── Player ────────────────────────────────────────────────────────

  static final Player player = Player(
    id: 'demo_player',
    firstName: 'Marcus',
    lastName: 'Coleman',
    grade: 11,
    position: 'QB',
    jerseyNumber: 7,
    team: 'varsity',
    height: "6'1\"",
    weight: 185,
    athleticClearance: 'cleared',
    updatedAt: DateTime(2025, 8, 1),
  );

  // ── Roster (15 demo players) ────────────────────────────────────

  static final List<Player> roster = [
    Player(
      id: 'demo_player',
      firstName: 'Marcus',
      lastName: 'Coleman',
      grade: 11,
      position: 'QB',
      jerseyNumber: 7,
      team: 'varsity',
      height: "6'1\"",
      weight: 185,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
    Player(
      id: 'demo_player_02',
      firstName: 'Jake',
      lastName: 'Rodriguez',
      grade: 12,
      position: 'RB',
      jerseyNumber: 22,
      team: 'varsity',
      height: "5'10\"",
      weight: 195,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
    Player(
      id: 'demo_player_03',
      firstName: 'Tyler',
      lastName: 'Chen',
      grade: 12,
      position: 'WR',
      jerseyNumber: 11,
      team: 'varsity',
      height: "6'0\"",
      weight: 175,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
    Player(
      id: 'demo_player_04',
      firstName: 'Devon',
      lastName: 'Williams',
      grade: 12,
      position: 'OLB',
      jerseyNumber: 44,
      team: 'varsity',
      height: "6'2\"",
      weight: 215,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
    Player(
      id: 'demo_player_05',
      firstName: 'Chris',
      lastName: 'Martinez',
      grade: 11,
      position: 'DL',
      jerseyNumber: 55,
      team: 'varsity',
      height: "6'3\"",
      weight: 250,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
    Player(
      id: 'demo_player_06',
      firstName: 'Aiden',
      lastName: 'Patel',
      grade: 11,
      position: 'CB',
      jerseyNumber: 2,
      team: 'varsity',
      height: "5'11\"",
      weight: 170,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
    Player(
      id: 'demo_player_07',
      firstName: 'Brandon',
      lastName: 'Lee',
      grade: 12,
      position: 'OL',
      jerseyNumber: 75,
      team: 'varsity',
      height: "6'4\"",
      weight: 285,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
    Player(
      id: 'demo_player_08',
      firstName: 'Ryan',
      lastName: 'Nguyen',
      grade: 10,
      position: 'S',
      jerseyNumber: 14,
      team: 'varsity',
      height: "5'11\"",
      weight: 180,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
    Player(
      id: 'demo_player_09',
      firstName: 'Jack',
      lastName: 'Taylor',
      grade: 11,
      position: 'TE',
      jerseyNumber: 88,
      team: 'varsity',
      height: "6'3\"",
      weight: 225,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
    Player(
      id: 'demo_player_10',
      firstName: 'Ethan',
      lastName: 'Garcia',
      grade: 10,
      position: 'QB',
      jerseyNumber: 12,
      team: 'jv',
      height: "5'11\"",
      weight: 175,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
    Player(
      id: 'demo_player_11',
      firstName: 'Noah',
      lastName: 'Kim',
      grade: 10,
      position: 'WR',
      jerseyNumber: 5,
      team: 'jv',
      height: "5'9\"",
      weight: 160,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
    Player(
      id: 'demo_player_12',
      firstName: 'Liam',
      lastName: 'Davis',
      grade: 10,
      position: 'LB',
      jerseyNumber: 33,
      team: 'jv',
      height: "6'0\"",
      weight: 200,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
    Player(
      id: 'demo_player_13',
      firstName: 'Mason',
      lastName: 'Brown',
      grade: 9,
      position: 'RB',
      jerseyNumber: 21,
      team: 'freshman',
      height: "5'8\"",
      weight: 165,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
    Player(
      id: 'demo_player_14',
      firstName: 'Lucas',
      lastName: 'Wilson',
      grade: 9,
      position: 'QB',
      jerseyNumber: 3,
      team: 'freshman',
      height: "5'10\"",
      weight: 160,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
    Player(
      id: 'demo_player_15',
      firstName: 'Daniel',
      lastName: 'Anderson',
      grade: 9,
      position: 'DL',
      jerseyNumber: 72,
      team: 'freshman',
      height: "6'1\"",
      weight: 220,
      athleticClearance: 'cleared',
      updatedAt: DateTime(2025, 8, 1),
    ),
  ];

  // ── Games (2025 Varsity Season) ───────────────────────────────────

  static final List<Game> games = [
    // Week 0 - Scrimmage (played)
    Game(
      id: 'game_001',
      season: '2025',
      week: 0,
      date: DateTime(2025, 8, 22),
      opponent: 'Mission Viejo JV',
      location: 'home',
      time: '5:00 PM',
      level: 'varsity',
      result: const GameResult(mvScore: 28, oppScore: 7, win: true),
      notes: 'Scrimmage',
    ),
    // Week 1 (played)
    Game(
      id: 'game_002',
      season: '2025',
      week: 1,
      date: DateTime(2025, 8, 29),
      opponent: 'El Toro Chargers',
      location: 'away',
      time: '7:00 PM',
      level: 'varsity',
      result: const GameResult(mvScore: 35, oppScore: 14, win: true),
    ),
    // Week 2 (played)
    Game(
      id: 'game_003',
      season: '2025',
      week: 2,
      date: DateTime(2025, 9, 5),
      opponent: 'Tesoro Titans',
      location: 'home',
      time: '7:00 PM',
      level: 'varsity',
      result: const GameResult(mvScore: 21, oppScore: 24, win: false),
    ),
    // Week 3 (played)
    Game(
      id: 'game_004',
      season: '2025',
      week: 3,
      date: DateTime(2025, 9, 12),
      opponent: 'Dana Hills Dolphins',
      location: 'away',
      time: '7:00 PM',
      level: 'varsity',
      result: const GameResult(mvScore: 31, oppScore: 17, win: true),
    ),
    // Week 4 (played)
    Game(
      id: 'game_005',
      season: '2025',
      week: 4,
      date: DateTime(2025, 9, 19),
      opponent: 'San Clemente Tritons',
      location: 'home',
      time: '7:00 PM',
      level: 'varsity',
      result: const GameResult(mvScore: 14, oppScore: 21, win: false),
    ),
    // Week 5 (played)
    Game(
      id: 'game_006',
      season: '2025',
      week: 5,
      date: DateTime(2025, 9, 26),
      opponent: 'San Juan Hills Stallions',
      location: 'away',
      time: '7:00 PM',
      level: 'varsity',
      result: const GameResult(mvScore: 42, oppScore: 28, win: true),
    ),
    // Week 6 (played)
    Game(
      id: 'game_007',
      season: '2025',
      week: 6,
      date: DateTime(2025, 10, 3),
      opponent: 'Capistrano Valley Cougars',
      location: 'home',
      time: '7:00 PM',
      level: 'varsity',
      result: const GameResult(mvScore: 38, oppScore: 10, win: true),
    ),
    // Week 7 (upcoming)
    Game(
      id: 'game_008',
      season: '2025',
      week: 7,
      date: DateTime(2025, 10, 10),
      opponent: 'Laguna Hills Hawks',
      location: 'away',
      time: '7:00 PM',
      level: 'varsity',
    ),
    // Week 8 (upcoming)
    Game(
      id: 'game_009',
      season: '2025',
      week: 8,
      date: DateTime(2025, 10, 17),
      opponent: 'Aliso Niguel Wolverines',
      location: 'home',
      time: '7:00 PM',
      level: 'varsity',
    ),
    // Week 9 (upcoming)
    Game(
      id: 'game_010',
      season: '2025',
      week: 9,
      date: DateTime(2025, 10, 24),
      opponent: 'Trabuco Hills Mustangs',
      location: 'away',
      time: '7:00 PM',
      level: 'varsity',
    ),
  ];

  // ── Announcements ─────────────────────────────────────────────────

  static final List<Announcement> announcements = [
    Announcement(
      id: 'ann_001',
      title: 'Spring Ball Dates Announced',
      body:
          'Spring ball will run from March 10 through April 18. '
          'Practice is Monday through Thursday, 3:30-5:30 PM. '
          'Full pads start Week 2. See Coach Rivera for details.',
      author: 'Coach Rivera',
      priority: 'high',
      createdAt: DateTime(2025, 2, 20),
    ),
    Announcement(
      id: 'ann_002',
      title: 'Summer Conditioning Schedule',
      body:
          'Summer conditioning begins June 9. Sessions run 7:00-9:00 AM '
          'Monday through Friday. Bring cleats, a water bottle, and a great '
          'attitude. Attendance is tracked and expected.',
      author: 'Coach Thompson',
      createdAt: DateTime(2025, 2, 25),
    ),
    Announcement(
      id: 'ann_003',
      title: 'Team Photo Day - March 15',
      body:
          'Team and individual photos will be taken on Saturday, March 15 '
          'at 9:00 AM on the main field. Wear full home jersey. '
          'Order forms will be sent home next week.',
      author: 'Coach Rivera',
      createdAt: DateTime(2025, 3, 1),
    ),
  ];

  // ── Coaches ───────────────────────────────────────────────────────

  static const List<Coach> coaches = [
    Coach(
      id: 'coach_001',
      firstName: 'David',
      lastName: 'Rivera',
      title: 'Head Coach',
      positionGroup: 'Program',
      email: 'drivera@mvhs.example.com',
      phone: '(949) 555-0101',
    ),
    Coach(
      id: 'coach_002',
      firstName: 'Mike',
      lastName: 'Thompson',
      title: 'Offensive Coordinator',
      positionGroup: 'Offense',
      email: 'mthompson@mvhs.example.com',
    ),
    Coach(
      id: 'coach_003',
      firstName: 'James',
      lastName: 'Washington',
      title: 'Defensive Coordinator',
      positionGroup: 'Defense',
      email: 'jwashington@mvhs.example.com',
    ),
    Coach(
      id: 'coach_004',
      firstName: 'Carlos',
      lastName: 'Mendez',
      title: 'Offensive Line Coach',
      positionGroup: 'OL',
      email: 'cmendez@mvhs.example.com',
    ),
    Coach(
      id: 'coach_005',
      firstName: 'Brian',
      lastName: 'Park',
      title: 'Defensive Backs Coach',
      positionGroup: 'DB',
      email: 'bpark@mvhs.example.com',
    ),
  ];

  // ── Max Entries (progression over time for HS QB) ─────────────────

  static final List<MaxEntry> maxEntries = [
    // Fall baseline
    MaxEntry(
      date: DateTime(2024, 8, 15),
      type: 'Fall Baseline',
      clean: 155,
      squat: 255,
      bench: 175,
      incline: 155,
      total: 740,
      bodyWeight: 178,
    ),
    // Winter test
    MaxEntry(
      date: DateTime(2025, 1, 10),
      type: 'Winter Test',
      clean: 170,
      squat: 275,
      bench: 190,
      incline: 165,
      total: 800,
      bodyWeight: 182,
    ),
    // Spring test
    MaxEntry(
      date: DateTime(2025, 3, 1),
      type: 'Spring Test',
      clean: 180,
      squat: 295,
      bench: 200,
      incline: 175,
      total: 850,
      bodyWeight: 185,
    ),
  ];

  // ── Workout Program ───────────────────────────────────────────────

  static const WorkoutProgram workout = WorkoutProgram(
    id: 'workout_spring_p2',
    phaseName: 'Spring Phase 2',
    exercises: [
      Exercise(
        name: 'Back Squat',
        sets: 4,
        reps: '5',
        percentOfMax: 0.80,
        liftReference: 'squat',
      ),
      Exercise(
        name: 'Bench Press',
        sets: 4,
        reps: '5',
        percentOfMax: 0.80,
        liftReference: 'bench',
      ),
      Exercise(
        name: 'Power Clean',
        sets: 3,
        reps: '3',
        percentOfMax: 0.75,
        liftReference: 'clean',
      ),
      Exercise(
        name: 'Incline DB Press',
        sets: 3,
        reps: '8',
        notes: 'Use dumbbells, controlled tempo',
      ),
      Exercise(
        name: 'Romanian Deadlift',
        sets: 3,
        reps: '8',
        notes: 'Hamstring focus, slow eccentric',
      ),
      Exercise(
        name: 'Pull-Ups',
        sets: 3,
        reps: 'Max',
        notes: 'Weighted if bodyweight > 12 reps',
      ),
    ],
  );

  // ── Calendar Events ───────────────────────────────────────────────

  static final List<CalendarEvent> calendarEvents = [
    CalendarEvent(
      id: 'cal_001',
      date: DateTime(2025, 3, 10),
      title: 'Spring Ball Begins',
      description: 'First day of spring football practice. Helmets and shorts.',
      phase: 'Spring Ball',
      timeRange: '3:30 PM - 5:30 PM',
      level: 'all',
    ),
    CalendarEvent(
      id: 'cal_002',
      date: DateTime(2025, 3, 15),
      title: 'Team Photo Day',
      description: 'Team and individual photos on main field. Full home jersey.',
      phase: 'Spring Ball',
      timeRange: '9:00 AM - 12:00 PM',
      level: 'all',
    ),
    CalendarEvent(
      id: 'cal_003',
      date: DateTime(2025, 3, 22),
      title: 'Spring Max Testing',
      description: 'Full max testing day - squat, bench, clean, incline.',
      phase: 'Spring Ball',
      timeRange: '3:30 PM - 5:30 PM',
      level: 'all',
    ),
    CalendarEvent(
      id: 'cal_004',
      date: DateTime(2025, 4, 5),
      title: 'Parent Meeting',
      description:
          'Mandatory parent meeting in the MVHS auditorium. Season expectations, '
          'fundraising, and summer schedule.',
      phase: 'Spring Ball',
      timeRange: '6:00 PM - 7:30 PM',
      level: 'all',
    ),
    CalendarEvent(
      id: 'cal_005',
      date: DateTime(2025, 4, 18),
      title: 'Spring Game',
      description:
          'Intra-squad spring game. Offense vs defense. Family and friends welcome.',
      phase: 'Spring Ball',
      timeRange: '6:00 PM - 8:00 PM',
      allDay: false,
      level: 'varsity',
    ),
  ];


  // ── Hudl Game Films ─────────────────────────────────────────────

  static final List<HudlFilm> hudlFilms = [
    HudlFilm(
      id: 'film_001',
      gameId: 'game_002',
      opponent: 'El Toro Chargers',
      gameDate: DateTime(2025, 8, 29),
      season: '2025',
      level: 'varsity',
      hudlVideoUrl: 'https://www.hudl.com/video/3/12345/abc001',
      hudlVideoId: 'abc001',
      totalPlays: 68,
      importedBy: 'coach_001',
      importedAt: DateTime(2025, 8, 30, 10, 15),
      status: FilmStatus.ready,
      summary: const FilmSummary(
        overview:
            'Dominant win over El Toro. Offense clicked on all cylinders with a '
            'balanced attack. Defense held opponents to under 200 total yards.',
        keyTakeaways: [
          'Run game averaged 5.8 YPC behind strong O-line play',
          'Secondary had 3 pass breakups and 1 interception',
          'Red zone efficiency was 4/5 (80%)',
        ],
        teamGrades: {
          'offense': 88.0,
          'defense': 85.5,
          'specialTeams': 76.0,
        },
      ),
    ),
    HudlFilm(
      id: 'film_002',
      gameId: 'game_003',
      opponent: 'Tesoro Titans',
      gameDate: DateTime(2025, 9, 5),
      season: '2025',
      level: 'varsity',
      hudlVideoUrl: 'https://www.hudl.com/video/3/12345/abc002',
      hudlVideoId: 'abc002',
      totalPlays: 72,
      importedBy: 'coach_001',
      importedAt: DateTime(2025, 9, 6, 9, 30),
      status: FilmStatus.ready,
      summary: const FilmSummary(
        overview:
            'Tough loss to Tesoro in a back-and-forth game. Two costly turnovers '
            'in the second half swung momentum. Defense played well but tired late.',
        keyTakeaways: [
          'Turnovers in Q3 led to 10 unanswered points',
          'Pass protection broke down on 3rd downs (3 sacks allowed)',
          'Need to clean up pre-snap penalties (4 false starts)',
        ],
        teamGrades: {
          'offense': 62.0,
          'defense': 74.5,
          'specialTeams': 70.0,
        },
      ),
    ),
    HudlFilm(
      id: 'film_003',
      gameId: 'game_004',
      opponent: 'Dana Hills Dolphins',
      gameDate: DateTime(2025, 9, 12),
      season: '2025',
      level: 'varsity',
      hudlVideoUrl: 'https://www.hudl.com/video/3/12345/abc003',
      hudlVideoId: 'abc003',
      totalPlays: 65,
      importedBy: 'coach_001',
      importedAt: DateTime(2025, 9, 13, 11, 0),
      status: FilmStatus.ready,
      summary: const FilmSummary(
        overview:
            'Bounce-back road win against Dana Hills. Strong defensive effort '
            'forced 3 turnovers. Offense found rhythm in the second half.',
        keyTakeaways: [
          'Defense forced 3 turnovers including a pick-six',
          'Second-half adjustments opened up the play-action game',
          'Rushing attack controlled clock in the 4th quarter',
        ],
        teamGrades: {
          'offense': 80.0,
          'defense': 90.0,
          'specialTeams': 82.5,
        },
      ),
    ),
  ];

  // ── Hudl Plays ────────────────────────────────────────────────────

  static final List<HudlPlay> hudlPlays = [
    // Film 1 – El Toro Chargers
    const HudlPlay(
      id: 'play_001',
      filmId: 'film_001',
      playNumber: 12,
      quarter: 1,
      downAndDistance: '1st & 10',
      yardLine: 35,
      formation: 'Shotgun Trips Right',
      playType: 'pass',
      playCall: 'Mesh Concept',
      result: 'Complete - 22 yards',
      yardsGained: 22,
      isTouchdown: false,
      taggedPlayerIds: ['demo_player', 'demo_player_02'],
      coachNote: 'Great read by QB, hit the crosser in stride.',
    ),
    const HudlPlay(
      id: 'play_002',
      filmId: 'film_001',
      playNumber: 34,
      quarter: 3,
      downAndDistance: '2nd & 5',
      yardLine: 12,
      formation: 'I-Formation Strong',
      playType: 'run',
      playCall: 'Power Right',
      result: 'Rush - 12 yards, TD',
      yardsGained: 12,
      isTouchdown: true,
      taggedPlayerIds: ['demo_player_03', 'demo_player_04'],
      coachNote: 'Pulling guard sealed the edge perfectly.',
    ),
    // Film 2 – Tesoro Titans
    const HudlPlay(
      id: 'play_003',
      filmId: 'film_002',
      playNumber: 8,
      quarter: 1,
      downAndDistance: '3rd & 7',
      yardLine: 42,
      formation: 'Shotgun Empty',
      playType: 'pass',
      playCall: 'Four Verticals',
      result: 'Complete - 38 yards, TD',
      yardsGained: 38,
      isTouchdown: true,
      taggedPlayerIds: ['demo_player', 'demo_player_02'],
      coachNote: 'Perfect deep ball. Safety bit on the play-action fake.',
    ),
    const HudlPlay(
      id: 'play_004',
      filmId: 'film_002',
      playNumber: 45,
      quarter: 3,
      downAndDistance: '2nd & 3',
      yardLine: 28,
      formation: 'Shotgun Doubles',
      playType: 'pass',
      playCall: 'Slant-Flat Combo',
      result: 'Intercepted',
      yardsGained: 0,
      isTurnover: true,
      taggedPlayerIds: ['demo_player'],
      coachNote: 'QB didn\'t see the LB dropping into the passing lane. Blitz read issue.',
    ),
    // Film 3 – Dana Hills Dolphins
    const HudlPlay(
      id: 'play_005',
      filmId: 'film_003',
      playNumber: 18,
      quarter: 2,
      downAndDistance: '1st & 10',
      yardLine: 50,
      formation: 'Pistol Wing Right',
      playType: 'run',
      playCall: 'Inside Zone Left',
      result: 'Rush - 15 yards',
      yardsGained: 15,
      taggedPlayerIds: ['demo_player_03', 'demo_player_05'],
      coachNote: 'RB hit the cutback lane hard. Great downfield block by WR.',
    ),
    const HudlPlay(
      id: 'play_006',
      filmId: 'film_003',
      playNumber: 52,
      quarter: 4,
      downAndDistance: '3rd & 8',
      yardLine: 25,
      formation: 'Shotgun Trips Left',
      playType: 'pass',
      playCall: 'Smash Concept',
      result: 'Complete - 25 yards, TD',
      yardsGained: 25,
      isTouchdown: true,
      taggedPlayerIds: ['demo_player', 'demo_player_02'],
      coachNote: 'Corner route was wide open. QB put it on the money.',
    ),
  ];

  // ── Hudl Player Stats ─────────────────────────────────────────────

  static final List<HudlPlayerStats> hudlPlayerStats = [
    // Marcus Coleman – QB – vs El Toro
    const HudlPlayerStats(
      id: 'pstat_001',
      filmId: 'film_001',
      playerId: 'demo_player',
      playerName: 'Marcus Coleman',
      position: 'QB',
      stats: {
        'completions': 18,
        'attempts': 25,
        'passingYards': 245,
        'passingTDs': 3,
        'interceptions': 0,
        'completionPct': 72.0,
        'yardsPerAttempt': 9.8,
        'rushAttempts': 4,
        'rushYards': 28,
        'qbRating': 142.5,
        'sacksTaken': 1,
      },
      overallGrade: 88.5,
      gradeLabel: 'Elite',
      strengths: [
        'Pocket awareness — consistently stepped up to avoid pressure',
        'Deep ball accuracy — 4/5 on throws over 20 yards',
        'Pre-snap reads — checked out of 3 bad plays at the line',
      ],
      areasToImprove: [
        'Tendency to lock onto first read on quick game',
        'Could improve ball placement on out-breaking routes',
      ],
      highlightPlays: [12, 23, 34, 48],
      aiAnalysis:
          'Marcus was in full command of the offense against El Toro. His '
          'pocket presence was outstanding, sliding away from pressure on '
          'multiple occasions to extend plays. The deep ball was his biggest '
          'weapon, connecting on 4 of 5 attempts over 20 yards. He also made '
          'three audible changes at the line that resulted in positive plays. '
          'Minor areas to work on include going through his full progression '
          'on quick-game concepts and tightening ball placement on out routes.',
    ),
    // Marcus Coleman – QB – vs Tesoro
    const HudlPlayerStats(
      id: 'pstat_002',
      filmId: 'film_002',
      playerId: 'demo_player',
      playerName: 'Marcus Coleman',
      position: 'QB',
      stats: {
        'completions': 15,
        'attempts': 28,
        'passingYards': 180,
        'passingTDs': 1,
        'interceptions': 2,
        'completionPct': 53.6,
        'yardsPerAttempt': 6.4,
        'rushAttempts': 6,
        'rushYards': 18,
        'qbRating': 58.3,
        'sacksTaken': 3,
      },
      overallGrade: 62.0,
      gradeLabel: 'Below Average',
      strengths: [
        'Showed toughness taking hits and staying in the pocket',
        'First-quarter TD drive was well-orchestrated (8 plays, 75 yards)',
      ],
      areasToImprove: [
        'Reading the blitz — failed to identify overload blitz on 3 sacks',
        'Ball security — both INTs came from forcing throws into coverage',
        'Need quicker release on 3-step drops to beat pressure',
        'Check-down awareness — missed open RB in the flat multiple times',
      ],
      highlightPlays: [8],
      aiAnalysis:
          'A tough night for Marcus against a blitz-heavy Tesoro defense. He '
          'struggled to identify pre-snap pressure looks, resulting in 3 sacks '
          'and multiple rushed throws. Both interceptions came when he forced '
          'the ball into tight windows under duress instead of taking the '
          'check-down. The first-quarter TD drive showed what he\'s capable of '
          'when given time, but the second half was a different story as Tesoro '
          'dialed up the pressure. Key focus areas this week: blitz recognition '
          'drills, quick-release mechanics, and check-down progression reads.',
    ),
  ];
}
