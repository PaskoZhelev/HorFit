import 'package:flutter/material.dart';
import 'package:hor_fit/database/database_helper.dart';
import 'package:hor_fit/models/exercise_models.dart';

class ExerciseProvider with ChangeNotifier {
  List<ExerciseWithMuscle> exercises = [];
  List<Muscle> muscles = [];

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> loadExercises() async {
    exercises = await _dbHelper.getExercisesWithMuscles();
    muscles = await _dbHelper.getMuscles();
    notifyListeners();
  }

  Future<void> addExercise(Exercise exercise) async {
    await _dbHelper.insertExercise(exercise);
    await loadExercises(); // Refresh the list after insertion
  }

  String getMuscleNameById(int id) {
    final muscle = muscles.firstWhere(
          (m) => int.parse(m.id) == id,
      orElse: () => Muscle(id: id.toString(), name: 'Unknown'),
    );
    return muscle.name;
  }

}