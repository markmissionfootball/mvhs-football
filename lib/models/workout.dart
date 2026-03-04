import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String name;
  final int sets;
  final String reps;
  final double? percentOfMax;
  final String? liftReference;
  final String? notes;

  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.percentOfMax,
    this.liftReference,
    this.notes,
  });

  factory Exercise.fromMap(Map<String, dynamic> data) {
    return Exercise(
      name: data['name'] ?? '',
      sets: data['sets'] ?? 0,
      reps: data['reps']?.toString() ?? '',
      percentOfMax: (data['percentOfMax'] as num?)?.toDouble(),
      liftReference: data['liftReference'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'percentOfMax': percentOfMax,
        'liftReference': liftReference,
        'notes': notes,
      };
}

class WorkoutProgram {
  final String id;
  final String phaseName;
  final List<Exercise> exercises;

  const WorkoutProgram({
    required this.id,
    required this.phaseName,
    required this.exercises,
  });

  factory WorkoutProgram.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutProgram(
      id: doc.id,
      phaseName: data['phaseName'] ?? '',
      exercises: (data['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'phaseName': phaseName,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }
}

class PlayerWorkoutExercise {
  final String name;
  final double targetWeight;
  final int sets;
  final String reps;
  final bool completed;

  const PlayerWorkoutExercise({
    required this.name,
    required this.targetWeight,
    required this.sets,
    required this.reps,
    this.completed = false,
  });

  factory PlayerWorkoutExercise.fromMap(Map<String, dynamic> data) {
    return PlayerWorkoutExercise(
      name: data['name'] ?? '',
      targetWeight: (data['targetWeight'] as num?)?.toDouble() ?? 0,
      sets: data['sets'] ?? 0,
      reps: data['reps']?.toString() ?? '',
      completed: data['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'targetWeight': targetWeight,
        'sets': sets,
        'reps': reps,
        'completed': completed,
      };
}

class PlayerWorkout {
  final String phase;
  final List<PlayerWorkoutExercise> exercises;
  final DateTime assignedDate;
  final DateTime? completedDate;

  const PlayerWorkout({
    required this.phase,
    required this.exercises,
    required this.assignedDate,
    this.completedDate,
  });

  factory PlayerWorkout.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlayerWorkout(
      phase: data['phase'] ?? '',
      exercises: (data['exercises'] as List<dynamic>?)
              ?.map((e) =>
                  PlayerWorkoutExercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      assignedDate: (data['assignedDate'] as Timestamp).toDate(),
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'phase': phase,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'assignedDate': Timestamp.fromDate(assignedDate),
      'completedDate':
          completedDate != null ? Timestamp.fromDate(completedDate!) : null,
    };
  }
}
