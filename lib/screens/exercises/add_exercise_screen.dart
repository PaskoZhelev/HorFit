import 'package:flutter/material.dart';
import 'package:hor_fit/models/exercise_models.dart';
import 'package:hor_fit/providers/exercises_provider.dart';
import 'package:provider/provider.dart';

class AddExerciseScreen extends StatefulWidget {
  @override
  _AddExerciseScreenState createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final TextEditingController _nameController = TextEditingController();
  int? selectedMuscleId;
  late Muscle selectedMuscle;
  List<Muscle> muscles = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Fetch muscles from Provider
    final provider = Provider.of<ExerciseProvider>(context, listen: false);
    muscles = provider.muscles;
    selectedMuscle = muscles[0];

    if (muscles.isNotEmpty && selectedMuscle == null) {
      selectedMuscle = muscles[0]; // Default selection
      selectedMuscleId = int.parse(selectedMuscle!.id);
    }

  }

  void _saveExercise() async {
    if (_nameController.text.isEmpty || selectedMuscleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a name and select a muscle.")),
      );
      return;
    }

    final newExercise = Exercise(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
      name: _nameController.text,
      typeId: 0,
      muscleId: selectedMuscleId!,
      equipmentId: 0,
      bodyPartId: 0,
      mediaId: null,
      ownType: 'custom',
    );

    final provider = Provider.of<ExerciseProvider>(context, listen: false);
    await provider.addExercise(newExercise);

    Navigator.pop(context); // Go back to the exercise list
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(title: Text('Add New Exercise')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Exercise Name'),
            ),
            const SizedBox(height: 20),

            // Check if muscles are available
            muscles.isEmpty
                ? CircularProgressIndicator() // Show a loading indicator if muscles are not loaded
                : DropdownButton<String>(
              value: selectedMuscle.name,
              hint: Text('Select Muscle'),
              isExpanded: true,
              items: muscles.map((muscle) {
                return DropdownMenuItem(
                  value: muscle.name,
                  child: Text(muscle.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedMuscle = muscles.firstWhere((muscle) => muscle.name == value);
                  selectedMuscleId = int.parse(selectedMuscle.id);
                });
              },
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveExercise,
              child: Text('Save Exercise', style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }
}