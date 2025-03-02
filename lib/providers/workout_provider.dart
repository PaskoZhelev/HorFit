import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hor_fit/database/database_helper.dart';
import 'package:hor_fit/models/exercise_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      for (var i = 0; i < exercises.length; i++) {
        var exercise = exercises[i];
        String exerciseId = exercise.exercise.id;

        // Insert into the 'workout_exercises' table
        await txn.insert(
          'workout_exercises',
          {
            'workout_id': workoutId,
            'exercise_id': exerciseId,
            'order_index': i,
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
    LEFT JOIN workout_exercises we ON e.id = we.exercise_id
    INNER JOIN exercise_sets es ON e.id = es.exercise_id
    INNER JOIN muscles ON e.muscle_id = muscles.id
    WHERE es.workout_log_id = ?
    ORDER BY we.order_index
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

  Future<int> startWorkoutKeepWeightsAndExercises(int workoutId) async {
    final db = await _dbHelper.database;

    final prefs = await SharedPreferences.getInstance();
    var useExercisesFromLastLog = prefs.getBool('useExercisesFromLastLog') ?? true;

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

    if (previousLogQuery.isNotEmpty && useExercisesFromLastLog) {
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
        workout_exercises.order_index,
        exercise_sets.set_number,
        exercise_sets.weight,
        exercise_sets.reps
      FROM workout_exercises
      LEFT JOIN exercise_sets ON 
        workout_exercises.workout_id = exercise_sets.workout_id 
        AND workout_exercises.exercise_id = exercise_sets.exercise_id
      WHERE workout_exercises.workout_id = ?
      ORDER BY workout_exercises.order_index, exercise_sets.set_number
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

  Future<int> startWorkoutKeepingOnlyWeights(int workoutId, DateTime? customStartDate) async {
    final db = await _dbHelper.database;
    final prefs = await SharedPreferences.getInstance();
    var useExercisesFromLastLog = prefs.getBool('useExercisesFromLastLog') ?? true;

    // Get the last workout log for this workout
    final previousLogQuery = await db.query(
        'workout_logs',
        where: 'workout_id = ?',
        whereArgs: [workoutId],
        orderBy: 'start_date DESC',
        limit: 1
    );

    var workoutLog;
    if(customStartDate != null) {
      // Create workout log
      workoutLog = {
        'workout_id': workoutId,
        'start_date': customStartDate.toIso8601String(),
        'end_date': customStartDate.add(Duration(minutes: 60)).toIso8601String(),
        'is_finished': 0,
      };
    } else{
      // Create workout log
      workoutLog = {
        'workout_id': workoutId,
        'start_date': DateTime.now().toIso8601String(),
        'end_date': DateTime.now().toIso8601String(),
        'is_finished': 0,
      };
    }


    final logId = await db.insert('workout_logs', workoutLog);
    final batch = db.batch();

    // Get the workout template exercises
    final templateExercises = await db.query(
      'workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'order_index',
    );

    // Get the workout template exercises with their sets
    final templateSets = await db.rawQuery('''
    SELECT 
      we.exercise_id,
      we.order_index,
      es.set_number,
      es.weight,
      es.reps
    FROM workout_exercises we
    LEFT JOIN exercise_sets es ON 
      we.workout_id = es.workout_id 
      AND we.exercise_id = es.exercise_id
    WHERE we.workout_id = ?
    ORDER BY we.order_index, es.set_number
  ''', [workoutId]);

    // Group template sets by exercise_id
    Map<String, List<Map<String, dynamic>>> templateExerciseSets = {};
    for (var set in templateSets) {
      String exerciseId = set['exercise_id'] as String;
      templateExerciseSets.putIfAbsent(exerciseId, () => []);
      templateExerciseSets[exerciseId]!.add(set);
    }

    // Create a map to store the last weights for each exercise
    Map<String, List<Map<String, dynamic>>> lastExerciseSets = {};

    if (previousLogQuery.isNotEmpty && useExercisesFromLastLog) {
      final previousLogId = previousLogQuery.first['id'] as int;
      final previousSets = await db.query(
        'exercise_sets',
        where: 'workout_log_id = ?',
        whereArgs: [previousLogId],
      );

      // Group sets by exercise_id
      for (var set in previousSets) {
        String exerciseId = set['exercise_id'] as String;
        lastExerciseSets.putIfAbsent(exerciseId, () => []);
        lastExerciseSets[exerciseId]!.add(set);
      }
    }

    // Process each exercise from the template
    for (String exerciseId in templateExerciseSets.keys) {
      List<Map<String, dynamic>> previousSets = lastExerciseSets[exerciseId] ?? [];
      List<Map<String, dynamic>> templateSetsForExercise = templateExerciseSets[exerciseId] ?? [];

      if (previousSets.isNotEmpty && useExercisesFromLastLog) {
        // Use sets from the previous workout with their weights and reps
        for (var set in previousSets) {
          batch.insert('exercise_sets', {
            'workout_log_id': logId,
            'exercise_id': exerciseId,
            'set_number': set['set_number'],
            'weight': set['weight'],
            'reps': set['reps'],
            'is_finished': 0,
          });
        }
      } else {
        // First try to find the most recent sets for this exercise from any previous workout log
        final mostRecentSetsQuery = await db.rawQuery('''
        SELECT es.*
        FROM exercise_sets es
        JOIN workout_logs wl ON es.workout_log_id = wl.id
        WHERE wl.workout_id = ? 
        AND es.exercise_id = ?
        AND wl.id < ?
        ORDER BY wl.start_date DESC
        LIMIT 1
    ''', [workoutId, exerciseId, logId]);

        if (mostRecentSetsQuery.isNotEmpty) {
          // Found previous sets for this exercise, use those
          final previousWorkoutLogId = mostRecentSetsQuery.first['workout_log_id'];
          final previousSets = await db.query(
              'exercise_sets',
              where: 'workout_log_id = ? AND exercise_id = ?',
              whereArgs: [previousWorkoutLogId, exerciseId],
              orderBy: 'set_number'
          );

          for (var set in previousSets) {
            batch.insert('exercise_sets', {
              'workout_log_id': logId,
              'exercise_id': exerciseId,
              'set_number': set['set_number'],
              'weight': set['weight'],
              'reps': set['reps'],
              'is_finished': 0,
            });
          }
        } else {
          // No previous sets found, use template sets
          for (var set in templateSetsForExercise) {
            batch.insert('exercise_sets', {
              'workout_log_id': logId,
              'exercise_id': exerciseId,
              'set_number': set['set_number'] ?? 1,
              'weight': set['weight'] ?? 0.0,
              'reps': set['reps'] ?? 0,
              'is_finished': 0,
            });
          }
        }
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
  Future<void> finishWorkout(int workoutLogId, List<WorkoutPlanExercise> exercises, DateTime? customDate) async {
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

      var endDate = customDate != null ? customDate : DateTime.now();
      // Update workout log status
      await txn.update(
        'workout_logs',
        {
          'is_finished': 1,
          'end_date': endDate.toIso8601String(),
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

    // First, get all exercises for this workout log
    final exercises = await db.rawQuery('''
    SELECT DISTINCT e.*
    FROM exercise_sets es
    JOIN exercises e ON es.exercise_id = e.id
    WHERE es.workout_log_id = ?
    ORDER BY e.name
  ''', [workoutLogId]);

    // For each exercise, get its sets
    List<Map<String, dynamic>> result = [];

    for (var exercise in exercises) {
      final sets = await db.rawQuery('''
      SELECT 
        set_number,
        weight,
        reps,
        is_finished
      FROM exercise_sets
      WHERE workout_log_id = ? AND exercise_id = ?
      ORDER BY set_number
    ''', [workoutLogId, exercise['id']]);

      result.add({
        ...exercise,
        'sets': sets,
      });
    }

    return result;
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

  Future<List<ExerciseHistory>> getExerciseHistory(String exerciseId) async {
    return await _dbHelper.getExerciseHistory(exerciseId);
  }

  Future<List<Map<String, dynamic>>> getLastSetsForExercise(String exerciseId) async {
    final db = await _dbHelper.database;

    return await db.rawQuery('''
    SELECT * 
    FROM exercise_sets 
    WHERE exercise_id = ? 
    AND workout_log_id = (
        SELECT MAX(workout_log_id) 
        FROM exercise_sets 
        WHERE exercise_id = ?
        AND workout_log_id IS NOT NULL
    )
    ORDER BY set_number ASC;
  ''', [exerciseId, exerciseId]);
  }
}