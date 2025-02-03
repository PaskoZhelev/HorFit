import 'package:flutter/material.dart';
import 'package:hor_fit/screens/workouts/workout_overview_screen.dart';
import 'package:hor_fit/screens/workouts/workout_plans_screen.dart';

class WorkoutMainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Workouts'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Workout Plans'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            WorkoutOverviewScreen(),
            WorkoutPlansScreen(),
          ],
        ),
      ),
    );
  }
}