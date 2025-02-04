import 'package:flutter/material.dart';
import 'package:hor_fit/models/exercise_models.dart';
import 'package:hor_fit/providers/workout_provider.dart';
import 'package:hor_fit/screens/exercises/exercise_detail_screen.dart';
import 'package:hor_fit/screens/workouts/select_exercise_screen.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateWorkoutPlanScreen extends StatefulWidget {
  final Workout? workout;

  CreateWorkoutPlanScreen({this.workout});

  @override
  _CreateWorkoutPlanScreenState createState() => _CreateWorkoutPlanScreenState();
}

class _CreateWorkoutPlanScreenState extends State<CreateWorkoutPlanScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final List<WorkoutPlanExercise> _exercises = [];
  bool _isEditing = false;
  final Map<int, bool> _expandedState = {};
  bool _isKgUnit = true;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.workout != null;
    if (_isEditing) {
      _nameController.text = widget.workout!.name;
      _loadExistingWorkout();
    }

    _loadWeightUnit();
  }

  Future<void> _loadWeightUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isKgUnit = prefs.getBool('weightUnit') ?? true;
    });
  }

  Future<void> _loadExistingWorkout() async {
    final exerciseSets = await Provider.of<WorkoutProvider>(context, listen: false)
        .getWorkoutExercises(widget.workout!.id!);

    setState(() => _exercises.addAll(exerciseSets));
  }

  Future<void> _selectExercise() async {
    final exercise = await Navigator.push<ExerciseWithMuscle>(
      context,
      MaterialPageRoute(builder: (context) => SelectExerciseScreen()),
    );

    if (exercise != null) {
      setState(() {
        _exercises.add(WorkoutPlanExercise(exercise: exercise)..addSet());
      });
    }
  }

  Future<void> _saveWorkout() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a workout name')),
      );
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add at least one exercise')),
      );
      return;
    }

    // Ensure the exercises and sets are being correctly passed
    await Provider.of<WorkoutProvider>(context, listen: false).saveWorkout(
      name: _nameController.text,
      exercises: _exercises,
      workoutId: widget.workout?.id,
    );

    Provider.of<WorkoutProvider>(context, listen: false).loadWorkouts();
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Workout' : 'Create Workout Plan'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveWorkout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(),
        backgroundColor: mainColor1,
        onPressed: _selectExercise,
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
              onTap: () {
                _nameFocusNode.requestFocus();
              },
              decoration: InputDecoration(
                labelText: 'Workout Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _exercises.length,
              itemBuilder: (context, index) => _buildExerciseCard(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    bool isExpanded = _expandedState[exerciseIndex] ?? false;

    return Dismissible(
      key: Key('${exercise.exercise.id}_${exerciseIndex}'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() => _exercises.removeAt(exerciseIndex));
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: isExpanded,
            leading: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExerciseDetailScreen(
                      exercise: exercise.exercise,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 110,
                  height: 110,
                  color: Colors.white, // Set white background
                  child: Image.asset(
                    'assets/images/exercises/${exercise.exercise.mediaId ?? 'default'}.png',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            title: Text(exercise.exercise.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            subtitle: Text('${exercise.sets.length} sets', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            trailing: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            onExpansionChanged: (expanded) {
              setState(() => _expandedState[exerciseIndex] = expanded);
            },
              children: [
                ...exercise.sets.asMap().entries.map((entry) {
                  final setIndex = entry.key;
                  final set = entry.value;
                  final weightController = TextEditingController(text: set.weight.toString());
                  final weightFocusNode = FocusNode();
                  final repsFocusNode = FocusNode();
                  final repsController = TextEditingController(text: set.reps.toString());

                  return Dismissible(
                    key: Key('set_${exerciseIndex}_${setIndex}_${exercise.sets.length}'), // Updated key to be unique
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      setState(() {
                        exercise.sets.removeAt(setIndex);
                        // Update set numbers after removal
                        for (var i = 0; i < exercise.sets.length; i++) {
                          exercise.sets[i].setNumber = i + 1;
                        }
                      });

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {});
                      });
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text('Set ${setIndex + 1}'),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: weightController,
                              focusNode: weightFocusNode,
                              onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
                              style: TextStyle(fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                labelText: 'Weight',
                                suffixText: _isKgUnit ? 'kg' : 'lb',
                              ),
                              keyboardType: TextInputType.number,
                              onTap: () {
                                weightFocusNode.requestFocus();
                                weightController.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: weightController.text.length,
                                );
                              },
                              onChanged: (value) {
                                set.weight = double.tryParse(value) ?? 0;
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: repsController,
                              focusNode: repsFocusNode,
                              onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
                              style: TextStyle(fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                labelText: 'Reps',
                              ),
                              keyboardType: TextInputType.number,
                              onTap: () {
                                repsFocusNode.requestFocus();
                                repsController.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: repsController.text.length,
                                );
                              },
                              onChanged: (value) {
                                set.reps = int.tryParse(value) ?? 0;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => exercise.addSet());
                    },
                    icon: Icon(Icons.add),
                    label: Text('Add Set'),
                  ),
                ),
              ],
          ),
        ),
      ),
    );
  }

}
