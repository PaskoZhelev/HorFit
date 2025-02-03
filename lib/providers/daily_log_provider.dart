import 'package:flutter/material.dart';
import '../models/food_models.dart';
import '../database//database_helper.dart';

class DailyLogProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  DailyLog? _currentLog;
  DateTime _currentDate = DateTime.now();

  DailyLog? get currentLog => _currentLog;

  DateTime get currentDate => _currentDate;

  Future<void> loadDailyLog([DateTime? date]) async {
    _currentDate = date ?? DateTime.now();
    _currentLog = await _dbHelper.getDailyLog(_currentDate);

    if (_currentLog == null) {
      // Create new log with default meal types
      final logId = await _dbHelper.createDailyLog(_currentDate);

      // Create default meals
      final defaultMeals = [
        'Breakfast',
        'Snack 1',
        'Lunch',
        'Snack 2',
        'Dinner'
      ];
      for (var mealType in defaultMeals) {
        await _dbHelper.createDailyMeal(logId, mealType);
      }

      // Fetch the newly created log
      _currentLog = await _dbHelper.getDailyLog(_currentDate);
    }

    notifyListeners();
  }

  Future<void> addFoodToMeal(int mealId, Food food, double servingSize) async {
    if (food.id == null) {
      throw Exception('Food must have an ID to be added to a meal');
    }
    await _dbHelper.addFoodToDailyMeal(mealId, food.id!, servingSize);
    await loadDailyLog(_currentDate);
  }

  Future<void> removeFoodFromMeal(int mealId, int foodId) async {
    await _dbHelper.removeFoodFromDailyMeal(mealId, foodId);
    await loadDailyLog(_currentDate);
  }

  Future<void> updateFoodServing(int mealId, int foodId,
      double newServing) async {
    await _dbHelper.updateDailyMealFood(mealId, foodId, newServing);
    await loadDailyLog(_currentDate);
  }

  void changeDate(DateTime newDate) {
    loadDailyLog(newDate);
  }

  Map<String, double> calculateDailyTotals() {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    if (_currentLog != null) {
      for (var meal in _currentLog!.meals) {
        for (var food in meal.foods) {
          calories += food.adjustedCalories;
          protein += food.adjustedProtein;
          carbs += food.adjustedCarb;
          fat += food.adjustedFat;
        }
      }
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  Future<void> addMealType(String mealType, int logId) async {
    await _dbHelper.createDailyMeal(logId, mealType);
    await loadDailyLog(_currentDate);
  }

  Future<void> deleteMealType(int mealId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Delete all foods in this meal
      await txn.delete(
        'daily_meal_foods',
        where: 'meal_id = ?',
        whereArgs: [mealId],
      );

      // Delete the meal itself
      await txn.delete(
        'daily_meals',
        where: 'id = ?',
        whereArgs: [mealId],
      );
    });

    await loadDailyLog(_currentDate);
  }

  Future<void> importFromMealPlan(int planId) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Get the current log ID
      final logId = _currentLog?.id;
      if (logId == null) throw Exception('No current log found');

      // Delete all existing meals and their foods for the current day
      final existingMeals = await txn.query(
        'daily_meals',
        where: 'log_id = ?',
        whereArgs: [logId],
      );

      for (final meal in existingMeals) {
        await txn.delete(
          'daily_meal_foods',
          where: 'meal_id = ?',
          whereArgs: [meal['id']],
        );
      }

      await txn.delete(
        'daily_meals',
        where: 'log_id = ?',
        whereArgs: [logId],
      );

      // Get all meals from the selected meal plan
      final planMeals = await txn.query(
        'plan_meals',
        where: 'plan_id = ?',
        whereArgs: [planId],
      );

      // For each meal in the plan
      for (final planMeal in planMeals) {
        // Create new daily meal
        final newMealId = await txn.insert('daily_meals', {
          'log_id': logId,
          'meal_type': planMeal['meal_type'],
        });

        // Get all foods from the plan meal
        final planMealFoods = await txn.query(
          'plan_meal_food',
          where: 'meal_id = ?',
          whereArgs: [planMeal['id']],
        );

        // Add each food to the new daily meal
        for (final planMealFood in planMealFoods) {
          await txn.insert('daily_meal_foods', {
            'meal_id': newMealId,
            'food_id': planMealFood['food_id'],
            'servingSize': planMealFood['servingSize'],
          });
        }
      }
    });

    // Reload the current log to refresh the UI
    await loadDailyLog(_currentDate);
  }
}
