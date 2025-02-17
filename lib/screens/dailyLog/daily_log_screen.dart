import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hor_fit/models/food_models.dart';
import 'package:hor_fit/providers/daily_log_provider.dart';
import 'package:hor_fit/providers/meal_plan_provider.dart';
import 'package:hor_fit/screens/mealPlan/adjust_serving_screen.dart';
import 'package:hor_fit/screens/mealPlan/select_food_screen.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DailyLogsScreen extends StatefulWidget {
  @override
  _DailyLogScreenState createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogsScreen> {
  late ScrollController _scrollController;
  bool fabIsVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {
        fabIsVisible = _scrollController.position.userScrollDirection == ScrollDirection.forward;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DailyLogProvider>(context, listen: false).loadDailyLog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<DailyLogProvider>(
          builder: (context, provider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left),
                      onPressed: () {
                        final newDate = provider.currentDate.subtract(Duration(days: 1));
                        provider.changeDate(newDate);
                      },
                    ),
                    Text(DateFormat('MMM d, yyyy').format(provider.currentDate)),
                    IconButton(
                      icon: Icon(Icons.chevron_right),
                      onPressed: () {
                        final newDate = provider.currentDate.add(Duration(days: 1));
                        provider.changeDate(newDate);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8),
                _buildMacroSummary(provider.calculateDailyTotals()),
              ],
            );
          },
        ),
        toolbarHeight: 120,
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () => _importFromMealPlan(context),
            tooltip: 'Import from meal plan',
          ),
        ],
      ),
      floatingActionButton: fabIsVisible ? FloatingActionButton(
        shape: CircleBorder(),
        onPressed: () async {
          String? mealType;

          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('New Meal'),
              content: TextField(
                decoration: InputDecoration(hintText: 'Meal name'),
                onChanged: (value) => mealType = value,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () {
                    if (mealType != null && mealType!.isNotEmpty) {
                      Navigator.pop(context, mealType);
                    }
                  },
                  child: Text('Add', style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          );

          if (mealType != null && mealType!.isNotEmpty) {
            await Provider.of<DailyLogProvider>(context, listen: false)
                .addMealType(mealType!, context.read<DailyLogProvider>().currentLog!.id!);
          }
        },
        backgroundColor: mainColor1,
        child: Icon(Icons.add),
      ) : null,
      body: Consumer<DailyLogProvider>(
        builder: (context, provider, child) {
          if (provider.currentLog == null) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: provider.currentLog!.meals.length,
            itemBuilder: (context, index) {
              final meal = provider.currentLog!.meals[index];
              return _buildMealCard(context, meal);
            },
          );
        },
      ),
    );
  }

  Future<void> _importFromMealPlan(BuildContext context) async {
    final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);
    await mealPlanProvider.fetchFoodPlans();

    final selectedPlan = await showDialog<FoodPlan>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import from Meal Plan', style: TextStyle(fontSize: 15)),
        content: Container(
          width: double.maxFinite,
          child: Consumer<MealPlanProvider>(
            builder: (context, provider, child) {
              if (provider.foodPlans.isEmpty) {
                return Center(child: Text('No meal plans available'));
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: provider.foodPlans.length,
                itemBuilder: (context, index) {
                  final plan = provider.foodPlans[index];
                  return ListTile(
                    title: Text(plan.name),
                    onTap: () => Navigator.pop(context, plan),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (selectedPlan != null) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await Provider.of<DailyLogProvider>(context, listen: false)
            .importFromMealPlan(selectedPlan.id!);

        // Hide loading indicator
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Meal plan imported successfully')),
        );
      } catch (e) {
        // Hide loading indicator
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import meal plan')),
        );
      }
    }
  }

  Future<void> _deleteMealType(BuildContext context, DailyMeal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Meal Type'),
        content: Text('Are you sure you want to delete "${meal.mealType}"? This will also delete all foods in this meal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Provider.of<DailyLogProvider>(context, listen: false)
          .deleteMealType(meal.id!);
    }
  }

  Future<void> _addFoodToMeal(BuildContext context, int mealId) async {
    final selectedFood = await Navigator.push<Food>(
      context,
      MaterialPageRoute(builder: (context) => SelectFoodScreen()),
    );

    if (selectedFood != null) {
      final adjustedFood = await Navigator.push<FoodWithServing>(
        context,
        MaterialPageRoute(
          builder: (context) => AdjustServingScreen(
            food: selectedFood,
            initialServing: selectedFood.servingSize,
          ),
        ),
      );

      if (adjustedFood != null) {
        // Now using the adjusted serving size instead of the default serving size
        await Provider.of<DailyLogProvider>(context, listen: false)
            .addFoodToMeal(mealId, selectedFood, adjustedFood.servingSize);
      }
    }
  }

  Widget _buildMealCard(BuildContext context, DailyMeal meal) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var food in meal.foods) {
      totalCalories += food.adjustedCalories;
      totalProtein += food.adjustedProtein;
      totalCarbs += food.adjustedCarb;
      totalFat += food.adjustedFat;
    }

    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  meal.mealType,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.white),
                  onPressed: () => _deleteMealType(context, meal),
                  tooltip: 'Delete meal type',
                ),
              ],
            ),
            SizedBox(height: 8),
            ...meal.foods.map((food) => Dismissible(
              key: ValueKey('${meal.id}-${food.food.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                color: Colors.red,
                child: Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                Provider.of<DailyLogProvider>(context, listen: false)
                    .removeFoodFromMeal(meal.id!, food.food.id!);
              },
              child: ListTile(
                dense: true,
                title: Text(food.food.name),
                subtitle: _buildFoodMacros(food),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${food.servingSize.toStringAsFixed(0)} ${food.food.measure}'),
                    SizedBox(height: 2),
                    Text(
                      '${food.adjustedCalories.toStringAsFixed(0)} kcal',
                      style: TextStyle(fontWeight: FontWeight.w500, color: CALS_COLOR),
                    ),
                  ],
                ),
                onTap: () async {
                  final adjustedFood = await Navigator.push<FoodWithServing>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdjustServingScreen(
                        food: food.food,
                        initialServing: food.servingSize,
                      ),
                    ),
                  );

                  if (adjustedFood != null) {
                    Provider.of<DailyLogProvider>(context, listen: false)
                        .updateFoodServing(meal.id!, food.food.id!, adjustedFood.servingSize);
                  }
                },
              ),
            )).toList(),
            _buildAddFoodButton(meal.id!),
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: _buildMealMacros(totalCalories, totalProtein, totalCarbs, totalFat),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFoodButton(int mealId) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton.icon(
        icon: Icon(Icons.add, size: 18, color: Colors.teal),
        label: Text('Add Food'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.teal,
          side: BorderSide(color: Colors.teal.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        ),
        onPressed: () => _addFoodToMeal(context, mealId),
      ),
    );
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

  // Modern Macro Item in Meal Card
  Widget _buildMacroItem(String label, double value, Color color, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSummary(Map<String, double> macros) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 4),
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

}