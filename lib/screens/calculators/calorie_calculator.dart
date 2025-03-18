import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalorieCalculator extends StatefulWidget {
  @override
  _CalorieCalculatorState createState() => _CalorieCalculatorState();
}

class _CalorieCalculatorState extends State<CalorieCalculator> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String _calorieMessage = '';
  String maintenanceWeight = '';
  String mildWeightGain = '';
  String mildWeightLoss = '';
  String weightLoss = '';
  String weightGain = '';

  // Gender selection
  String _selectedGender = 'Male';

  // Activity level selection
  String _selectedActivityLevel = 'Sedentary';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // Load saved values for age, height, and weight from SharedPreferences
  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _ageController.text = prefs.getString('age') ?? '';
      _heightController.text = prefs.getString('height') ?? '';
      _weightController.text = prefs.getString('weight') ?? '';
    });
  }

  // Save values for age, height, and weight to SharedPreferences
  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('age', _ageController.text);
    prefs.setString('height', _heightController.text);
    prefs.setString('weight', _weightController.text);
  }

  // BMR Calculation using the Mifflin-St Jeor Equation
  double _calculateBMR() {
    double weight = double.tryParse(_weightController.text) ?? 0;
    double height = double.tryParse(_heightController.text) ?? 0;
    int age = int.tryParse(_ageController.text) ?? 0;

    if (_selectedGender == 'Male') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  // TDEE Calculation including activity level
  double _calculateTDEE() {
    double bmr = _calculateBMR();
    double activityMultiplier;

    switch (_selectedActivityLevel) {
      case 'Sedentary':
        activityMultiplier = 1.2;
        break;
      case 'Light: 1-3 times per week':
        activityMultiplier = 1.375;
        break;
      case 'Moderate: 4-5 times per week':
        activityMultiplier = 1.55;
        break;
      case 'Active: 6-7 times per week':
        activityMultiplier = 1.725;
        break;
      case 'Super Active: daily':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.2;
    }
    return bmr * activityMultiplier;
  }

  // Calculate Calories for weight maintenance, mild and standard weight loss/gain
  void _calculateCalories() {
    double tdee = _calculateTDEE();
    double maintenance = tdee;
    double weightLossMild = tdee - 250;   // 0.25 kg/week deficit
    double weightLossStandard = tdee - 500; // 0.5 kg/week deficit
    double weightGainMild = tdee + 250;     // 0.25 kg/week surplus
    double weightGainStandard = tdee + 500; // 0.5 kg/week surplus

    setState(() {
      maintenanceWeight = maintenance.toStringAsFixed(0);
      mildWeightGain = weightGainMild.toStringAsFixed(0);
      weightGain = weightGainStandard.toStringAsFixed(0);
      mildWeightLoss = weightLossMild.toStringAsFixed(0);
      weightLoss = weightLossStandard.toStringAsFixed(0);
      _calorieMessage = "Weight maintenance: ${maintenance.toStringAsFixed(0)} kcal/day";
      _calorieMessage += "\nMild Weight Loss (0.25 kg/week): ${weightLossMild.toStringAsFixed(0)} kcal/day";
      _calorieMessage += "\nWeight Loss (0.5 kg/week): ${weightLossStandard.toStringAsFixed(0)} kcal/day";
      _calorieMessage += "\nMild Weight Gain (0.25 kg/week): ${weightGainMild.toStringAsFixed(0)} kcal/day";
      _calorieMessage += "\nWeight Gain (0.5 kg/week): ${weightGainStandard.toStringAsFixed(0)} kcal/day";
    });

    // Save the current input values
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calorie Calculator'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Gender selection
              DropdownButton<String>(
                value: _selectedGender,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue!;
                  });
                },
                items: <String>['Male', 'Female']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              // Age input
              TextField(
                controller: _ageController,
                onTapOutside: (event) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  labelText: 'Age (years)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),

              // Height input
              TextField(
                controller: _heightController,
                onTapOutside: (event) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),

              // Weight input
              TextField(
                controller: _weightController,
                onTapOutside: (event) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),

              Text(
                "Activity Level:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              // Activity level selection
              DropdownButton<String>(
                value: _selectedActivityLevel,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedActivityLevel = newValue!;
                  });
                },
                items: <String>[
                  'Sedentary',
                  'Light: 1-3 times per week',
                  'Moderate: 4-5 times per week',
                  'Active: 6-7 times per week',
                  'Super Active: daily'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),

              // Calculate button
              ElevatedButton(
                onPressed: _calculateCalories,
                child: Text('Calculate Calories'),
              ),
              SizedBox(height: 20),

              // Display results
              if (maintenanceWeight.isNotEmpty)
                Card(
                  elevation: 4,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Weight Maintenance:",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '$maintenanceWeight kcal/day',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlue,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          "Mild Weight Gain (0.25 kg/week):",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '$mildWeightGain kcal/day',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          "Weight Gain (0.5 kg/week):",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '$weightGain kcal/day',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          "Mild Weight Loss (0.25 kg/week):",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '$mildWeightLoss kcal/day',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          "Weight Loss (0.5 kg/week):",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '$weightLoss kcal/day',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

