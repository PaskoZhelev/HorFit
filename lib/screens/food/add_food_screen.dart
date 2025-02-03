import 'package:flutter/material.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:provider/provider.dart';
import '../../models/food_models.dart';
import '../../providers/food_provider.dart';

class AddFoodScreen extends StatefulWidget {
  final Food? existingFood; // If editing a food, pass it here

  AddFoodScreen({this.existingFood});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController calorieController = TextEditingController();
  final TextEditingController servingSizeController = TextEditingController(text: "100");
  final TextEditingController measureController = TextEditingController(text: "grams");
  final TextEditingController fatController = TextEditingController();
  final TextEditingController proteinController = TextEditingController();
  final TextEditingController carbController = TextEditingController();

  // Focus nodes to manage focus for text fields
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode calorieFocusNode = FocusNode();
  final FocusNode servingSizeFocusNode = FocusNode();
  final FocusNode measureFocusNode = FocusNode();
  final FocusNode fatFocusNode = FocusNode();
  final FocusNode proteinFocusNode = FocusNode();
  final FocusNode carbFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.existingFood != null) {
      // Populate controllers if editing
      nameController.text = widget.existingFood!.name;
      calorieController.text = widget.existingFood!.calories.toString();
      servingSizeController.text = widget.existingFood!.servingSize.toString();
      measureController.text = widget.existingFood!.measure;
      fatController.text = widget.existingFood!.fat.toString();
      proteinController.text = widget.existingFood!.protein.toString();
      carbController.text = widget.existingFood!.carbohydrate.toString();
    }
  }

  // Helper function to create each row
  Widget _buildRow(String label, TextEditingController controller, String iconName, TextInputType textInput, {Color labelColor = Colors.white, FocusNode? focusNode}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Label (bold) on the left
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: labelColor,
            ),
          ),
        ),
        // Input field with value aligned to the very right
        Container(
          width: 150, // Adjust width as needed
          child: Align(
            alignment: Alignment.centerRight,
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.right, // Align input text to the right
              decoration: InputDecoration(
                border: InputBorder.none, // No border
                isDense: true, // Reduces padding
                contentPadding: EdgeInsets.all(5), // No extra padding inside
              ),
              keyboardType: textInput,
              validator: (value) => value == null || value.isEmpty ? 'Enter a value' : null,
              onTap: () {
                // Select all text when the field is tapped
                controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: controller.text.length,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Function to save the food data
  void _saveFood() {
    if (_formKey.currentState!.validate()) {
      var currType = 'custom';
      if(widget.existingFood != null)
      {
        currType = widget.existingFood!.type;
      }

      final food = Food(
        id: widget.existingFood?.id,
        name: nameController.text,
        calories: double.parse(calorieController.text),
        servingSize: double.parse(servingSizeController.text),
        measure: measureController.text,
        fat: double.parse(fatController.text),
        protein: double.parse(proteinController.text),
        carbohydrate: double.parse(carbController.text),
        type: currType,
      );

      if (widget.existingFood == null) {
        // Adding a new food
        Provider.of<FoodProvider>(context, listen: false).addFood(food);
      } else {
        // Updating existing food
        Provider.of<FoodProvider>(context, listen: false).updateFood(food);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingFood == null ? 'Add Food' : 'Edit Food', style: TextStyle(color: Colors.white),),
        actions: [
          // Save icon in the top right
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveFood, // Calls the _saveFood function when tapped
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRow('Food Name', nameController, 'food', TextInputType.text, focusNode: nameFocusNode),
                      Divider(color: Colors.grey.withValues(alpha: 0.2)),
                      _buildRow('Serving Size', servingSizeController, 'food_bank', TextInputType.number, focusNode: servingSizeFocusNode),
                      Divider(color: Colors.grey.withValues(alpha: 0.2)),
                      _buildRow('Measure (e.g., grams, cup)', measureController, 'scale', TextInputType.text, focusNode: measureFocusNode),
                      Divider(color: Colors.grey.withValues(alpha: 0.2)),
                      _buildRow('Calories (kcal)', calorieController, 'local_fire_department', TextInputType.number, focusNode: calorieFocusNode, labelColor: CALS_COLOR),
                      Divider(color: Colors.grey.withValues(alpha: 0.2)),
                      _buildRow('Protein (g)', proteinController, 'egg', TextInputType.number, labelColor: PROTEIN_COLOR, focusNode: proteinFocusNode),
                      Divider(color: Colors.grey.withValues(alpha: 0.2)),
                      _buildRow('Carbohydrates (g)', carbController, 'local_pizza', TextInputType.number, labelColor: CARBS_COLOR, focusNode: carbFocusNode),
                      Divider(color: Colors.grey.withValues(alpha: 0.2)),
                      _buildRow('Fat (g)', fatController, 'egg_alt', TextInputType.number, labelColor: FAT_COLOR, focusNode: fatFocusNode),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveFood,
                label: Text('Save', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: mainColor1, // The button background
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


