#!/usr/bin/env python3
"""
Extract and parse breakdown.xlsx from all Hudl game film ZIPs.
Auto-discovers all Hudl ZIPs in ~/Downloads/ across multiple seasons.
Outputs unified JSON with play-by-play data for AI agent training.
"""

import json
import os
import re
import sys
import zipfile
import tempfile
from pathlib import Path

try:
    import openpyxl
except ImportError:
    print("Installing openpyxl...")
    os.system(f"{sys.executable} -m pip install openpyxl")
    import openpyxl

DOWNLOADS = Path.home() / "Downloads"
OUTPUT_DIR = Path(__file__).parent
OUTPUT_FILE = OUTPUT_DIR / "hudl_all_games.json"


def discover_hudl_zips():
    """Auto-discover all Hudl game film ZIPs in Downloads."""
    zips = []
    seen_ids = set()
    for f in sorted(DOWNLOADS.glob("*.zip")):
        name = f.name
        # Match Hudl ZIPs by pattern: contain a (9369xxx) ID or known prefixes
        hudl_id = extract_hudl_id(name)
        if not hudl_id:
            continue
        # Skip duplicates (e.g., "(9369405) (1).zip")
        if hudl_id in seen_ids:
            print(f"  SKIP duplicate: {name} (ID {hudl_id} already seen)")
            continue
        seen_ids.add(hudl_id)
        zips.append(name)
    return zips


def extract_opponent_from_filename(filename):
    """Extract opponent name from ZIP filename."""
    name = filename.replace(".zip", "")
    # Remove Hudl ID in parentheses (including " (1)" duplicates)
    name = re.sub(r'\s*\(\d+\)(\s*\(\d+\))?\s*$', '', name)
    # Handle "2024 G1 - Kamehameha vs. Mission Viejo" format
    if re.match(r'^\d{4}\s+G\d+\s*-\s*', name):
        name = re.sub(r'^\d{4}\s+G\d+\s*-\s*', '', name)
        # "Kamehameha vs. Mission Viejo" → take first part
        name = re.split(r'\s+vs\.?\s+', name)[0]
        return name.strip()
    # Handle "MHS vs Mission Viejo (CA) 9-19-25" format
    name = re.sub(r'^MHS vs\.?\s*', '', name)
    # Standard "MVHS vs. Opponent" format
    name = re.sub(r'^MVHS vs\.?\s*', '', name)
    name = re.sub(r'^vs\.?\s*', '', name)
    # Remove suffixes
    name = re.sub(r'\s*(INTERCUT|Intercut|intercut)\s*$', '', name)
    name = re.sub(r'\s*-\s*Wide and Tight Tactical\s*$', '', name)
    # Remove date patterns like 08-18-2023, 9-19-25, 08-24-2024
    name = re.sub(r'\s*\d{1,2}-\d{1,2}-\d{2,4}\s*', ' ', name)
    # Remove state abbreviations like (CA)
    name = re.sub(r'\s*\([A-Z]{2}\)\s*', ' ', name)
    return name.strip()


def extract_hudl_id(filename):
    """Extract Hudl video ID from filename."""
    match = re.search(r'\((\d{7,})\)', filename)
    return match.group(1) if match else None


def extract_season_from_filename(filename):
    """Determine season year from filename date or Hudl ID range."""
    # Look for explicit 4-digit year in date
    match = re.search(r'(\d{1,2})-(\d{1,2})-(\d{4})', filename)
    if match:
        return match.group(3)
    # Look for 2-digit year like 9-19-25
    match = re.search(r'(\d{1,2})-(\d{1,2})-(\d{2})\b', filename)
    if match:
        yr = int(match.group(3))
        return str(2000 + yr)
    # Look for "2024 G1" prefix
    match = re.match(r'^(\d{4})\s+G\d+', filename)
    if match:
        return match.group(1)
    # Infer from Hudl ID ranges (observed pattern)
    hudl_id = extract_hudl_id(filename)
    if hudl_id:
        hid = int(hudl_id)
        if 9369456 <= hid <= 9369471:
            return "2023"
        elif 9369412 <= hid <= 9369422:
            return "2024"
        elif 9369399 <= hid <= 9369408:
            return "2025"
    return "unknown"


def parse_breakdown(xlsx_path, opponent, hudl_id, zip_filename, season):
    """Parse a single breakdown.xlsx into structured play data."""
    wb = openpyxl.load_workbook(xlsx_path, read_only=True, data_only=True)
    ws = wb.active

    rows = list(ws.iter_rows(values_only=True))
    if not rows:
        return None

    # First row is headers
    headers = [str(h).strip() if h else f"col_{i}" for i, h in enumerate(rows[0])]

    plays = []
    game_info = {
        "opponent": opponent,
        "hudlId": hudl_id,
        "season": season,
        "sourceFile": zip_filename,
        "totalPlays": 0,
        "offensivePlays": 0,
        "defensivePlays": 0,
        "specialTeamsPlays": 0,
    }

    for row_idx, row in enumerate(rows[1:], start=2):
        if not any(row):
            continue

        row_dict = {}
        for i, val in enumerate(row):
            if i < len(headers):
                key = headers[i]
                if val is not None:
                    row_dict[key] = val

        if not row_dict:
            continue

        play = {}

        # Core play info
        play["playNumber"] = _int(row_dict.get("PLAY #"))
        play["quarter"] = _int(row_dict.get("QTR"))
        play["down"] = _int(row_dict.get("DN"))
        play["distance"] = _int(row_dict.get("DIST"))
        play["yardLine"] = _num(row_dict.get("YARD LN"))
        play["hash"] = _str(row_dict.get("HASH"))

        # Play classification
        play["odk"] = _str(row_dict.get("ODK"))
        play["playType"] = _str(row_dict.get("PLAY TYPE"))
        play["result"] = _str(row_dict.get("RESULT"))
        play["gainLoss"] = _num(row_dict.get("GN/LS"))
        play["series"] = _int(row_dict.get("SERIES"))

        # Offensive scheme
        play["offStrength"] = _str(row_dict.get("OFF STR"))
        play["offFormation"] = _str(row_dict.get("OFF FORM"))
        play["offPlay"] = _str(row_dict.get("OFF PLAY"))
        play["playDirection"] = _str(row_dict.get("PLAY DIR"))
        play["gap"] = _str(row_dict.get("GAP"))
        play["personnel"] = _str(row_dict.get("PERSONNEL"))
        play["motion"] = _str(row_dict.get("MOTION"))
        play["motionDirection"] = _str(row_dict.get("MOTION DIR"))
        play["passZone"] = _str(row_dict.get("PASS ZONE"))

        # Defensive scheme
        play["defStrength"] = _str(row_dict.get("DEF STR"))
        play["defFront"] = _str(row_dict.get("DEF FRONT"))
        play["blitz"] = _str(row_dict.get("BLITZ"))
        play["coverage"] = _str(row_dict.get("COVERAGE"))

        # Special teams
        play["kickYards"] = _num(row_dict.get("KICK YARDS"))
        play["returnYards"] = _num(row_dict.get("RET YARDS"))

        # Game context
        play["team"] = _str(row_dict.get("TEAM"))
        play["oppTeam"] = _str(row_dict.get("OPP TEAM"))
        play["penalty"] = _str(row_dict.get("PENALTY"))
        play["efficiency"] = _str(row_dict.get("EFF"))

        # Score tracking
        play["homeScore"] = _int(row_dict.get("HOME SCORE"))
        play["awayScore"] = _int(row_dict.get("AWAY SCORE"))

        # Player involvement
        players_on_play = {}
        for key, val in row_dict.items():
            if val and key not in play and key not in ["col_" + str(i) for i in range(200)]:
                str_key = str(key).strip()
                str_val = str(val).strip()
                if str_val and str_val != "None":
                    players_on_play[str_key] = str_val

        if players_on_play:
            play["playerData"] = players_on_play

        # Remove None values
        play = {k: v for k, v in play.items() if v is not None}

        if play.get("playNumber") or play.get("playType"):
            plays.append(play)

            odk = play.get("odk", "")
            if odk == "O":
                game_info["offensivePlays"] += 1
            elif odk == "D":
                game_info["defensivePlays"] += 1
            elif odk == "K":
                game_info["specialTeamsPlays"] += 1

    wb.close()
    game_info["totalPlays"] = len(plays)

    return {
        "gameInfo": game_info,
        "headers": headers,
        "plays": plays,
    }


def _str(val):
    if val is None or str(val).strip() == "" or str(val).strip() == "None":
        return None
    return str(val).strip()

def _int(val):
    if val is None:
        return None
    try:
        return int(float(val))
    except (ValueError, TypeError):
        return None

def _num(val):
    if val is None:
        return None
    try:
        f = float(val)
        return int(f) if f == int(f) else f
    except (ValueError, TypeError):
        return None


def main():
    print("Discovering Hudl ZIPs in ~/Downloads/...")
    zip_files = discover_hudl_zips()
    print(f"Found {len(zip_files)} unique Hudl ZIPs\n")

    all_games = []
    total_plays = 0
    skipped = []
    seasons = {}

    for zip_name in zip_files:
        zip_path = DOWNLOADS / zip_name
        if not zip_path.exists():
            print(f"  SKIP: {zip_name} (not found)")
            skipped.append(zip_name)
            continue

        opponent = extract_opponent_from_filename(zip_name)
        hudl_id = extract_hudl_id(zip_name)
        season = extract_season_from_filename(zip_name)

        print(f"\n{'='*60}")
        print(f"Processing: {opponent} [{season}] (Hudl #{hudl_id})")
        print(f"  ZIP: {zip_name}")

        try:
            with zipfile.ZipFile(zip_path, 'r') as zf:
                breakdown_files = [f for f in zf.namelist() if f.endswith('breakdown.xlsx')]

                if not breakdown_files:
                    print(f"  SKIP: No breakdown.xlsx found in archive")
                    skipped.append(zip_name)
                    continue

                breakdown_path = breakdown_files[0]
                print(f"  Found: {breakdown_path}")

                with tempfile.NamedTemporaryFile(suffix='.xlsx', delete=False) as tmp:
                    tmp.write(zf.read(breakdown_path))
                    tmp_path = tmp.name

                try:
                    result = parse_breakdown(tmp_path, opponent, hudl_id, zip_name, season)
                    if result and result["plays"]:
                        all_games.append(result)
                        play_count = len(result["plays"])
                        total_plays += play_count
                        gi = result["gameInfo"]
                        print(f"  Plays: {play_count} (O:{gi['offensivePlays']} D:{gi['defensivePlays']} K:{gi['specialTeamsPlays']})")

                        # Track per-season counts
                        if season not in seasons:
                            seasons[season] = {"games": 0, "plays": 0}
                        seasons[season]["games"] += 1
                        seasons[season]["plays"] += play_count

                        # Sample play
                        for p in result["plays"]:
                            if p.get("offPlay"):
                                print(f"  Sample: Q{p.get('quarter','')} {p.get('down','')}{'&'+str(p.get('distance','')) if p.get('distance') else ''} "
                                      f"{p.get('offFormation','')} → {p.get('offPlay','')} → {p.get('result','')} ({p.get('gainLoss',0)}yds)")
                                break
                    else:
                        print(f"  SKIP: No play data parsed (likely untagged)")
                        skipped.append(zip_name)
                finally:
                    os.unlink(tmp_path)

        except Exception as e:
            print(f"  ERROR: {e}")
            import traceback
            traceback.print_exc()
            skipped.append(zip_name)

    # Summary
    print(f"\n{'='*60}")
    print(f"SUMMARY")
    print(f"{'='*60}")
    print(f"Games parsed: {len(all_games)}")
    print(f"Total plays:  {total_plays}")
    print(f"Skipped:      {len(skipped)}")
    if skipped:
        for s in skipped:
            print(f"  - {s}")

    print(f"\nPer-Season Breakdown:")
    for season in sorted(seasons.keys()):
        s = seasons[season]
        print(f"  {season}: {s['games']} games, {s['plays']} plays")

    # Compute aggregate stats
    all_formations = {}
    all_plays_by_name = {}
    all_def_fronts = {}
    all_coverages = {}
    all_personnel = {}

    for game in all_games:
        for play in game["plays"]:
            form = play.get("offFormation")
            if form:
                all_formations[form] = all_formations.get(form, 0) + 1
            play_name = play.get("offPlay")
            if play_name:
                all_plays_by_name[play_name] = all_plays_by_name.get(play_name, 0) + 1
            front = play.get("defFront")
            if front:
                all_def_fronts[front] = all_def_fronts.get(front, 0) + 1
            cov = play.get("coverage")
            if cov:
                all_coverages[cov] = all_coverages.get(cov, 0) + 1
            pers = play.get("personnel")
            if pers:
                all_personnel[pers] = all_personnel.get(pers, 0) + 1

    print(f"\nTop Formations:")
    for f, c in sorted(all_formations.items(), key=lambda x: -x[1])[:20]:
        print(f"  {f}: {c}")

    print(f"\nTop Play Calls:")
    for f, c in sorted(all_plays_by_name.items(), key=lambda x: -x[1])[:20]:
        print(f"  {f}: {c}")

    print(f"\nDefensive Fronts:")
    for f, c in sorted(all_def_fronts.items(), key=lambda x: -x[1])[:15]:
        print(f"  {f}: {c}")

    print(f"\nCoverages:")
    for f, c in sorted(all_coverages.items(), key=lambda x: -x[1])[:15]:
        print(f"  {f}: {c}")

    # Sort games by season then opponent for clean output
    all_games.sort(key=lambda g: (g["gameInfo"].get("season", ""), g["gameInfo"]["opponent"]))

    # Build output
    output = {
        "meta": {
            "generatedAt": "2026-03-05",
            "source": "Hudl Game Film Exports",
            "team": "Mission Viejo High School",
            "seasons": sorted(seasons.keys()),
            "gamesCount": len(all_games),
            "totalPlays": total_plays,
            "perSeason": seasons,
        },
        "aggregates": {
            "formations": dict(sorted(all_formations.items(), key=lambda x: -x[1])),
            "playCalls": dict(sorted(all_plays_by_name.items(), key=lambda x: -x[1])),
            "defensiveFronts": dict(sorted(all_def_fronts.items(), key=lambda x: -x[1])),
            "coverages": dict(sorted(all_coverages.items(), key=lambda x: -x[1])),
            "personnel": dict(sorted(all_personnel.items(), key=lambda x: -x[1])),
        },
        "games": all_games,
    }

    with open(OUTPUT_FILE, 'w') as f:
        json.dump(output, f, indent=2)

    file_size = os.path.getsize(OUTPUT_FILE)
    print(f"\nOutput: {OUTPUT_FILE}")
    print(f"Size: {file_size / 1024 / 1024:.1f} MB")
    print(f"\nDone!")


if __name__ == "__main__":
    main()
