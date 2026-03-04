import * as admin from "firebase-admin";
import Anthropic from "@anthropic-ai/sdk";

/**
 * Tool definitions for the Claude agent.
 * Each tool maps to a Firestore query that retrieves real program data.
 */
export const agentToolDefinitions: Anthropic.Tool[] = [
  {
    name: "get_todays_workout",
    description:
      "Get the player's workout for today based on the current training phase",
    input_schema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "get_max_history",
    description:
      "Get the player's lift max history over time (clean, squat, bench, incline)",
    input_schema: {
      type: "object" as const,
      properties: {
        lift: {
          type: "string",
          enum: ["clean", "squat", "bench", "incline", "all"],
          description: "Which lift to retrieve history for",
        },
      },
    },
  },
  {
    name: "get_combine_results",
    description: "Get the player's combine/athletic testing results",
    input_schema: {
      type: "object" as const,
      properties: {
        combine: {
          type: "string",
          enum: ["spring", "summer", "latest"],
          description: "Which combine to retrieve",
        },
      },
    },
  },
  {
    name: "get_schedule",
    description: "Get upcoming games with opponent, date, time, location",
    input_schema: {
      type: "object" as const,
      properties: {
        level: {
          type: "string",
          enum: ["varsity", "jv", "freshman", "all"],
        },
        upcoming_only: { type: "boolean" },
      },
    },
  },
  {
    name: "get_calendar_events",
    description:
      "Get upcoming calendar events (practices, meetings, deadlines)",
    input_schema: {
      type: "object" as const,
      properties: {
        days_ahead: {
          type: "number",
          description: "Number of days to look ahead",
        },
      },
    },
  },
  {
    name: "get_depth_chart",
    description:
      "Get the current depth chart for offense, defense, or special teams",
    input_schema: {
      type: "object" as const,
      properties: {
        side: {
          type: "string",
          enum: ["offense", "defense", "special_teams"],
        },
      },
    },
  },
  {
    name: "get_my_game_stats",
    description: "Get the player's game-by-game stats for the season",
    input_schema: {
      type: "object" as const,
      properties: {
        game: {
          type: "string",
          description: "Opponent name or 'season' for full season",
        },
      },
    },
  },
  {
    name: "get_season_awards",
    description:
      "Get player of the game and team awards for the season",
    input_schema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "get_recruiting_profile",
    description:
      "Get the player's recruiting profile, college interests, and outreach history",
    input_schema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "draft_recruiting_email",
    description:
      "Draft a recruiting outreach email to a college coach using the player's real stats",
    input_schema: {
      type: "object" as const,
      properties: {
        college: { type: "string" },
        coachName: { type: "string" },
        personalNote: {
          type: "string",
          description: "Optional personal touch from the player",
        },
      },
      required: ["college"],
    },
  },
  {
    name: "get_ncaa_eligibility_info",
    description:
      "Get NCAA eligibility requirements for a specific division",
    input_schema: {
      type: "object" as const,
      properties: {
        division: {
          type: "string",
          enum: ["D1", "D2", "D3", "NAIA"],
        },
      },
    },
  },
  {
    name: "get_announcements",
    description: "Get recent team announcements from coaches",
    input_schema: {
      type: "object" as const,
      properties: {
        count: { type: "number" },
      },
    },
  },
  {
    name: "get_team_roster",
    description: "Get the roster for a specific team level",
    input_schema: {
      type: "object" as const,
      properties: {
        level: { type: "string", enum: ["varsity", "jv", "freshman"] },
      },
    },
  },
  {
    name: "save_recruiting_interest",
    description: "Save a college to the player's recruiting interest list",
    input_schema: {
      type: "object" as const,
      properties: {
        college: { type: "string" },
        level: { type: "string" },
        notes: { type: "string" },
      },
      required: ["college"],
    },
  },
];

// ─── Tool Execution ─────────────────────────────────────────

/**
 * Executes a tool call by querying Firestore and returning the result.
 */
export async function executeTool(
  toolName: string,
  input: Record<string, unknown>,
  playerId: string
): Promise<string> {
  const db = admin.firestore();

  switch (toolName) {
    case "get_todays_workout": {
      // Find active workout program, then today's exercises
      const programSnap = await db
        .collection("workoutPrograms")
        .where("active", "==", true)
        .limit(1)
        .get();

      if (programSnap.empty) {
        return JSON.stringify({ error: "No active workout program found." });
      }

      const program = programSnap.docs[0].data();
      return JSON.stringify({
        phase: program.phase,
        weekNumber: program.weekNumber,
        exercises: program.exercises ?? [],
        notes: program.notes ?? "",
      });
    }

    case "get_max_history": {
      const lift = (input.lift as string) ?? "all";
      const maxSnap = await db
        .collection("players")
        .doc(playerId)
        .collection("maxEntries")
        .orderBy("testDate", "desc")
        .limit(10)
        .get();

      const entries = maxSnap.docs.map((doc) => {
        const d = doc.data();
        if (lift === "all") return d;
        return {
          testDate: d.testDate,
          [lift]: d[lift],
        };
      });

      return JSON.stringify({ lift, entries });
    }

    case "get_combine_results": {
      const combineType = (input.combine as string) ?? "latest";
      let query = db
        .collection("players")
        .doc(playerId)
        .collection("combineResults")
        .orderBy("testDate", "desc");

      if (combineType !== "latest") {
        query = query.where("season", "==", combineType);
      }

      const snap = await query.limit(1).get();
      if (snap.empty) {
        return JSON.stringify({ error: "No combine results found." });
      }

      return JSON.stringify(snap.docs[0].data());
    }

    case "get_schedule": {
      const level = (input.level as string) ?? "all";
      const upcomingOnly = (input.upcoming_only as boolean) ?? true;

      let query: admin.firestore.Query = db.collection("games");

      if (level !== "all") {
        query = query.where("level", "==", level);
      }
      if (upcomingOnly) {
        query = query.where("dateTime", ">=", new Date());
      }

      const snap = await query.orderBy("dateTime", "asc").limit(10).get();
      const games = snap.docs.map((doc) => doc.data());

      return JSON.stringify({ games });
    }

    case "get_calendar_events": {
      const daysAhead = (input.days_ahead as number) ?? 7;
      const now = new Date();
      const end = new Date(now.getTime() + daysAhead * 86400000);

      const snap = await db
        .collection("calendarEvents")
        .where("startTime", ">=", now)
        .where("startTime", "<=", end)
        .orderBy("startTime", "asc")
        .get();

      const events = snap.docs.map((doc) => doc.data());
      return JSON.stringify({ events });
    }

    case "get_depth_chart": {
      const side = (input.side as string) ?? "offense";
      const snap = await db
        .collection("depthCharts")
        .where("side", "==", side)
        .orderBy("updatedAt", "desc")
        .limit(1)
        .get();

      if (snap.empty) {
        return JSON.stringify({ error: `No ${side} depth chart found.` });
      }

      return JSON.stringify(snap.docs[0].data());
    }

    case "get_my_game_stats": {
      const game = (input.game as string) ?? "season";

      let query: admin.firestore.Query = db
        .collection("players")
        .doc(playerId)
        .collection("gameStats");

      if (game !== "season") {
        query = query.where("opponent", "==", game);
      }

      const snap = await query.orderBy("gameDate", "desc").get();
      const stats = snap.docs.map((doc) => doc.data());

      return JSON.stringify({ stats });
    }

    case "get_season_awards": {
      const snap = await db
        .collection("gameAwards")
        .orderBy("gameDate", "desc")
        .get();

      const awards = snap.docs.map((doc) => doc.data());
      const playerAwards = awards.filter(
        (a) =>
          a.playerOfGame === playerId ||
          a.offensivePOG === playerId ||
          a.defensivePOG === playerId ||
          a.specialTeamsPOG === playerId
      );

      return JSON.stringify({ allAwards: awards, playerAwards });
    }

    case "get_recruiting_profile": {
      const snap = await db
        .collection("recruitingProfiles")
        .doc(playerId)
        .get();

      if (!snap.exists) {
        return JSON.stringify({
          error: "No recruiting profile found. Ask Coach about setting one up.",
        });
      }

      return JSON.stringify(snap.data());
    }

    case "draft_recruiting_email": {
      // Return the inputs so Claude can compose the email using player context
      return JSON.stringify({
        college: input.college,
        coachName: input.coachName ?? "Coaching Staff",
        personalNote: input.personalNote ?? "",
        instruction:
          "Use the player's stats from the system prompt to compose a professional recruiting email.",
      });
    }

    case "get_ncaa_eligibility_info": {
      const division = (input.division as string) ?? "D1";
      // Static NCAA info — could be moved to Firestore
      const eligibility: Record<string, object> = {
        D1: {
          gpa: "2.3 minimum (sliding scale with test scores)",
          coreCredits: "16 core courses required",
          testScores: "SAT/ACT required (sliding scale with GPA)",
          registration: "Must register at eligibilitycenter.org",
          notes:
            "Contact period begins June 15 after sophomore year for football",
        },
        D2: {
          gpa: "2.2 minimum",
          coreCredits: "16 core courses required",
          testScores: "SAT/ACT required",
          registration: "Must register at eligibilitycenter.org",
          notes: "Partial scholarships available — can stack with academic aid",
        },
        D3: {
          gpa: "Determined by individual schools",
          coreCredits: "Determined by individual schools",
          testScores: "Varies by school — many test-optional",
          registration: "No NCAA clearinghouse needed",
          notes:
            "No athletic scholarships — but academic and merit aid available",
        },
        NAIA: {
          gpa: "2.0 minimum",
          coreCredits: "Varies by school",
          testScores: "Meet 2 of 3: GPA, test score, class rank",
          registration: "Register at playnaia.org",
          notes: "Full and partial athletic scholarships available",
        },
      };

      return JSON.stringify(eligibility[division] ?? eligibility["D1"]);
    }

    case "get_announcements": {
      const count = (input.count as number) ?? 5;
      const snap = await db
        .collection("announcements")
        .orderBy("createdAt", "desc")
        .limit(count)
        .get();

      const announcements = snap.docs.map((doc) => doc.data());
      return JSON.stringify({ announcements });
    }

    case "get_team_roster": {
      const level = (input.level as string) ?? "varsity";
      const snap = await db
        .collection("players")
        .where("team", "==", level)
        .where("active", "==", true)
        .orderBy("lastName")
        .get();

      const roster = snap.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      return JSON.stringify({ level, roster });
    }

    case "save_recruiting_interest": {
      const profileRef = db.collection("recruitingProfiles").doc(playerId);
      await profileRef.set(
        {
          collegeInterests: admin.firestore.FieldValue.arrayUnion({
            college: input.college,
            level: input.level ?? "unknown",
            notes: input.notes ?? "",
            addedAt: new Date(),
          }),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return JSON.stringify({
        success: true,
        message: `Added ${input.college} to your recruiting interest list.`,
      });
    }

    default:
      return JSON.stringify({ error: `Unknown tool: ${toolName}` });
  }
}
