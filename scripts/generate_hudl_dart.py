#!/usr/bin/env python3
"""
Generate Dart source file from parsed Hudl game data.
Creates lib/data/hudl_game_data.dart for AI agent training.
"""

import json
from pathlib import Path
from datetime import datetime

SCRIPT_DIR = Path(__file__).parent
INPUT = SCRIPT_DIR / "hudl_all_games.json"
OUTPUT = SCRIPT_DIR.parent / "lib" / "data" / "hudl_game_data.dart"


def dart_string(s):
    """Escape a string for Dart single-quote literal."""
    if s is None:
        return "null"
    s = str(s).replace("\\", "\\\\").replace("'", "\\'")
    return f"'{s}'"


def dart_int(v):
    if v is None:
        return "null"
    return str(int(v))


def dart_num(v):
    if v is None:
        return "null"
    if isinstance(v, float) and v == int(v):
        return str(int(v))
    return str(v)


def main():
    with open(INPUT) as f:
        data = json.load(f)

    games = data["games"]
    meta = data["meta"]
    aggregates = data["aggregates"]

    lines = []
    w = lines.append

    w("// GENERATED FILE — DO NOT EDIT")
    w(f"// Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    w(f"// Source: {meta['gamesCount']} Hudl game film exports (2023 season)")
    w(f"// Total plays: {meta['totalPlays']}")
    w("")
    w("// ignore_for_file: prefer_single_quotes, lines_longer_than_80_chars")
    w("")
    w("/// Structured play-by-play data from Hudl game film for AI agent training.")
    w("/// This data is PRIVATE to the mobile app and must never be exposed publicly.")
    w("class HudlGameData {")
    w("  HudlGameData._();")
    w("")

    # ── Meta ──
    w("  static const meta = {")
    w(f"    'season': '2023',")
    w(f"    'team': 'Mission Viejo High School',")
    w(f"    'gamesCount': {meta['gamesCount']},")
    w(f"    'totalPlays': {meta['totalPlays']},")
    w("  };")
    w("")

    # ── Aggregate stats (for quick AI lookups) ──
    w("  // ── Aggregate Statistics ─────────────────────────────────────")
    w("")

    # Top formations
    top_formations = list(aggregates["formations"].items())[:30]
    w("  /// Top offensive formations by frequency")
    w("  static const topFormations = <String, int>{")
    for name, count in top_formations:
        w(f"    {dart_string(name)}: {count},")
    w("  };")
    w("")

    # Top play calls
    top_plays = list(aggregates["playCalls"].items())[:50]
    w("  /// Top play calls by frequency")
    w("  static const topPlayCalls = <String, int>{")
    for name, count in top_plays:
        w(f"    {dart_string(name)}: {count},")
    w("  };")
    w("")

    # Defensive fronts
    top_fronts = list(aggregates["defensiveFronts"].items())[:20]
    w("  /// Defensive fronts seen (opponent defenses)")
    w("  static const defensiveFronts = <String, int>{")
    for name, count in top_fronts:
        w(f"    {dart_string(name)}: {count},")
    w("  };")
    w("")

    # Coverages
    w("  /// Defensive coverages seen")
    w("  static const coverages = <String, int>{")
    for name, count in aggregates["coverages"].items():
        w(f"    {dart_string(name)}: {count},")
    w("  };")
    w("")

    # ── Game summaries ──
    w("  // ── Game Summaries ──────────────────────────────────────────")
    w("")
    w("  static const gameSummaries = <Map<String, dynamic>>[")
    for game in games:
        gi = game["gameInfo"]
        w("    {")
        w(f"      'opponent': {dart_string(gi['opponent'])},")
        w(f"      'season': {dart_string(gi.get('season', 'unknown'))},")
        w(f"      'hudlId': {dart_string(gi.get('hudlId'))},")
        w(f"      'totalPlays': {gi['totalPlays']},")
        w(f"      'offensivePlays': {gi['offensivePlays']},")
        w(f"      'defensivePlays': {gi['defensivePlays']},")
        w(f"      'specialTeamsPlays': {gi['specialTeamsPlays']},")
        w("    },")
    w("  ];")
    w("")

    # ── Full play-by-play data per game ──
    w("  // ── Play-by-Play Data ───────────────────────────────────────")
    w("")

    # Generate plays per game as separate static lists
    # Include season in variable name to avoid collisions across years
    for game_idx, game in enumerate(games):
        gi = game["gameInfo"]
        opponent = gi["opponent"]
        season = gi.get("season", "unknown")
        safe_name = _safe_dart_name(opponent) + season
        plays = game["plays"]

        w(f"  /// {opponent} [{season}] — {len(plays)} plays")
        w(f"  static const plays{safe_name} = <Map<String, dynamic>>[")

        for play in plays:
            w("    {")
            # Write each field
            for key in [
                "playNumber", "quarter", "down", "distance", "yardLine",
                "hash", "odk", "playType", "result", "gainLoss", "series",
                "offStrength", "offFormation", "offPlay", "playDirection",
                "gap", "personnel", "motion", "motionDirection", "passZone",
                "defStrength", "defFront", "blitz", "coverage",
                "kickYards", "returnYards", "team", "oppTeam",
                "penalty", "efficiency",
            ]:
                val = play.get(key)
                if val is not None:
                    if isinstance(val, str):
                        w(f"      '{key}': {dart_string(val)},")
                    elif isinstance(val, (int, float)):
                        w(f"      '{key}': {dart_num(val)},")

            # Player data — only include fields NOT already in structured keys
            STRUCTURED_KEYS = {
                "PLAY #", "QTR", "DN", "DIST", "YARD LN", "HASH",
                "ODK", "PLAY TYPE", "RESULT", "GN/LS", "SERIES",
                "OFF STR", "OFF FORM", "OFF PLAY", "PLAY DIR",
                "GAP", "PERSONNEL", "MOTION", "MOTION DIR", "PASS ZONE",
                "DEF STR", "DEF FRONT", "BLITZ", "COVERAGE",
                "KICK YARDS", "RET YARDS", "TEAM", "OPP TEAM",
                "PENALTY", "EFF", "HOME SCORE", "AWAY SCORE",
            }
            pd = play.get("playerData")
            if pd:
                extras = {k: v for k, v in pd.items()
                         if k not in STRUCTURED_KEYS
                         and v and str(v).strip() and str(v) != "0"
                         and not k.startswith("col_")}
                if extras:
                    w(f"      'playerData': <String, dynamic>{{")
                    for pk, pv in extras.items():
                        w(f"        {dart_string(pk)}: {dart_string(pv)},")
                    w(f"      }},")

            w("    },")

        w("  ];")
        w("")

    # ── Master games list referencing all plays ──
    w("  /// All games with their play data")
    w("  static const allGames = <Map<String, dynamic>>[")
    for game in games:
        gi = game["gameInfo"]
        season = gi.get("season", "unknown")
        safe_name = _safe_dart_name(gi["opponent"]) + season
        w("    {")
        w(f"      'opponent': {dart_string(gi['opponent'])},")
        w(f"      'season': {dart_string(season)},")
        w(f"      'hudlId': {dart_string(gi.get('hudlId'))},")
        w(f"      'totalPlays': {gi['totalPlays']},")
        w(f"      'playsKey': 'plays{safe_name}',")
        w("    },")
    w("  ];")
    w("")

    # ── Helper to get plays by opponent + season ──
    w("  /// Get plays for a specific game by Hudl ID")
    w("  static List<Map<String, dynamic>> getPlaysForGame(String hudlId) {")
    w("    switch (hudlId) {")
    for game in games:
        gi = game["gameInfo"]
        season = gi.get("season", "unknown")
        safe_name = _safe_dart_name(gi["opponent"]) + season
        w(f"      case {dart_string(gi.get('hudlId', ''))}:")
        w(f"        return plays{safe_name};")
    w("      default:")
    w("        return [];")
    w("    }")
    w("  }")
    w("")

    # ── Utility: get all offensive plays across all games ──
    w("  /// All offensive plays across all games (for AI analysis)")
    w("  static List<Map<String, dynamic>> get allOffensivePlays {")
    w("    final plays = <Map<String, dynamic>>[];")
    for game in games:
        gi = game["gameInfo"]
        season = gi.get("season", "unknown")
        safe_name = _safe_dart_name(gi["opponent"]) + season
        w(f"    plays.addAll(plays{safe_name}.where((p) => p['odk'] == 'O'));")
    w("    return plays;")
    w("  }")
    w("")

    # ── Utility: get all defensive plays ──
    w("  /// All defensive plays across all games (for AI analysis)")
    w("  static List<Map<String, dynamic>> get allDefensivePlays {")
    w("    final plays = <Map<String, dynamic>>[];")
    for game in games:
        gi = game["gameInfo"]
        season = gi.get("season", "unknown")
        safe_name = _safe_dart_name(gi["opponent"]) + season
        w(f"    plays.addAll(plays{safe_name}.where((p) => p['odk'] == 'D'));")
    w("    return plays;")
    w("  }")
    w("")

    w("}")  # end class

    # Write output
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT, 'w') as f:
        f.write('\n'.join(lines) + '\n')

    file_size = OUTPUT.stat().st_size
    print(f"Generated: {OUTPUT}")
    print(f"Size: {file_size / 1024:.0f} KB ({file_size / 1024 / 1024:.1f} MB)")
    print(f"Lines: {len(lines)}")


def _safe_dart_name(opponent):
    """Convert opponent name to safe Dart identifier."""
    # Remove special chars, convert to PascalCase
    parts = opponent.replace("…", "").replace(".", "").replace("-", " ").split()
    return "".join(p.capitalize() for p in parts if p)


if __name__ == "__main__":
    main()
