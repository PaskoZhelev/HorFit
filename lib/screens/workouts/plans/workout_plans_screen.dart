import 'package:flutter/material.dart';
import 'package:hor_fit/models/exercise_models.dart';
import 'package:hor_fit/providers/workout_provider.dart';
import 'package:hor_fit/screens/workouts/plans/create_workout_plan_screen.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:provider/provider.dart';

class WorkoutPlansScreen extends StatefulWidget {

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {

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
        title: Text('Workout Plans'),
      ),
      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(),
        backgroundColor: mainColor1,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateWorkoutPlanScreen(),
            ),
          );
        },
        child: Icon(Icons.add),
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
                  title: Text(workout.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                  subtitle: Text('${provider.workoutExerciseCount[workout.id]} exercises', style: TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, workout),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateWorkoutPlanScreen(
                          workout: workout,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Workout workout) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Workout'),
        content: Text('Are you sure you want to delete "${workout.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Provider.of<WorkoutProvider>(context, listen: false)
          .deleteWorkout(workout.id!);
    }
  }
}