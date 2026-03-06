#!/usr/bin/env python3
"""
Generate Dart demo data for Hudl films, plays, and stats
based on real parsed game data.
"""

import json
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
INPUT = SCRIPT_DIR / "hudl_all_games.json"

with open(INPUT) as f:
    data = json.load(f)

# Skip the Tactical export (no tags) — Mission Viejo High
games = [g for g in data["games"] if g["gameInfo"]["offensivePlays"] > 0]

def dart_str(s):
    if s is None: return "''"
    return f"'{str(s).replace(chr(39), chr(92)+chr(39))}'"

# ── Generate hudlFilms ──
print("  // ── Hudl Game Films (14 real games from 2023 season) ─────────")
print("")
print("  static final List<HudlFilm> hudlFilms = [")

# Game dates approximate for the 2023 season (Aug-Nov)
game_dates = [
    ("2023, 8, 18", "El Camino High School"),   # Week 0
    ("2023, 8, 25", "Citrus Valley"),            # Week 1
    ("2023, 9, 1",  "Highland"),                 # Week 2
    ("2023, 9, 8",  "Long Beach Poly"),          # Week 3
    ("2023, 9, 15", "Kamehameha"),               # Week 4 (Hawaii trip)
    ("2023, 9, 22", "Granite Hills"),            # Week 5
    ("2023, 9, 29", "Los Alamitos"),             # Week 6
    ("2023, 10, 6", "De La Salle"),              # Week 7
    ("2023, 10, 13", "Palos Verdes"),            # Week 8
    ("2023, 10, 20", "Tesoro"),                  # League Week 1
    ("2023, 10, 27", "San Clemente"),            # League Week 2
    ("2023, 11, 3", "Capo Valley"),              # League Week 3
    ("2023, 11, 10", "Oaks Christian"),           # Playoffs R1
    ("2023, 11, 17", "Servite"),                  # Playoffs R2
]

# Sort games to match date order
opponent_to_game = {g["gameInfo"]["opponent"]: g for g in games}

for i, (date_str, opp_name) in enumerate(game_dates, 1):
    game = opponent_to_game.get(opp_name)
    if not game:
        # Try partial match
        for key in opponent_to_game:
            if opp_name in key:
                game = opponent_to_game[key]
                break
    if not game:
        continue

    gi = game["gameInfo"]
    film_id = f"film_{i:03d}"
    hudl_id = gi.get("hudlId", "")
    total = gi["totalPlays"]
    off = gi["offensivePlays"]
    dfn = gi["defensivePlays"]

    # Compute rough grades from the data
    off_plays = [p for p in game["plays"] if p.get("odk") == "O"]
    total_yards = sum(p.get("gainLoss", 0) for p in off_plays if p.get("gainLoss"))
    completions = sum(1 for p in off_plays if p.get("result") == "Complete")
    pass_plays = sum(1 for p in off_plays if p.get("playType") == "Pass")
    run_plays = sum(1 for p in off_plays if p.get("playType") == "Run")
    rush_yards = sum(p.get("gainLoss", 0) for p in off_plays if p.get("playType") == "Run" and p.get("gainLoss"))
    tds = sum(1 for p in off_plays if p.get("result") and "TD" in str(p.get("result", "")))
    turnovers = sum(1 for p in off_plays if p.get("result") and ("INT" in str(p.get("result", "")).upper() or "Fumble" in str(p.get("result", ""))))

    ypc = rush_yards / max(1, run_plays)
    comp_pct = completions / max(1, pass_plays) * 100

    # Generate summary text
    overview_parts = []
    if total_yards > 300:
        overview_parts.append(f"Explosive offensive performance against {opp_name}")
    elif total_yards > 200:
        overview_parts.append(f"Solid offensive output against {opp_name}")
    else:
        overview_parts.append(f"Gritty game against {opp_name}")

    overview_parts.append(f"with {total_yards} total yards on {off} offensive snaps.")

    if ypc > 5:
        overview_parts.append(f"Ground game averaged {ypc:.1f} YPC.")
    if comp_pct > 65:
        overview_parts.append(f"Passing attack was efficient at {comp_pct:.0f}% completion rate.")

    overview = " ".join(overview_parts)

    takeaways = []
    if ypc > 5:
        takeaways.append(f"Run game averaged {ypc:.1f} yards per carry on {run_plays} attempts")
    if comp_pct > 60:
        takeaways.append(f"Passing was {completions}/{pass_plays} ({comp_pct:.0f}%) completions")
    if tds > 0:
        takeaways.append(f"{tds} offensive touchdowns scored")
    if turnovers > 0:
        takeaways.append(f"{turnovers} turnover(s) need to be addressed")

    # Compute grades
    off_grade = min(95, max(55, 70 + (total_yards - 200) / 20 + tds * 3 - turnovers * 5))
    def_grade = min(95, max(55, 75 + (dfn - 50) / 10))
    st_grade = 75.0

    print(f"    HudlFilm(")
    print(f"      id: '{film_id}',")
    print(f"      gameId: 'game_2023_{i:02d}',")
    print(f"      opponent: {dart_str(opp_name)},")
    print(f"      gameDate: DateTime({date_str}),")
    print(f"      season: '2023',")
    print(f"      level: 'varsity',")
    print(f"      hudlVideoUrl: 'https://www.hudl.com/video/3/{hudl_id}',")
    print(f"      hudlVideoId: '{hudl_id}',")
    print(f"      totalPlays: {total},")
    print(f"      importedBy: 'coach_001',")
    print(f"      importedAt: DateTime({date_str.split(',')[0]}, {int(date_str.split(',')[1].strip()) + (1 if int(date_str.split(',')[2].strip()) < 28 else 0)}, {min(28, int(date_str.split(',')[2].strip()) + 1)}, 10, 0),")
    print(f"      status: FilmStatus.ready,")
    print(f"      summary: const FilmSummary(")
    print(f"        overview:")

    # Split overview into lines
    words = overview.split()
    line = "            '"
    for word in words:
        if len(line) + len(word) + 1 > 78:
            print(line)
            line = "            '" + word
        else:
            if line.endswith("'"):
                line += word
            else:
                line += " " + word
    line += "',"
    print(line)

    print(f"        keyTakeaways: [")
    for t in takeaways[:3]:
        print(f"          '{t}',")
    print(f"        ],")
    print(f"        teamGrades: {{")
    print(f"          'offense': {off_grade:.1f},")
    print(f"          'defense': {def_grade:.1f},")
    print(f"          'specialTeams': {st_grade:.1f},")
    print(f"        }},")
    print(f"      ),")
    print(f"    ),")

print("  ];")
print("")

# ── Generate hudlPlays (2 sample plays per game from real data) ──
print("  // ── Hudl Plays (real plays from 2023 season breakdown data) ──")
print("")
print("  static final List<HudlPlay> hudlPlays = [")

play_id = 0
for i, (date_str, opp_name) in enumerate(game_dates, 1):
    game = opponent_to_game.get(opp_name)
    if not game:
        for key in opponent_to_game:
            if opp_name in key:
                game = opponent_to_game[key]
                break
    if not game:
        continue

    film_id = f"film_{i:03d}"
    off_plays = [p for p in game["plays"] if p.get("odk") == "O" and p.get("offPlay")]

    # Pick 2 interesting plays: one big gain, one notable
    big_plays = sorted([p for p in off_plays if p.get("gainLoss", 0) >= 10],
                       key=lambda p: -(p.get("gainLoss", 0)))

    sample_plays = big_plays[:2] if len(big_plays) >= 2 else off_plays[:2]

    if sample_plays:
        print(f"    // {opp_name}")

    for sp in sample_plays:
        play_id += 1
        pn = sp.get("playNumber", play_id)
        q = sp.get("quarter", 1)
        dn = sp.get("down", 1)
        dist = sp.get("distance", 10)
        yl = sp.get("yardLine", 50)
        form = sp.get("offFormation", "Shotgun")
        pt = "pass" if sp.get("playType") == "Pass" else "run" if sp.get("playType") == "Run" else "special_teams"
        pc = sp.get("offPlay", "Unknown")
        result = sp.get("result", "")
        yds = sp.get("gainLoss", 0)
        is_td = "TD" in str(result)
        is_to = "INT" in str(result).upper() or "Fumble" in str(result)
        is_pen = sp.get("penalty") is not None and sp.get("penalty") != ""

        # Build result string
        if pt == "pass":
            if "Complete" in result:
                result_str = f"Complete - {yds} yards" + (", TD" if is_td else "")
            elif "Incomplete" in result:
                result_str = "Incomplete"
            elif "INT" in result.upper():
                result_str = "Intercepted"
            else:
                result_str = f"{result} - {yds} yards"
        elif pt == "run":
            result_str = f"Rush - {yds} yards" + (", TD" if is_td else "")
        else:
            result_str = f"{result}"

        # Ordinal suffix
        ordinal = {1: "st", 2: "nd", 3: "rd"}.get(dn, "th")
        dd = f"{dn}{ordinal} & {dist}"

        print(f"    const HudlPlay(")
        print(f"      id: 'play_{play_id:03d}',")
        print(f"      filmId: '{film_id}',")
        print(f"      playNumber: {pn},")
        print(f"      quarter: {q},")
        print(f"      downAndDistance: '{dd}',")
        print(f"      yardLine: {abs(yl) if yl else 50},")
        print(f"      formation: {dart_str(form)},")
        print(f"      playType: '{pt}',")
        print(f"      playCall: {dart_str(pc)},")
        print(f"      result: '{result_str}',")
        print(f"      yardsGained: {yds},")
        if is_td:
            print(f"      isTouchdown: true,")
        if is_to:
            print(f"      isTurnover: true,")
        if is_pen:
            print(f"      isPenalty: true,")
            pen_detail = sp.get("penalty", "")
            if pen_detail:
                print(f"      penaltyDetail: {dart_str(pen_detail)},")
        print(f"    ),")

print("  ];")
