import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hor_fit/database/database_helper.dart';
import 'package:hor_fit/models/food_models.dart';
import 'package:hor_fit/providers/meal_plan_provider.dart';
import 'package:hor_fit/screens/mealPlan/adjust_serving_screen.dart';
import 'package:hor_fit/screens/mealPlan/select_food_screen.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:provider/provider.dart';

class AddFoodPlanScreen extends StatefulWidget {
  final FoodPlan? foodPlan;

  AddFoodPlanScreen({this.foodPlan});

  @override
  _AddFoodPlanScreenState createState() => _AddFoodPlanScreenState();
}

class _AddFoodPlanScreenState extends State<AddFoodPlanScreen> {
  late TextEditingController _planNameController;
  List<Meal> meals = [];
  bool _isEditing = false;

  late ScrollController controller;
  bool fabIsVisible = true;

  Map<String, double> get _totalMacros {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (var meal in meals) {
      for (var food in meal.foods) {
        calories += food.adjustedCalories;
        protein += food.adjustedProtein;
        carbs += food.adjustedCarb;
        fat += food.adjustedFat;
      }
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
    controller.addListener(() {
      setState(() {
        fabIsVisible =
            controller.position.userScrollDirection == ScrollDirection.forward;
      });
    });

    _planNameController = TextEditingController(text: widget.foodPlan?.name ?? '');
    _isEditing = widget.foodPlan != null;
    _loadExistingPlan();
  }

  void _addNewMeal(String name) {
    setState(() => meals.add(Meal(name: name, foods: [])));
  }

  void _deleteMeal(int index) {
    setState(() => meals.removeAt(index));
  }

  Future<void> _loadExistingPlan() async {
    if (!_isEditing) {
      meals = [
        Meal(name: 'Breakfast', foods: []),
        Meal(name: 'Snack 1', foods: []),
        Meal(name: 'Lunch', foods: []),
        Meal(name: 'Snack 2', foods: []),
        Meal(name: 'Dinner', foods: []),
      ];
      return;
    }

    final dbHelper = DatabaseHelper();
    final existingMeals = await dbHelper.getMealsForPlan(widget.foodPlan!.id!);

    meals = await Future.wait(existingMeals.map((planMeal) async {
      final foods = await dbHelper.getFoodsForPlanMeal(planMeal.id!);
      return Meal(
        name: planMeal.mealType,
        foods: foods,
      );
    }));

    setState(() {});
  }

  Future<void> _addFoodToMeal(int mealIndex) async {
    final selectedFood = await Navigator.push<Food>(
      context,
      MaterialPageRoute(builder: (context) => SelectFoodScreen()),
    );

    if (selectedFood != null) {
      final adjustedFood = await Navigator.push<FoodWithServing>(
        context,
        MaterialPageRoute(
          builder: (context) => AdjustServingScreen(food: selectedFood, initialServing: selectedFood.servingSize,),
        ),
      );

      if (adjustedFood != null) {
        setState(() => meals[mealIndex].foods.add(adjustedFood));
      }
    }
  }

  Future<void> _savePlan() async {
    if (_planNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plan name is required')));
      return;
    }

    final dbHelper = DatabaseHelper();
    final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);

    final db = await dbHelper.database;
    await db.transaction((txn) async {
      if (_isEditing) {
        // Delete existing plan structure
        final mealIds = await txn.rawQuery(
            'SELECT id FROM plan_meals WHERE plan_id = ?',
            [widget.foodPlan!.id!]
        );

        for (final meal in mealIds) {
          await txn.delete(
            'plan_meal_food',
            where: 'meal_id = ?',
            whereArgs: [meal['id']],
          );
        }

        await txn.delete(
          'plan_meals',
          where: 'plan_id = ?',
          whereArgs: [widget.foodPlan!.id!],
        );

        // Update plan name
        await txn.update(
          'food_plans',
          {'name': _planNameController.text},
          where: 'id = ?',
          whereArgs: [widget.foodPlan!.id!],
        );
      }

      final planId = _isEditing ? widget.foodPlan!.id! :
      await txn.insert('food_plans', {
        'name': _planNameController.text
      });

      for (final meal in meals) {
        final mealId = await txn.insert('plan_meals', {
          'plan_id': planId,
          'meal_type': meal.name,
        });

        for (final foodWithServing in meal.foods) {
          await txn.insert('plan_meal_food', {
            'meal_id': mealId,
            'food_id': foodWithServing.food.id,
            'servingSize': foodWithServing.servingSize,
          });
        }
      }
    });

    mealPlanProvider.fetchFoodPlans();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final macros = _totalMacros;

    return WillPopScope(
      onWillPop: () async {
        // Check if there are any unsaved changes
        bool hasChanges = _checkForChanges();

        if (hasChanges) {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Unsaved Changes'),
              content: Text('Do you want to save your changes?'),
              actions: [
                TextButton(
                  onPressed: () {
                    // Cancel pop
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.white),),
                ),
                TextButton(
                  onPressed: () {
                    // Discard changes and pop
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Discard', style: TextStyle(color: Colors.red),),
                ),
                TextButton(
                  onPressed: () {
                    // Save changes and pop
                    _savePlan();
                  },
                  child: Text('Save', style: TextStyle(color: Colors.green),),
                ),
              ],
            ),
          ) ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _planNameController,
                decoration: InputDecoration(
                  hintText: 'Enter Plan Name',
                  border: InputBorder.none,
                ),
              ),
              _buildMacroSummary(macros),
            ],
          ),
          toolbarHeight: 150,
          actions: [
            IconButton(
              icon: Icon(Icons.save, size: 30,),
              onPressed: _savePlan,
            ),
          ],
        ),
        floatingActionButton: fabIsVisible ? FloatingActionButton(
          shape: CircleBorder(),
          onPressed: () => showDialog(
            context: context,
            builder: (context) {
              String newName = '';
              return AlertDialog(
                title: Text('New Meal'),
                content: TextField(
                  onChanged: (value) => newName = value,
                  decoration: InputDecoration(hintText: 'Meal name'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: Colors.white),),
                  ),
                  TextButton(
                    onPressed: () {
                      if (newName.isNotEmpty) {
                        _addNewMeal(newName);
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Add', style: TextStyle(color: Colors.green),),
                  ),
                ],
              );
            },
          ),
          backgroundColor: mainColor1,
          child: Icon(Icons.add),
        ) : null,
        body: ListView.builder(
          controller: controller,
          itemCount: meals.length,
          itemBuilder: (context, index) {
            final meal = meals[index];
            final totalCalories = meal.foods.fold(0.0, (sum, f) => sum + f.adjustedCalories);
            final totalProtein = meal.foods.fold(0.0, (sum, f) => sum + f.adjustedProtein);
            final totalCarbs = meal.foods.fold(0.0, (sum, f) => sum + f.adjustedCarb);
            final totalFat = meal.foods.fold(0.0, (sum, f) => sum + f.adjustedFat);

            return Card(
              margin: EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(meal.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteMeal(index),
                        ),
                      ],
                    ),

                    ...meal.foods.map((f) => Dismissible(
                      key: UniqueKey(),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        setState(() {
                          meal.foods.remove(f);
                        });
                      },
                      child: InkWell(
                        onTap: () async {
                          final adjustedFood = await Navigator.push<FoodWithServing>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdjustServingScreen(
                                food: f.food,
                                initialServing: f.servingSize,
                              ),
                            ),
                          );

                          if (adjustedFood != null) {
                            setState(() {
                              final foodIndex = meal.foods.indexOf(f);
                              meal.foods[foodIndex] = adjustedFood;
                            });
                          }
                        },
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                          title: Text(f.food.name),
                          subtitle: _buildFoodMacros(f),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${f.servingSize.toStringAsFixed(0)} ${f.food.measure}'),
                              SizedBox(height: 2),
                              Text(
                                '${f.adjustedCalories.toStringAsFixed(0)} kcal',
                                style: TextStyle(fontWeight: FontWeight.w500, color: CALS_COLOR),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )).toList(),
                    _buildModernAddButton(index),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildMealMacros(
                          totalCalories,
                          totalProtein,
                          totalCarbs,
                          totalFat
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _checkForChanges() {
    // Check if the plan name has changed
    bool nameChanged = widget.foodPlan == null
        ? _planNameController.text.isNotEmpty
        : _planNameController.text != widget.foodPlan!.name;

    // Check if there are any meals added
    bool mealsAdded = meals.any((meal) => meal.foods.isNotEmpty);

    // Check if the number of meals has changed from the original
    bool mealsChanged = widget.foodPlan == null
        ? meals.length > 5
        : meals.length != 5;

    return nameChanged || mealsAdded || mealsChanged;
  }

  Widget _buildMealMacros(double calories, double protein, double carbs, double fat) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / 4 - 8;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMacroItem('Protein', protein, PROTEIN_COLOR, itemWidth),
            _buildMacroItem('Carbs', carbs, CARBS_COLOR, itemWidth),
            _buildMacroItem('Fat', fat, FAT_COLOR, itemWidth),
            _buildMacroItem('Calories', calories, CALS_COLOR, itemWidth),
          ],
        );
      },
    );
  }

  Widget _buildMacroItem(String label, double value, Color color, double width) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSummary(Map<String, double> macros) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMacroChip('Protein', macros['protein']!, PROTEIN_COLOR, 'g'),
          _buildMacroChip('Carbs', macros['carbs']!, CARBS_COLOR, 'g'),
          _buildMacroChip('Fat', macros['fat']!, FAT_COLOR, 'g'),
          _buildMacroChip('Calories', macros['calories']!, CALS_COLOR, 'kcal'),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, double value, Color color, String unit) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodMacros(FoodWithServing food) {
    return Row(
      children: [
        _buildMacroPill('P', food.adjustedProtein, PROTEIN_COLOR),
        SizedBox(width: 6),
        _buildMacroPill('C', food.adjustedCarb, CARBS_COLOR),
        SizedBox(width: 6),
        _buildMacroPill('F', food.adjustedFat, FAT_COLOR),
      ],
    );
  }

  Widget _buildMacroPill(String label, double value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4),
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAddButton(int index) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton.icon(
        icon: Icon(Icons.add, size: 18, color: Colors.teal,),
        label: Text('Add Food'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.teal,
          side: BorderSide(color: Colors.teal.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        ),
        onPressed: () => _addFoodToMeal(index),
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text('${value.toStringAsFixed(1)} $unit'),
        ],
      ),
    );
  }
}