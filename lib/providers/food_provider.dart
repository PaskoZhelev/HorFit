import 'package:flutter/material.dart';
import '../models/food_models.dart';
import '../database/database_helper.dart';

class FoodProvider with ChangeNotifier {
  List<Food> _foods = [];

  List<Food> get foods => _foods;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> fetchFoods() async {
    _foods = await _dbHelper.getFoodsSorted();
    notifyListeners();
  }

  Food? getFoodById(int id) {
    try {
      return _foods.firstWhere((food) => food.id == id);
    } catch (e) {
      return null; // Return null if the food ID is not found
    }
  }

  Future<void> addFood(Food food) async {
    await _dbHelper.insertFood(food);
    await fetchFoods();
  }

  Future<void> updateFood(Food food) async {
    await _dbHelper.updateFood(food);
    await fetchFoods();
  }

  Future<void> deleteFood(int id) async {
    await _dbHelper.deleteFood(id);
    await fetchFoods();
  }

  void removeFoodFromList(int id) {
    final foodIndex = _foods.indexWhere((food) => food.id == id);
    if (foodIndex != -1) {
      _foods.removeAt(foodIndex);
      notifyListeners();  // Update the UI after removal
    }
  }

  // Restore the food back to the list if deletion is canceled
  void addFoodBackToList(Food food) {
    _foods.add(food);
    notifyListeners();  // Update the UI after restoration
  }
}

