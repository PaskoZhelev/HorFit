import 'package:flutter/material.dart';
import 'package:hor_fit/database/database_helper.dart';
import 'package:hor_fit/screens/exercises/exercises_list_screen.dart';
import 'package:hor_fit/screens/food/food_list_screen.dart';
import 'package:hor_fit/screens/mealPlan/food_plan_list_screen.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isKgUnit = true;

  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadWeightUnit();
  }

  Future<void> _loadWeightUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isKgUnit = prefs.getBool('weightUnit') ?? true;
    });
  }

  Future<void> _toggleWeightUnit(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weightUnit', value);
    setState(() {
      isKgUnit = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
            children: [
              Card(
                margin: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FoodListScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Foods',
                              style: TextStyle(fontSize: 16),
                            ),
                            Spacer(),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FoodPlanListScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Meal Plans',
                              style: TextStyle(fontSize: 16),
                            ),
                            Spacer(),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                margin: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExerciseScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Exercises',
                              style: TextStyle(fontSize: 16),
                            ),
                            Spacer(),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                margin: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Weight Unit',
                            style: TextStyle(fontSize: 16),
                          ),
                          Row(
                            children: [
                              Text('lb'),
                              Switch(
                                value: isKgUnit,
                                onChanged: _toggleWeightUnit,
                                activeColor: mainColor1,
                              ),
                              Text('kg'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    InkWell(
                      onTap: () async {
                        await dbHelper.exportDatabase(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Export DB',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 4), // Small spacing between text elements
                                Text(
                                  'You can share the file to a folder using the file manager',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.6), // Lower opacity
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1),
                    InkWell(
                      onTap: () async {
                        await dbHelper.importDatabase(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Import DB',
                              style: TextStyle(fontSize: 16),
                            ),
                            Spacer(),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1),
                    InkWell(
                      onTap: () async {
                        showDialog(
                          context: context,
                          builder:
                              (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                  'Reset Database'),
                              content: Text(
                                  'Are you sure you want to reset the database to the initial state?'),
                              actions: [
                                TextButton(
                                  child: Text('Cancel', style: TextStyle(color: Colors.white),),
                                  onPressed: () {
                                    Navigator.of(
                                        context)
                                        .pop();
                                  },
                                ),
                                TextButton(
                                  child: Text(
                                    'Reset',
                                    style: TextStyle(
                                        color:
                                        Colors.red),
                                  ),
                                  onPressed: () async {
                                    await dbHelper.clickResetDatabase(context);

                                    Navigator.of(
                                        context)
                                        .pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Reset DB',
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                            Spacer(),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}