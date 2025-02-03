import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hor_fit/database/database_helper.dart';
import 'package:hor_fit/models/exercise_models.dart';

class WorkoutProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Workout> _workouts = [];
  Map<int,int> _workoutExerciseCount = {};

  List<Workout> get workouts => _workouts;

  Map<int,int> get workoutExerciseCount => _workoutExerciseCount;

  Future<void> loadWorkouts() async {
    _workouts = await _dbHelper.getWorkouts();
    getWorkoutExerciseCount();
    notifyListeners();
  }

  Future<void> saveWorkout({
    required String name,
    required List<WorkoutPlanExercise> exercises,
    int? workoutId,
  }) async {
    final db = await DatabaseHelper().database;

    await db.transaction((txn) async {
      // Step 1: Insert or Update Workout
      if (workoutId != null) {
        // If editing, first delete all existing exercise sets and workout exercises
        await txn.delete(
          'exercise_sets',
          where: 'workout_id = ?',
          whereArgs: [workoutId],
        );

        await txn.delete(
          'workout_exercises',
          where: 'workout_id = ?',
          whereArgs: [workoutId],
        );

        // Update the workout name
        await txn.update(
          'workouts',
          {'name': name},
          where: 'id = ?',
          whereArgs: [workoutId],
        );
      } else {
        // If it's a new workout, insert a new entry
        workoutId = await txn.insert('workouts', {'name': name});
      }

      // Step 2: Insert Exercises and Sets
      for (var exercise in exercises) {
        String exerciseId = exercise.exercise.id;

        // Insert into the 'workout_exercises' table
        await txn.insert(
          'workout_exercises',
          {
            'workout_id': workoutId,
            'exercise_id': exerciseId,
          },
        );

        // Step 3: Insert each set
        for (var set in exercise.sets) {
          await txn.insert(
            'exercise_sets',
            {
              'workout_id': workoutId,
              'exercise_id': exerciseId,
              'set_number': set.setNumber,
              'weight': set.weight,
              'reps': set.reps,
            },
          );
        }
      }
    });

    await loadWorkouts();
  }

  Future<void> deleteWorkout(int id) async {
    await _dbHelper.deleteWorkout(id);
    await loadWorkouts();
  }

  Future<List<WorkoutPlanExercise>> getWorkoutExercises(int workoutId) async {
    return await _dbHelper.getWorkoutExercises(workoutId);
  }

  Future<void> getWorkoutExerciseCount() async {
    _workoutExerciseCount = await _dbHelper.getWorkoutExerciseCount();
  }

  Future<List<WorkoutPlanExercise>> getWorkoutLogExercisesDetailed(int workoutLogId) async {
    final db = await _dbHelper.database;

    // First, get the unique exercises
    final exercises = await db.rawQuery('''
    SELECT DISTINCT e.*, muscles.name AS muscleName 
    FROM exercises e
    INNER JOIN exercise_sets es ON e.id = es.exercise_id
    INNER JOIN muscles ON e.muscle_id = muscles.id
    WHERE es.workout_log_id = ?
  ''', [workoutLogId]);

    // Then, get all sets for these exercises
    final List<WorkoutPlanExercise> workoutExercises = [];

    for (var exercise in exercises) {
      final sets = await db.rawQuery('''
      SELECT * FROM exercise_sets 
      WHERE workout_log_id = ? AND exercise_id = ? 
      ORDER BY set_number
    ''', [workoutLogId, exercise['id']]);

      final workoutExercise = WorkoutPlanExercise(
        exercise: ExerciseWithMuscle.fromJson(exercise),
      );

      for (var set in sets) {
        workoutExercise.sets.add(
          WorkoutSet(
            setNumber: set['set_number'] as int,
            weight: set['weight'] as double,
            reps: set['reps'] as int,
            isFinished: set['is_finished'] as int,
          ),
        );
      }

      workoutExercises.add(workoutExercise);
    }

    return workoutExercises;
  }

  Future<int> startWorkout(int workoutId) async {
    final db = await _dbHelper.database;

    // Check for previous workout logs
    final previousLogQuery = await db.query(
        'workout_logs',
        where: 'workout_id = ?',
        whereArgs: [workoutId],
        orderBy: 'start_date DESC',
        limit: 1
    );

    // Create workout log
    final workoutLog = {
      'workout_id': workoutId,
      'start_date': DateTime.now().toIso8601String(),
      'end_date': DateTime.now().toIso8601String(), // Will be updated when finished
      'is_finished': 0,
    };

    final logId = await db.insert('workout_logs', workoutLog);

    // Initialize batch
    final batch = db.batch();

    if (previousLogQuery.isNotEmpty) {
      // Copy sets from the previous workout log
      final previousLogId = previousLogQuery.first['id'] as int;
      final previousSets = await db.query(
        'exercise_sets',
        where: 'workout_log_id = ?',
        whereArgs: [previousLogId],
      );

      for (var set in previousSets) {
        batch.insert('exercise_sets', {
          'workout_log_id': logId,
          'exercise_id': set['exercise_id'],
          'set_number': set['set_number'],
          'weight': set['weight'],
          'reps': set['reps'],
          'is_finished': 0,
        });
      }
    } else {
      // If no previous log exists, copy from workout template
      final exercisesQuery = await db.rawQuery('''
      SELECT 
        workout_exercises.exercise_id,
        exercise_sets.set_number,
        exercise_sets.weight,
        exercise_sets.reps
      FROM workout_exercises
      LEFT JOIN exercise_sets ON 
        workout_exercises.workout_id = exercise_sets.workout_id 
        AND workout_exercises.exercise_id = exercise_sets.exercise_id
      WHERE workout_exercises.workout_id = ?
      ORDER BY workout_exercises.exercise_id, exercise_sets.set_number
    ''', [workoutId]);

      for (var row in exercisesQuery) {
        batch.insert('exercise_sets', {
          'workout_log_id': logId,
          'exercise_id': row['exercise_id'],
          'set_number': row['set_number'] ?? 1,
          'weight': row['weight'] ?? 0.0,
          'reps': row['reps'] ?? 0,
          'is_finished': 0,
        });
      }
    }

    await batch.commit();
    notifyListeners();
    return logId;
  }

  // Update a single exercise set during workout
  Future<void> updateExerciseSet(ExerciseSet set) async {
    final db = await _dbHelper.database;
    await db.update(
      'exercise_sets',
      {
        'weight': set.weight,
        'reps': set.reps,
        'is_finished': set.isFinished,
      },
      where: 'id = ?',
      whereArgs: [set.id],
    );
    notifyListeners();
  }

  // Mark workout as finished
  Future<void> finishWorkout(int workoutLogId, List<WorkoutPlanExercise> exercises) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Delete existing exercise sets for this workout log
      await txn.delete(
        'exercise_sets',
        where: 'workout_log_id = ?',
        whereArgs: [workoutLogId],
      );

      // Insert new exercise sets from the provided exercises
      for (var exercise in exercises) {
        for (var set in exercise.sets) {
          await txn.insert(
            'exercise_sets',
            {
              'workout_log_id': workoutLogId,
              'exercise_id': exercise.exercise.id,
              'set_number': set.setNumber,
              'weight': set.weight,
              'reps': set.reps,
              'is_finished': set.isFinished,
            },
          );
        }
      }

      // Update workout log status
      await txn.update(
        'workout_logs',
        {
          'is_finished': 1,
          'end_date': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [workoutLogId],
      );
    });

    notifyListeners();
  }

  // Get all exercise sets for a specific workout log
  Future<List<ExerciseSet>> getWorkoutLogExercises(int workoutLogId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exercise_sets',
      where: 'workout_log_id = ?',
      whereArgs: [workoutLogId],
    );

    return List.generate(maps.length, (i) => ExerciseSet.fromJson(maps[i]));
  }

  // Get workout history
  Future<List<WorkoutLog>> getWorkoutHistory() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workout_logs',
      orderBy: 'start_date DESC',
    );

    return List.generate(maps.length, (i) => WorkoutLog.fromJson(maps[i]));
  }

  // Calculate workout duration
  Duration calculateWorkoutDuration(String startDate, String? endDate) {
    final start = DateTime.parse(startDate);
    final end = endDate != null ? DateTime.parse(endDate) : DateTime.now();
    return end.difference(start);
  }

  Future<List<Map<String, dynamic>>> getRecentWorkoutLogs({int limit = 3}) async {
    return await _dbHelper.getRecentWorkoutLogs(limit: limit);

  }

  Future<List<Map<String, dynamic>>> getWorkoutLogDetails(int workoutLogId) async {
    final db = await _dbHelper.database;

    // Get all exercises and their sets for this workout log
    final exercises = await db.rawQuery('''
      SELECT DISTINCT
        e.*,
        (
          SELECT json_group_array(
            json_object(
              'set_number', es.set_number,
              'weight', es.weight,
              'reps', es.reps,
              'is_finished', es.is_finished
            )
          )
          FROM exercise_sets es
          WHERE es.workout_log_id = ? AND es.exercise_id = e.id
          ORDER BY es.set_number
        ) as sets
      FROM exercise_sets es
      JOIN exercises e ON es.exercise_id = e.id
      WHERE es.workout_log_id = ?
      GROUP BY e.id
      ORDER BY e.name
    ''', [workoutLogId, workoutLogId]);

    // Parse the JSON string of sets into a List
    return exercises.map((exercise) {
      var setsJson = exercise['sets'] as String;
      List<dynamic> setsList = json.decode(setsJson);
      return {
        ...exercise,
        'sets': setsList.map((set) => Map<String, dynamic>.from(set)).toList(),
      };
    }).toList();
  }

  Future<void> deleteWorkoutLog(int workoutLogId) async {
    await _dbHelper.deleteWorkoutLog(workoutLogId);
    getRecentWorkoutLogs();
    notifyListeners();
  }

  Future<bool> hasWorkoutOnDate(DateTime date) async {
    final db = await _dbHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final result = await db.query(
      'workout_logs',
      where: 'start_date BETWEEN ? AND ? AND is_finished = 1',
      whereArgs: [startOfDay, endOfDay],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getWorkoutLogsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    return await _dbHelper.getWorkoutLogsForDateRange(startOfDay, endOfDay);
  }

  Future<Map<String, int>> getWeeklyMuscleOverview() async {
    var now = DateTime.now();
    now = DateTime(now.year, now.month, now.day);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    return await _dbHelper.getWeeklyMuscleOverview(
      startOfWeek.toIso8601String(),
      endOfWeek.toIso8601String(),
    );
  }

  Future<List<Map<String, dynamic>>> getWorkoutLogsForMonth(DateTime date) async {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

    return await _dbHelper.getWorkoutLogsForDateRange(
      startOfMonth.toIso8601String(),
      endOfMonth.toIso8601String(),
    );
  }

  Future<Set<DateTime>> getWorkoutDatesForMonth(DateTime date) async {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

    final logs = await _dbHelper.getWorkoutLogsForDateRange(
      startOfMonth.toIso8601String(),
      endOfMonth.toIso8601String(),
    );

    return logs.map((log) {
      final date = DateTime.parse(log['start_date']);
      return DateTime(date.year, date.month, date.day);
    }).toSet();
  }
}