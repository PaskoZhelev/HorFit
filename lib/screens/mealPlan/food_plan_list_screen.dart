import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hor_fit/models/food_models.dart';
import 'package:hor_fit/providers/meal_plan_provider.dart';
import 'package:hor_fit/screens/mealPlan/add_food_plan_screen.dart';
import 'package:hor_fit/utils/constants.dart';

class FoodPlanListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);

    // Fetch plans when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mealPlanProvider.fetchFoodPlans();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Plans'),
      ),
      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddFoodPlanScreen()),
        ).then((_) => mealPlanProvider.fetchFoodPlans()),
        backgroundColor: mainColor1,
        child: Icon(Icons.add),
      ),
      body: Consumer<MealPlanProvider>(
        builder: (context, provider, child) {
          if (provider.foodPlans.isEmpty) {
            return Center(
              child: Text('No meal plans found. Tap + to create one!'),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: provider.foodPlans.length,
            itemBuilder: (context, index) {
              final plan = provider.foodPlans[index];
              return FutureBuilder<Map<String, double>>(
                future: provider.calculateMealPlanMacros(plan.id!),
                builder: (context, snapshot) {
                  return InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFoodPlanScreen(foodPlan: plan),
                      ),
                    ).then((_) => provider.fetchFoodPlans()),
                    child: _buildPlanCard(
                      context: context,
                      plan: plan,
                      macros: snapshot.data,
                      isLoading: !snapshot.hasData,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required FoodPlan plan,
    required Map<String, double>? macros,
    required bool isLoading,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 20, color: Colors.white),
                  onPressed: () => _deletePlan(context, plan),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / 4 - 8;
                return isLoading
                    ? _buildLoadingGrid(itemWidth)
                    : _buildMacroGrid(macros!, itemWidth);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroGrid(Map<String, double> macros, double itemWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMacroItem('Protein', macros['protein']!, PROTEIN_COLOR, itemWidth),
        _buildMacroItem('Carbs', macros['carbs']!, CARBS_COLOR, itemWidth),
        _buildMacroItem('Fat', macros['fat']!, FAT_COLOR, itemWidth),
        _buildMacroItem('Calories', macros['calories']!, CALS_COLOR, itemWidth),
      ],
    );
  }

  Widget _buildMacroItem(String label, double value, Color color, double width) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toStringAsFixed(value < 1 ? 1 : 0),
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

  Widget _buildLoadingGrid(double itemWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (index) => SizedBox(
        width: itemWidth,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 16,
              color: Colors.grey[200],
            ),
            SizedBox(height: 4),
            Container(
              width: 30,
              height: 12,
              color: Colors.grey[200],
            ),
          ],
        ),
      )),
    );
  }

  void _deletePlan(BuildContext context, FoodPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Plan?'),
        content: Text('Are you sure you want to delete "${plan.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white),),
          ),
          TextButton(
            onPressed: () {
              Provider.of<MealPlanProvider>(context, listen: false)
                  .deletePlan(plan.id!);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}