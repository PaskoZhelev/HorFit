import 'package:flutter/material.dart';
import 'package:hor_fit/models/food_models.dart';
import 'package:hor_fit/providers/food_provider.dart';
import 'package:hor_fit/screens/food/add_food_screen.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:provider/provider.dart';


class FoodListScreen extends StatefulWidget {
  @override
  _FoodListScreenState createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // Add focus node

  @override
  void initState() {
    super.initState();
    Provider.of<FoodProvider>(context, listen: false).fetchFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Foods'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Search Foods',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                    setState(() {  // Add this setState
                      searchQuery = '';  // Clear the search query
                    });
                  },
                )
                    : null,
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: Consumer<FoodProvider>(
        builder: (context, foodProvider, child) {
          final filteredFoods = foodProvider.foods.where((food) {
            return food.name.toLowerCase().contains(searchQuery);
          }).toList();

          return Padding(
            padding: EdgeInsets.all(8),
            child: ListView.builder(
              itemCount: filteredFoods.length,
              itemBuilder: (context, index) {
                final Food food = filteredFoods[index];

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  elevation: 1,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    minVerticalPadding: 0,
                    title: Text(
                      food.name,
                      style: TextStyle(fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildNutrientRow('Prot.', food.protein, PROTEIN_COLOR),
                          SizedBox(width: 4),
                          buildNutrientRow('Carb.', food.carbohydrate, CARBS_COLOR),
                          SizedBox(width: 4),
                          buildNutrientRow('Fat', food.fat, FAT_COLOR),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete,
                          color: Colors.red,
                          size: 20),
                      onPressed: () {
                        showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Confirm Deletion'),
                              content: Text('Are you sure you want to delete "${food.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel', style: TextStyle(color: Colors.white),),
                                ),
                                TextButton(
                                  onPressed: () {
                                    foodProvider.deleteFood(food.id!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Food "${food.name}" deleted')),
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddFoodScreen(existingFood: food),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddFoodScreen(existingFood: null),
            ),
          );
        },
        backgroundColor: mainColor1,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget buildNutrientRow(String name, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$name ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 10,
            )
        ),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}