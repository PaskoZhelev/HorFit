import 'package:flutter/material.dart';
import 'package:hor_fit/models/food_models.dart';
import 'package:hor_fit/providers/food_provider.dart';
import 'package:provider/provider.dart';

class SelectFoodScreen extends StatefulWidget {
  @override
  _SelectFoodScreenState createState() => _SelectFoodScreenState();
}

class _SelectFoodScreenState extends State<SelectFoodScreen> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load foods when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FoodProvider>(context, listen: false).fetchFoods();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Food'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Foods',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                  },
                ),
              ),
              onChanged: (query) => setState(() => searchQuery = query.toLowerCase()),
            ),
          ),
        ),
      ),
      body: Consumer<FoodProvider>(
        builder: (context, foodProvider, child) {
          if (foodProvider.foods.isEmpty) {
            return Center(child: Text('No foods found. Add some first!'));
          }

          final filteredFoods = foodProvider.foods.where((food) {
            return food.name.toLowerCase().contains(searchQuery);
          }).toList();

          return ListView.builder(
            itemCount: filteredFoods.length,
            itemBuilder: (context, index) {
              final food = filteredFoods[index];
              return ListTile(
                title: Text(food.name),
                subtitle: Text(
                    '${food.calories} kcal • '
                        'P: ${food.protein}g • '
                        'C: ${food.carbohydrate}g • '
                        'F: ${food.fat}g'
                ),
                onTap: () => Navigator.pop(context, food),
              );
            },
          );
        },
      ),
    );
  }
}