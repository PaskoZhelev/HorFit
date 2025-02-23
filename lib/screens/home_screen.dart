import 'package:flutter/material.dart';
import 'package:hor_fit/screens/dailyLog/daily_log_screen.dart';
import 'package:hor_fit/screens/exercises/exercises_list_screen.dart';
import 'package:hor_fit/screens/food/food_list_screen.dart';
import 'package:hor_fit/screens/mealPlan/food_plan_list_screen.dart';
import 'package:hor_fit/screens/settings/settings_screen.dart';
import 'package:hor_fit/screens/workouts/workout_main_screen.dart';
import 'package:hor_fit/screens/workouts/plans/workout_plans_screen.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    WorkoutMainScreen(),
    DailyLogsScreen(),
    SettingsScreen()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.white54,
        selectedFontSize: 13,
        unselectedFontSize: 12,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Meal Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
