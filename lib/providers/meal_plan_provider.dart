import 'package:flutter/material.dart';
import 'package:hor_fit/database/database_helper.dart';
import 'package:hor_fit/models/food_models.dart';

class MealPlanProvider with ChangeNotifier {
  final DatabaseHelper _databaseProvider = DatabaseHelper();

  List<FoodPlan> _foodPlans = [];
  List<PlanMeal> _planMeals = [];

  List<FoodPlan> get foodPlans => _foodPlans;

  // Fetch all food plans from the database
  Future<void> fetchFoodPlans() async {
    _foodPlans = await _databaseProvider.getFoodPlans();
    notifyListeners();
  }

  // Add a new food plan
  Future<void> addFoodPlan(FoodPlan foodPlan) async {
    await _databaseProvider.insertFoodPlan(foodPlan);
    fetchFoodPlans();
  }

  // Fetch all plan meals for a specific food plan
  Future<void> fetchPlanMeals(int foodPlanId) async {
    _planMeals = await _databaseProvider.getMealsForPlan(foodPlanId);
    notifyListeners();
  }

  // Add a meal type to the food plan
  Future<void> addMealType(PlanMeal planMeal) async {
    await _databaseProvider.insertFoodPlanMeal(planMeal);
    fetchPlanMeals(planMeal.planId);
  }

  // Get foods for a specific meal
  Future<List<Food>> getFoodsForMeal(int mealId) async {
    if(mealId == - 1)
      {
        return [];
      }
    return await _databaseProvider.getFoodsForMeal(mealId);
  }

  // Add a food to a meal
  Future<void> addFoodToMeal(int mealId, Food food, double servingSize) async {
    await _databaseProvider.insertMealFood(mealId,food.id!,servingSize);
    notifyListeners();
  }

  // Calculate macros for a specific meal
  Future<Map<String, double>> calculateMealMacros(int mealId) async {
    if(mealId == -1)
      {
        return {
          'calories': 0,
          'protein': 0,
          'carbs': 0,
          'fat': 0
        };
      }

    final mealFoods = await getFoodsForMeal(mealId);

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var food in mealFoods) {
      final adjustedMacros = calculateFoodMacros(food);
      totalCalories += adjustedMacros['calories']!;
      totalProtein += adjustedMacros['protein']!;
      totalCarbs += adjustedMacros['carbs']!;
      totalFat += adjustedMacros['fat']!;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  // Calculate macros for a single food item based on its serving size
  Map<String, double> calculateFoodMacros(Food food, {double? servingSize}) {
    servingSize ??= food.servingSize;

    final multiplier = servingSize / food.servingSize;
    return {
      'calories': food.calories * multiplier,
      'protein': food.protein * multiplier,
      'carbs': food.carbohydrate * multiplier,
      'fat': food.fat * multiplier,
    };
  }

  // Calculate macros for an entire food plan
  Future<Map<String, double>> calculateMealPlanMacros(int planId) async {
    final dbHelper = DatabaseHelper();
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    final meals = await dbHelper.getMealsForPlan(planId);

    for (final meal in meals) {
      final foods = await dbHelper.getFoodsForPlanMeal(meal.id!);

      for (final foodWithServing in foods) {
        final ratio = foodWithServing.servingSize / foodWithServing.food.servingSize;
        totalCalories += foodWithServing.food.calories * ratio;
        totalProtein += foodWithServing.food.protein * ratio;
        totalCarbs += foodWithServing.food.carbohydrate * ratio;
        totalFat += foodWithServing.food.fat * ratio;
      }
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  Future<void> addFoodToPlanMeal(mealId, FoodWithServing foodWithServing) async {
    await _databaseProvider.addFoodToPlanMeal(
      mealId,
      foodWithServing.food.id!,
      foodWithServing.servingSize,
    );

    fetchFoodPlans();
  }

  Future<void> deletePlan(int planId) async {
    await _databaseProvider.deletePlan(planId);

    fetchFoodPlans();
  }
}

