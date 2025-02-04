import 'package:flutter/material.dart';
import 'package:hor_fit/models/exercise_models.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final ExerciseWithMuscle exercise;

  const ExerciseDetailScreen({
    Key? key,
    required this.exercise,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Exercise Image
              Card(
                margin: EdgeInsets.all(8),
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(
                    child: SizedBox(
                      height: 250,
                      child: Image.asset(
                        'assets/images/exercises/${exercise.mediaId ?? 'default'}.png',
                        fit: BoxFit.contain, // Large image with BoxFit.contain
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Muscle Name
              Text(
                'Muscle: ${exercise.muscle}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}