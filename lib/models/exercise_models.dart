class Exercise {
  final String id;
  final String name;
  final int typeId;
  final int muscleId;
  final int equipmentId;
  final int bodyPartId;
  final String? mediaId;
  final String ownType;
  final int priority;

  Exercise({
    required this.id,
    required this.name,
    required this.typeId,
    required this.muscleId,
    required this.equipmentId,
    required this.bodyPartId,
    this.mediaId,
    this.ownType = 'custom',
    required this.priority
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      typeId: json['type_id'],
      muscleId: json['muscle_id'],
      equipmentId: json['equipment_id'],
      bodyPartId: json['bodyPart_id'],
      mediaId: json['mediaId'],
      ownType: json['own_type'] ?? 'custom',
      priority: json['priority'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type_id': typeId,
      'muscle_id': muscleId,
      'equipment_id': equipmentId,
      'bodyPart_id': bodyPartId,
      'mediaId': mediaId,
      'own_type': ownType,
      'priority': priority,
    };
  }
}

class ExerciseType {
  final String id;
  final String name;

  ExerciseType({required this.id, required this.name});

  factory ExerciseType.fromJson(Map<String, dynamic> json) {
    return ExerciseType(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class Muscle {
  final String id;
  final String name;

  Muscle({required this.id, required this.name});

  factory Muscle.fromJson(Map<String, dynamic> json) {
    return Muscle(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class Equipment {
  final String id;
  final String name;

  Equipment({required this.id, required this.name});

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class BodyPart {
  final String id;
  final String name;

  BodyPart({required this.id, required this.name});

  factory BodyPart.fromJson(Map<String, dynamic> json) {
    return BodyPart(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class ExerciseWithMuscle {
  final String id;
  final String name;
  final int typeId;
  final int muscleId;
  final String muscle;
  final int equipmentId;
  final int bodyPartId;
  final String? mediaId;
  final String ownType;
  final int priority;

  ExerciseWithMuscle({
    required this.id,
    required this.name,
    required this.typeId,
    required this.muscleId,
    required this.muscle,
    required this.equipmentId,
    required this.bodyPartId,
    this.mediaId,
    this.ownType = 'custom',
    required this.priority,
  });

  factory ExerciseWithMuscle.fromJson(Map<String, dynamic> json) {
    return ExerciseWithMuscle(
      id: json['id'].toString(),
      name: json['name'],
      typeId: json['type_id'],
      muscleId: json['muscle_id'],
      muscle: json['muscleName'],
      equipmentId: json['equipment_id'],
      bodyPartId: json['bodyPart_id'],
      mediaId: json['mediaId'],
      ownType: json['own_type'] ?? 'custom',
      priority: json['priority'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type_id': typeId,
      'muscle_id': muscleId,
      'muscle_name': muscle,
      'equipment_id': equipmentId,
      'bodyPart_id': bodyPartId,
      'mediaId': mediaId,
      'own_type': ownType,
      'priority': priority,
    };
  }
}

class Workout {
  int? id;
  String name;

  Workout({this.id, required this.name});

  // Convert a map (database row) into a Workout object
  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      name: json['name'],
    );
  }

  // Convert a Workout object into a map to insert into the database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class WorkoutExercise {
  int? id;
  int workoutId;
  String exerciseId;
  int orderIndex;  // Add this field

  WorkoutExercise({
    this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.orderIndex,  // Add this parameter
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id'],
      workoutId: json['workout_id'],
      exerciseId: json['exercise_id'],
      orderIndex: json['order_index'],  // Add this field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'order_index': orderIndex,  // Add this field
    };
  }
}

class WorkoutLog {
  int? id;
  int? workoutId;
  String startDate; // Stored in ISO 8601 format (YYYY-MM-DD HH:MM:SS)
  int isFinished;

  WorkoutLog({this.id, this.workoutId, required this.startDate, required this.isFinished});

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'],
      workoutId: json['workout_id'],
      startDate: json['start_date'],
      isFinished: json['is_finished'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_id': workoutId,
      'start_date': startDate,
      'is_finished': isFinished,
    };
  }
}

class ExerciseSet {
  int? id;
  int? workoutLogId;
  int? workoutId;
  String exerciseId;
  int setNumber;
  double weight;
  int reps;
  int isFinished;

  ExerciseSet({
    this.id,
    this.workoutLogId,
    this.workoutId,
    required this.exerciseId,
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.isFinished
  });

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      id: json['id'],
      workoutLogId: json['workout_log_id'],
      workoutId: json['workout_id'],
      exerciseId: json['exercise_id'],
      setNumber: json['set_number'],
      weight: json['weight'],
      reps: json['reps'],
      isFinished: json['is_finished'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_log_id': workoutLogId,
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'weight': weight,
      'reps': reps,
      'is_finished': isFinished,
    };
  }
}

class WorkoutPlanExercise {
  final ExerciseWithMuscle exercise;
  final List<WorkoutSet> sets;

  WorkoutPlanExercise({
    required this.exercise,
    List<WorkoutSet>? sets,
  }) : sets = sets ?? [];

  void addSet() {
    // Add a new set with default values or copied from the last set
    final newSetNumber = sets.length + 1;
    final lastSet = sets.isNotEmpty ? sets.last : null;

    sets.add(WorkoutSet(
      setNumber: newSetNumber,
      weight: lastSet?.weight ?? 0,
      reps: lastSet?.reps ?? 0,
      isFinished: 0,
    ));
  }

  void removeSet(int index) {
    sets.removeAt(index);
    // Renumber remaining sets
    for (var i = 0; i < sets.length; i++) {
      sets[i].setNumber = i + 1;
    }
  }
}

class WorkoutSet {
  int setNumber;
  double weight;
  int reps;
  int isFinished;

  WorkoutSet({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.isFinished,
  });
}

class ExerciseHistory {
  final DateTime date;
  final double weight;
  final int reps;
  final int workoutLogId;

  ExerciseHistory({
    required this.date,
    required this.weight,
    required this.reps,
    required this.workoutLogId,
  });

  factory ExerciseHistory.fromJson(Map<String, dynamic> json) {
    return ExerciseHistory(
      date: DateTime.parse(json['start_date']),
      weight: json['weight'].toDouble(),
      reps: json['reps'],
      workoutLogId: json['workout_log_id'],
    );
  }
}
