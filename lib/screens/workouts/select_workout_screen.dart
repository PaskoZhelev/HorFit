import 'package:flutter/material.dart';
import 'package:hor_fit/models/exercise_models.dart';
import 'package:hor_fit/providers/workout_provider.dart';
import 'package:hor_fit/screens/workouts/plans/create_workout_plan_screen.dart';
import 'package:hor_fit/screens/workouts/workout_running_screen.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:provider/provider.dart';

import 'log_completed_workout_screen.dart';

class SelectWorkoutScreen extends StatefulWidget {

  bool isNewWorkout = true;
  final DateTime? customStartDate;

  SelectWorkoutScreen({
    required this.isNewWorkout,
    this.customStartDate,
  });

  @override
  State<SelectWorkoutScreen> createState() => _SelectWorkoutScreenState();
}

class _SelectWorkoutScreenState extends State<SelectWorkoutScreen> {

  @override
  void initState() {
    super.initState();
    fetchWorkoutPlans(context);
  }

  void fetchWorkoutPlans(BuildContext context) async {
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    await provider.getWorkoutExerciseCount();
    await provider.loadWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Workout'),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          if (provider.workouts.isEmpty) {
            return Center(
              child: Text('No workout plans yet. Create one!'),
            );
          }

          return ListView.builder(
            itemCount: provider.workouts.length,
            itemBuilder: (context, index) {
              final workout = provider.workouts[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(workout.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),),
                  subtitle: Text('${provider.workoutExerciseCount[workout.id]} exercises', style: TextStyle(fontSize: 12)),
                  onTap: () {

                    if(widget.isNewWorkout)
                      {
                        _startWorkout(context, workout);
                      } else {
                      _startCompletedWorkout(context, workout);
                    }

                  }
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _startWorkout(BuildContext context, Workout workout) async {
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    final logId = await provider.startWorkoutKeepingOnlyWeights(workout.id!, null);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutRunningScreen(
          workout: workout,
          workoutLogId: logId,
        ),
      ),
    );
  }

  void _startCompletedWorkout(BuildContext context, Workout workout) async {
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    final logId = await provider.startWorkoutKeepingOnlyWeights(workout.id!, widget.customStartDate);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LogCompletedWorkoutScreen(
          workout: workout,
          workoutLogId: logId,
          workoutDate: widget.customStartDate!,
        ),
      ),
    );
  }
}