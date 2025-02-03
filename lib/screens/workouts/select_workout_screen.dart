import 'package:flutter/material.dart';
import 'package:hor_fit/models/exercise_models.dart';
import 'package:hor_fit/providers/workout_provider.dart';
import 'package:hor_fit/screens/workouts/create_workout_plan_screen.dart';
import 'package:hor_fit/screens/workouts/workout_running_screen.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:provider/provider.dart';

class SelectWorkoutScreen extends StatefulWidget {
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
    provider.getWorkoutExerciseCount();
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
                  onTap: () => _startWorkout(context, workout),
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
    final logId = await provider.startWorkout(workout.id!);

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
}