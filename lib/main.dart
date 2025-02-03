import 'package:flutter/material.dart';
import 'package:hor_fit/providers/exercises_provider.dart';
import 'package:hor_fit/providers/meal_plan_provider.dart';
import 'package:hor_fit/providers/workout_provider.dart';
import 'package:hor_fit/utils/constants.dart';
import 'screens/home_screen.dart';

import 'package:provider/provider.dart';
import 'providers/daily_log_provider.dart';
import 'providers/food_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FoodProvider()),
        ChangeNotifierProvider(create: (_) => DailyLogProvider()),
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: darkTheme,
        home: HomeScreen()
      ),
    );
  }
}

