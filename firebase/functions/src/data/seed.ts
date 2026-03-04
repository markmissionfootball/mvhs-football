import * as admin from "firebase-admin";

/**
 * Data seeding script for populating Firestore with the 213 files of
 * program data. Run with: npm run seed
 *
 * This script is designed to be run locally against the Firebase emulator
 * or a staging project — never directly against production without review.
 *
 * Data sources (from MOBILE_APP_ARCHITECTURE.md):
 * - Player roster CSVs (Varsity, JV, Freshman)
 * - Strength & conditioning max sheets
 * - Combine results
 * - Game schedules and results
 * - Depth charts
 * - Workout programs
 * - Calendar events
 * - Coaching staff directory
 */

// Initialize Firebase Admin for local script execution
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: "mvhs-football",
  });
}

const db = admin.firestore();

async function seedPlayers(): Promise<void> {
  console.log("Seeding players...");

  // TODO: Parse actual roster CSVs from the 213-file data set
  // For now, create a sample structure showing the expected format.
  const samplePlayers = [
    {
      firstName: "Sample",
      lastName: "Player",
      grade: 11,
      position: "QB",
      jerseyNumber: 7,
      team: "varsity",
      height: "6'1\"",
      weight: 185,
      sizes: { top: "L", bottom: "34", cleat: "11" },
      athleticClearance: "cleared",
      paymentStatus: {
        springBall: true,
        summerBall: true,
        contributionFee: true,
        blastContacts: true,
      },
      active: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  ];

  for (const player of samplePlayers) {
    const ref = db.collection("players").doc();
    await ref.set(player);
    console.log(`  Created player: ${player.firstName} ${player.lastName} (${ref.id})`);
  }
}

async function seedCoaches(): Promise<void> {
  console.log("Seeding coaches...");

  // TODO: Parse coaching staff from program data
  const sampleCoaches = [
    {
      firstName: "Sample",
      lastName: "Coach",
      title: "Head Coach",
      positionGroup: "Program",
      certifications: [],
      active: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  ];

  for (const coach of sampleCoaches) {
    const ref = db.collection("coaches").doc();
    await ref.set(coach);
    console.log(`  Created coach: ${coach.firstName} ${coach.lastName} (${ref.id})`);
  }
}

async function seedWorkoutPrograms(): Promise<void> {
  console.log("Seeding workout programs...");

  // TODO: Parse workout program spreadsheets
  const sampleProgram = {
    phase: "Off-Season",
    weekNumber: 1,
    dayNumber: 1,
    exercises: [
      { name: "Power Clean", sets: 4, reps: 3, percentOfMax: 0.75, liftReference: "clean" },
      { name: "Back Squat", sets: 4, reps: 5, percentOfMax: 0.75, liftReference: "squat" },
      { name: "Incline Bench", sets: 4, reps: 5, percentOfMax: 0.75, liftReference: "incline" },
    ],
    notes: "Focus on form. Control the weight.",
    active: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const ref = db.collection("workoutPrograms").doc();
  await ref.set(sampleProgram);
  console.log(`  Created workout program: ${sampleProgram.phase} Week ${sampleProgram.weekNumber}`);
}

async function main(): Promise<void> {
  console.log("=== MVHS Football Data Seed ===\n");

  try {
    await seedPlayers();
    await seedCoaches();
    await seedWorkoutPrograms();

    console.log("\nSeed complete.");
  } catch (error) {
    console.error("Seed failed:", error);
    process.exit(1);
  }
}

main();
