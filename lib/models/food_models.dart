class Food {
  int? id; // Nullable for new items before saving in the database
  String name;
  double calories;
  double servingSize;
  String measure; // Example: gram, cup, slice, other
  double fat;
  double protein;
  double carbohydrate;
  String type;

  Food({
    this.id,
    required this.name,
    required this.calories,
    required this.servingSize,
    required this.measure,
    required this.fat,
    required this.protein,
    required this.carbohydrate,
    required this.type,
  });

  // Convert Food object to a map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'servingSize': servingSize,
      'measure': measure,
      'fat': fat,
      'protein': protein,
      'carbohydrate': carbohydrate,
      'type': type,
    };
  }

  // Convert map from SQLite to Food object
  static Food fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['id'],
      name: map['name'],
      calories: map['calories'],
      servingSize: map['servingSize'],
      measure: map['measure'],
      fat: map['fat'],
      protein: map['protein'],
      carbohydrate: map['carbohydrate'],
      type: map['type'],
    );
  }
}

class FoodPlan {
  int? id; // Nullable until saved in the database
  String name;

  FoodPlan({this.id, required this.name});

  // Convert FoodPlan object to a map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Convert map from SQLite to FoodPlan object
  static FoodPlan fromMap(Map<String, dynamic> map) {
    return FoodPlan(
      id: map['id'],
      name: map['name'],
    );
  }
}

class PlanMeal {
  final int? id;
  final int planId;
  final String mealType;

  PlanMeal({
    this.id,
    required this.planId,
    required this.mealType,
  });

  factory PlanMeal.fromMap(Map<String, dynamic> map) {
    return PlanMeal(
      id: map['id'],
      planId: map['plan_id'],
      mealType: map['meal_type'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plan_id': planId,
      'meal_type': mealType,
    };
  }
}

class PlanMealFood {
  final int? id;
  final int mealId; // PlanMeal ID
  final int foodId;
  final double servingSize; // Storing specific serving size

  PlanMealFood({
    this.id,
    required this.mealId,
    required this.foodId,
    required this.servingSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meal_id': mealId,
      'food_id': foodId,
      'servingSize': servingSize,
    };
  }

  static PlanMealFood fromMap(Map<String, dynamic> map) {
    return PlanMealFood(
      id: map['id'],
      mealId: map['meal_id'],
      foodId: map['food_id'],
      servingSize: map['servingSize'],
    );
  }
}


class Meal {
  final int? id;
  final String name;
  final List<FoodWithServing> foods;

  Meal({
    this.id,
    required this.name,
    required this.foods,
  });
}

class FoodWithServing {
  final Food food;
  final double servingSize;

  FoodWithServing({required this.food, required this.servingSize});

  double get adjustedCalories => (servingSize / food.servingSize) * food.calories;
  double get adjustedProtein => (servingSize / food.servingSize) * food.protein;
  double get adjustedCarb => (servingSize / food.servingSize) * food.carbohydrate;
  double get adjustedFat => (servingSize / food.servingSize) * food.fat;
}

class DailyLog {
  int? id;
  DateTime date;
  List<DailyMeal> meals;

  DailyLog({
    this.id,
    required this.date,
    required this.meals,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
    };
  }

  static DailyLog fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'],
      date: DateTime.parse(map['date']),
      meals: [], // This will be populated separately
    );
  }
}

class DailyMeal {
  int? id;
  int logId;
  String mealType;
  List<FoodWithServing> foods;

  DailyMeal({
    this.id,
    required this.logId,
    required this.mealType,
    required this.foods,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'log_id': logId,
      'meal_type': mealType,
    };
  }

  static DailyMeal fromMap(Map<String, dynamic> map) {
    return DailyMeal(
      id: map['id'],
      logId: map['log_id'],
      mealType: map['meal_type'],
      foods: [], // This will be populated separately
    );
  }
}

class DailyMealFood {
  int? id;
  int mealId;
  int foodId;
  double servingSize;

  DailyMealFood({
    this.id,
    required this.mealId,
    required this.foodId,
    required this.servingSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meal_id': mealId,
      'food_id': foodId,
      'servingSize': servingSize,
    };
  }

  static DailyMealFood fromMap(Map<String, dynamic> map) {
    return DailyMealFood(
      id: map['id'],
      mealId: map['meal_id'],
      foodId: map['food_id'],
      servingSize: map['servingSize'],
    );
  }
}