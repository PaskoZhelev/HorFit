import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hor_fit/models/exercise_models.dart';
import 'package:hor_fit/models/food_models.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = join(await getDatabasesPath(), DB_NAME);

    File dbFile = File(dbPath);

    var exists = await dbFile.exists();

    if (!exists) {
      await resetDb(dbPath);
    }

    // open the database
    return await openDatabase(dbPath);
  }

  Future<void> resetDb(var dbPath) async {
    try {
      await Directory(dirname(dbPath)).create(recursive: true);
    } catch (_) {}

    ByteData data = await rootBundle.load(join("assets/db", DB_NAME));
    List<int> bytes =
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    await File(dbPath).writeAsBytes(bytes, flush: true);
  }

  Future<void> clickResetDatabase(BuildContext context) async {
    try {
      final dbPath = join(await getDatabasesPath(), DB_NAME);
      await resetDb(dbPath);

      await _initDatabase();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Database resetted to the initial state")),
      );

    } catch (e) {
      print("Error exporting database: $e");
    }
  }

  /// Export Database using Sharing
  Future<void> exportDatabase(BuildContext context) async {
    try {
      final dbPath = join(await getDatabasesPath(), DB_NAME);
      File dbFile = File(dbPath);

      if (await dbFile.exists()) {

        Share.shareXFiles([XFile(dbFile.path)]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Database exported successfully to the selected folder")),
        );

        print("Database exported successfully to the selected folder");
      } else {
        print("Database file not found.");
      }
    } catch (e) {
      print("Error exporting database: $e");
    }
  }

  /// Import Database using SAF
  Future<void> importDatabase(BuildContext context) async {
    try {
      // Allow user to pick any file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Allow all file types
      );

      if (result != null && result.files.single.path != null) {
        String selectedFilePath = result.files.single.path!;

        // Ensure the selected file is a .db file
        if (!selectedFilePath.endsWith(".db")) {
          print("Invalid file selected. Please choose a .db file.");
          return;
        }

        String dbPath = join(await getDatabasesPath(), DB_NAME);

        // Copy the selected file to replace the existing database
        await File(selectedFilePath).copy(dbPath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Database imported successfully")),
        );

        print("Database imported successfully from: $selectedFilePath");
      } else {
        print("No file selected.");
      }
    } catch (e) {
      print("Error importing database: $e");
    }
  }

  // ---------------------------------------------------------------
  // Food Methods
  // ---------------------------------------------------------------

  Future<int> insertFood(Food food) async {
    final db = await database;
    return await db.insert('foods', food.toMap());
  }

  Future<int> updateFood(Food food) async {
    final db = await database;
    return await db.update(
      'foods',
      food.toMap(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
  }

  Future<int> deleteFood(int id) async {
    final db = await database;
    return await db.delete(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Food>> getFoods() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('foods');
    return maps.map((map) => Food.fromMap(map)).toList();
  }

  Future<List<Food>> getFoodsSorted() async {
    final db = await database;
    // Add ORDER BY clause to the query to sort by `type` and `name` in ascending order
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      orderBy:
          'type ASC, name ASC', // Sorting by `type` and `name` in ascending order
    );
    return maps.map((map) => Food.fromMap(map)).toList();
  }

  Future<Food> getFoodById(int id) async {
    final db = await database;
    final maps = await db.query(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return Food.fromMap(maps.first);
  }

  // Insert a meal into a food plan
  Future<int> insertFoodPlanMeal(PlanMeal planMeal) async {
    final db = await database;
    return await db.insert('plan_meals', planMeal.toMap());
  }

  // ---------------------------------------------------------------
  // Plan Methods
  // ---------------------------------------------------------------

  // Add a Food Plan
  Future<int> insertFoodPlan(FoodPlan plan) async {
    final db = await database;
    return await db.insert('food_plans', plan.toMap());
  }

// Get all Food Plans
  Future<List<FoodPlan>> getFoodPlans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('food_plans');
    return maps.map((map) => FoodPlan.fromMap(map)).toList();
  }

// Insert a Plan (Food Plan)
  Future<int> insertPlan(FoodPlan plan) async {
    final db = await database;
    return await db.insert('food_plans', plan.toMap());
  }

// Add a Meal to a Plan
  Future<int> addMealToPlan(int planId, String mealType) async {
    final db = await database;
    return await db.insert('plan_meals', {
      'plan_id': planId,
      'meal_type': mealType,
    });
  }

// Get Meals for a Specific Plan
  Future<List<PlanMeal>> getMealsForPlan(int planId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plan_meals',
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
    return maps.map((map) => PlanMeal.fromMap(map)).toList();
  }

// Add a Food to a Meal (using PlanMealFood table)
  Future<int> addFoodToPlanMeal(
      int mealId, int foodId, double servingSize) async {
    final db = await database;
    return await db.insert('plan_meal_food', {
      'meal_id': mealId,
      'food_id': foodId,
      'servingSize': servingSize,
    });
  }

// Get Foods for a Meal (from the PlanMealFood table)
  Future<List<FoodWithServing>> getFoodsForPlanMeal(int mealId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT 
      foods.*,
      foods.servingSize AS defaultServingSize,
      plan_meal_food.servingSize AS planMealServingSize
    FROM foods
    INNER JOIN plan_meal_food ON foods.id = plan_meal_food.food_id
    WHERE plan_meal_food.meal_id = ?
  ''', [mealId]);

    return maps
        .map((map) => FoodWithServing(
              food: Food.fromMap({
                ...map,
                'servingSize': map['defaultServingSize'],
                // Use the original serving size for the Food object
              }),
              servingSize: map[
                  'planMealServingSize'], // Use the plan meal specific serving size
            ))
        .toList();
  }

// Delete a Food Plan (and cascade delete related meals and foods)
  Future<int> deletePlan(int id) async {
    final db = await database;

    // Cascade delete plan-related meals and their foods
    final mealIds =
        await db.rawQuery('SELECT id FROM plan_meals WHERE plan_id = ?', [id]);
    for (var meal in mealIds) {
      await db.delete('plan_meal_food',
          where: 'meal_id = ?', whereArgs: [meal['id']]);
    }

    await db.delete('plan_meals', where: 'plan_id = ?', whereArgs: [id]);
    return await db.delete('food_plans', where: 'id = ?', whereArgs: [id]);
  }

// Retrieve Foods for a Specific Meal (using PlanMealFood table)
  Future<List<Food>> getFoodsForMeal(int mealId) async {
    final db = await database;

    // Join plan_meal_food and foods table to get the food details
    final List<Map<String, dynamic>> results = await db.rawQuery('''
    SELECT foods.*
    FROM foods
    INNER JOIN plan_meal_food ON foods.id = plan_meal_food.food_id
    WHERE plan_meal_food.meal_id = ?
  ''', [mealId]);

    // Convert query results to a list of Food objects
    return results.map((map) => Food.fromMap(map)).toList();
  }

// Insert a MealFood (association of food to a meal) into the database
  Future<int> insertMealFood(int mealId, int foodId, double servingSize) async {
    final db = await database;
    return await db.insert('plan_meal_food', {
      'meal_id': mealId,
      'food_id': foodId,
      'servingSize': servingSize,
    });
  }

  Future<int> updateFoodPlan(FoodPlan plan) async {
    final db = await database;
    return await db.update(
      'food_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<void> deleteFoodFromPlanMeal(int mealId, int foodId) async {
    final db = await database;
    await db.delete(
      'plan_meal_food',
      where: 'meal_id = ? AND food_id = ?',
      whereArgs: [mealId, foodId],
    );
  }

  Future<void> updateFoodPlanMealServing(
    int mealId,
    int foodId,
    double newServingSize,
  ) async {
    final db = await database;
    await db.update(
      'plan_meal_food',
      {'servingSize': newServingSize},
      where: 'meal_id = ? AND food_id = ?',
      whereArgs: [mealId, foodId],
    );
  }

  // ---------------------------------------------------------------
  // Daily Logs Methods
  // ---------------------------------------------------------------

  Future<List<FoodWithServing>> getFoodsForDailyMeal(int mealId) async {
    final db = await database;
    final foods = await db.rawQuery('''
    SELECT 
	    foods.*, 
      foods.servingSize AS defaultServingSize,
      daily_meal_foods.servingSize AS dailyMealServingSize
    FROM foods
    INNER JOIN daily_meal_foods ON foods.id = daily_meal_foods.food_id
    WHERE daily_meal_foods.meal_id = ?
  ''', [mealId]);

    return foods.map((food) {
      final baseFood = Food.fromMap({
        'id': food['id'] as int,
        'name': food['name'] as String,
        'calories': food['calories'] as double,
        'servingSize': food['defaultServingSize'] as double,
        'measure': food['measure'] as String,
        'fat': food['fat'] as double,
        'protein': food['protein'] as double,
        'carbohydrate': food['carbohydrate'] as double,
        'type': food['type'] as String,
      });

      return FoodWithServing(
        food: baseFood,
        servingSize: food['dailyMealServingSize'] as double, // This is the adjusted serving size from daily_meal_foods
      );
    }).toList();
  }

  Future<void> addFoodToDailyMeal(
    int mealId,
    int foodId,
    double servingSize,
  ) async {
    final db = await database;
    await db.insert('daily_meal_foods', {
      'meal_id': mealId,
      'food_id': foodId,
      'servingSize': servingSize,
    });
  }

  Future<void> removeFoodFromDailyMeal(
    int mealId,
    int foodId,
  ) async {
    final db = await database;
    await db.delete(
      'daily_meal_foods',
      where: 'meal_id = ? AND food_id = ?',
      whereArgs: [mealId, foodId],
    );
  }

  Future<int> createDailyMeal(int logId, String mealType) async {
    final db = await database;
    return await db.insert('daily_meals', {
      'log_id': logId,
      'meal_type': mealType,
    });
  }

  Future<void> updateDailyMealFood(
    int mealId,
    int foodId,
    double newServingSize,
  ) async {
    final db = await database;
    await db.update(
      'daily_meal_foods',
      {'servingSize': newServingSize},
      where: 'meal_id = ? AND food_id = ?',
      whereArgs: [mealId, foodId],
    );
  }

  Future<int> createDailyLog(DateTime date) async {
    final db = await database;
    return await db.insert('daily_logs', {
      'date': date.toIso8601String(),
    });
  }

  Future<DailyLog?> getDailyLog(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];

    final logs = await db.query(
      'daily_logs',
      where: 'date LIKE ?',
      whereArgs: ['$dateStr%'],
    );

    if (logs.isEmpty) return null;

    final log = DailyLog.fromMap(logs.first);
    log.meals = await getDailyMeals(log.id!);
    return log;
  }

  Future<List<DailyMeal>> getDailyMeals(int logId) async {
    final db = await database;
    final meals = await db.query(
      'daily_meals',
      where: 'log_id = ?',
      whereArgs: [logId],
    );

    final List<DailyMeal> result = [];
    for (var meal in meals) {
      final dailyMeal = DailyMeal.fromMap(meal);
      dailyMeal.foods = await getFoodsForDailyMeal(dailyMeal.id!);
      result.add(dailyMeal);
    }
    return result;
  }

// ---------------------------------------------------------------
// Exercises
// ---------------------------------------------------------------

  Future<List<Exercise>> getExercises() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('exercises');

    return List.generate(maps.length, (i) {
      return Exercise.fromJson(maps[i]);
    });
  }

  Future<List<ExerciseWithMuscle>> getExercisesWithMuscles() async {
    final db = await database;

    // SQL JOIN query to fetch exercises with their corresponding muscle names
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT exercises.*,
             muscles.name AS muscleName
      FROM exercises
      INNER JOIN muscles ON exercises.muscle_id = muscles.id
      ORDER BY
        exercises.priority DESC,
        exercises.name ASC
    ''');

    // Map the result to ExercisesWithMuscles objects
    return result.map((map) => ExerciseWithMuscle.fromJson(map)).toList();
  }

  // Method to fetch muscles
  Future<List<Muscle>> getMuscles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'muscles',
      orderBy: 'name ASC', // Sort by name in ascending order
    );

    return List.generate(maps.length, (i) {
      return Muscle.fromJson(maps[i]);
    });
  }

  Future<void> insertExercise(Exercise exercise) async {
    final db = await database;
    await db.insert(
      'exercises',
      {
        'id': exercise.id,
        'name': exercise.name,
        'type_id': exercise.typeId,
        'muscle_id': exercise.muscleId,
        'equipment_id': exercise.equipmentId,
        'bodyPart_id': exercise.bodyPartId,
        'mediaId': exercise.mediaId,
        'own_type': exercise.ownType,
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Replace if exists
    );
  }

// ---------------------------------------------------------------
// Workout Methods
// ---------------------------------------------------------------

  Future<List<Workout>> getWorkouts() async {
    final db = await database;
    final workouts = await db.query('workouts');
    return workouts.map((map) => Workout.fromJson(map)).toList();
  }

  Future<Map<int, int>> getWorkoutExerciseCount() async {
    final db = await database;
    final List<Map<String, dynamic>> workouts = await db.query('workouts');

    // Get exercise counts for each workout using a SQL query
    final List<Map<String, dynamic>> exerciseCounts = await db.rawQuery('''
    SELECT workout_id, COUNT(*) as exercise_count 
    FROM workout_exercises 
    GROUP BY workout_id
  ''');

    // Convert to Map for easy lookup
    return Map.fromEntries(
        exerciseCounts.map((row) => MapEntry(row['workout_id'] as int, row['exercise_count'] as int))
    );
  }

  Future<int> createWorkout(Workout workout) async {
    final db = await database;
    return await db.insert('workouts', workout.toJson());
  }

  Future<void> updateWorkout(Workout workout) async {
    final db = await database;
    await db.update(
      'workouts',
      workout.toJson(),
      where: 'id = ?',
      whereArgs: [workout.id],
    );
  }

  Future<void> deleteWorkout(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete all exercise sets for this workout
      await txn.delete(
        'exercise_sets',
        where: 'workout_id = ?',
        whereArgs: [id],
      );

      // Delete the workout
      await txn.delete(
        'workouts',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> deleteWorkoutExercises(int workoutId) async {
    final db = await database;
    await db.delete(
      'exercise_sets',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
  }

  Future<int> createExerciseSet(ExerciseSet set) async {
    final db = await database;
    return await db.insert('exercise_sets', set.toJson());
  }

  Future<List<WorkoutPlanExercise>> getWorkoutExercises(int workoutId) async {
    final db = await database;

    // First, get the unique exercises
    final exercises = await db.rawQuery('''
    SELECT DISTINCT e.*, muscles.name AS muscleName, we.order_index
    FROM exercises e
    INNER JOIN workout_exercises we ON e.id = we.exercise_id
    INNER JOIN exercise_sets wes ON e.id = wes.exercise_id
    INNER JOIN muscles ON e.muscle_id = muscles.id
    WHERE wes.workout_id = ?
    ORDER BY we.order_index
  ''', [workoutId]);

    // Then, get all sets for these exercises
    final List<WorkoutPlanExercise> workoutExercises = [];

    for (var exercise in exercises) {
      final sets = await db.rawQuery('''
      SELECT * FROM exercise_sets
      WHERE workout_id = ? AND exercise_id = ?
      ORDER BY set_number
    ''', [workoutId, exercise['id']]);

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

  //// WORKOUT LOGS

  Future<int> createWorkoutLog(WorkoutLog workoutLog) async {
    final db = await database;
    return await db.insert('workout_logs', workoutLog.toJson());
  }

  Future<void> createExerciseLogs(List<ExerciseSet> exerciseSets) async {
    final db = await database;
    final batch = db.batch();

    for (var set in exerciseSets) {
      batch.insert('exercise_logs', set.toJson());
    }

    await batch.commit();
  }

  Future<void> updateExerciseLog(ExerciseSet exerciseSet) async {
    final db = await database;
    await db.update(
      'exercise_logs',
      exerciseSet.toJson(),
      where: 'id = ?',
      whereArgs: [exerciseSet.id],
    );
  }

  Future<void> finishWorkoutLog(int workoutLogId) async {
    final db = await database;
    await db.update(
      'workout_logs',
      {'is_finished': 1},
      where: 'id = ?',
      whereArgs: [workoutLogId],
    );
  }

  Future<List<ExerciseSet>> getExerciseLogsForWorkout(int workoutLogId) async {
    final db = await database;
    final maps = await db.query(
      'exercise_logs',
      where: 'workout_log_id = ?',
      whereArgs: [workoutLogId],
    );

    return List.generate(maps.length, (i) => ExerciseSet.fromJson(maps[i]));
  }

  Future<List<WorkoutLog>> getWorkoutLogs() async {
    final db = await database;
    final maps = await db.query('workout_logs', orderBy: 'start_date DESC');

    return List.generate(maps.length, (i) => WorkoutLog.fromJson(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getRecentWorkoutLogs({int limit = 3}) async {
    final db = await database;
    final logs = await db.rawQuery('''
      SELECT 
        workout_logs.*,
        workouts.name as workout_name
      FROM workout_logs
      JOIN workouts ON workout_logs.workout_id = workouts.id
      WHERE workout_logs.is_finished = 1
      ORDER BY workout_logs.start_date DESC
      LIMIT ?
    ''', [limit]);

    return logs;
  }

  Future<void> deleteWorkoutLog(int workoutLogId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete all exercise sets for this workout log
      await txn.delete(
        'exercise_sets',
        where: 'workout_log_id = ?',
        whereArgs: [workoutLogId],
      );

      // Delete the workout log
      await txn.delete(
        'workout_logs',
        where: 'id = ?',
        whereArgs: [workoutLogId],
      );
    });
  }

  Future<List<Map<String, dynamic>>> getWorkoutLogsForDateRange(String startDate, String endDate) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        workout_logs.*,
        workouts.name as workout_name
      FROM workout_logs
      JOIN workouts ON workout_logs.workout_id = workouts.id
      WHERE workout_logs.start_date BETWEEN ? AND ?
        AND workout_logs.is_finished = 1
      ORDER BY workout_logs.start_date DESC
    ''', [startDate, endDate]);
  }

  Future<Map<String, int>> getWeeklyMuscleOverview(String startDate, String endDate) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT 
        m.name as muscle_name,
        COUNT(es.id) as sets_count
      FROM muscles m
      JOIN exercises e ON e.muscle_id = m.id
      JOIN exercise_sets es ON es.exercise_id = e.id
      JOIN workout_logs wl ON es.workout_log_id = wl.id
      WHERE wl.start_date BETWEEN ? AND ?
        AND wl.is_finished = 1
        AND es.is_finished = 1
      GROUP BY m.id, m.name
      HAVING sets_count > 0
      ORDER BY sets_count DESC
    ''', [startDate, endDate]);

    Map<String, int> muscleOverview = {};
    for (var row in results) {
      muscleOverview[row['muscle_name'] as String] = row['sets_count'] as int;
    }

    return muscleOverview;
  }
}
