import 'package:flutter/material.dart';
import 'package:hor_fit/models/food_models.dart';
import 'package:hor_fit/utils/constants.dart';

class AdjustServingScreen extends StatefulWidget {
  final Food food;
  final double initialServing;

  AdjustServingScreen({
    required this.food,
    required this.initialServing,
  });

  @override
  _AdjustServingScreenState createState() => _AdjustServingScreenState();
}

class _AdjustServingScreenState extends State<AdjustServingScreen> {
  final TextEditingController _servingSizeController = TextEditingController();
  double _servingSize = 0.0;

  @override
  void initState() {
    super.initState();
    _servingSize = widget.initialServing;
    _servingSizeController.text = _servingSize.toStringAsFixed(1);
  }

  void _updateValues(String value) {
    final newSize = double.tryParse(value) ?? widget.food.servingSize;
    setState(() => _servingSize = newSize);
  }

  void _save() {
    if (_servingSize <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Serving size must be positive')));
      return;
    }
    Navigator.pop(
        context,
        FoodWithServing(
          food: widget.food,
          servingSize: _servingSize,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _servingSize / widget.food.servingSize;

    return Scaffold(
      appBar: AppBar(
        title: Text('Adjust Serving'),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _save)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                  textSelectionTheme:
                      TextSelectionThemeData(selectionColor: Colors.teal)),
              child: TextField(
                controller: _servingSizeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Serving Size (${widget.food.measure})',
                ),
                onChanged: _updateValues,
                onTap: () {
                  // Select all text in the TextField when tapped
                  _servingSizeController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _servingSizeController.text.length,
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            _buildNutrientRow('Calories',
                (widget.food.calories * ratio).toStringAsFixed(1), 'kcal', CALS_COLOR),
            _buildNutrientRow('Protein',
                (widget.food.protein * ratio).toStringAsFixed(1), 'g', PROTEIN_COLOR),
            _buildNutrientRow('Carbs',
                (widget.food.carbohydrate * ratio).toStringAsFixed(1), 'g', CARBS_COLOR),
            _buildNutrientRow(
                'Fat', (widget.food.fat * ratio).toStringAsFixed(1), 'g', FAT_COLOR),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value, String unit, Color selectedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text('$value $unit', style: TextStyle(color: selectedColor),),
        ],
      ),
    );
  }
}
