import 'package:flutter/material.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:hor_fit/models/exercise_models.dart';
import 'package:hor_fit/providers/workout_provider.dart';
import 'package:hor_fit/screens/exercises/exercise_detail_screen.dart';
import 'package:hor_fit/screens/workouts/select_exercise_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditWorkoutLogScreen extends StatefulWidget {
  final Map<String, dynamic> workoutLog;

  EditWorkoutLogScreen({required this.workoutLog});

  @override
  _EditWorkoutLogScreenState createState() => _EditWorkoutLogScreenState();
}

class _EditWorkoutLogScreenState extends State<EditWorkoutLogScreen> {
  final List<WorkoutPlanExercise> _exercises = [];
  final Map<int, bool> _expandedState = {};
  bool _isKgUnit = true;
  bool _hasUnsavedChanges = false;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    startDate = DateTime.parse(widget.workoutLog['start_date']);
    endDate = DateTime.parse(widget.workoutLog['end_date']);
    _loadExercises();
    _loadWeightUnit();
  }

  Future<void> _loadWeightUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isKgUnit = prefs.getBool('weightUnit') ?? true;
    });
  }

  Future<void> _loadExercises() async {
    final exercises = await Provider.of<WorkoutProvider>(context, listen: false)
        .getWorkoutLogExercisesDetailed(widget.workoutLog['id']);
    setState(() => _exercises.addAll(exercises));
  }

  Future<void> _saveChanges() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save Changes'),
        content: Text('Do you want to save the changes to this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Save', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Provider.of<WorkoutProvider>(context, listen: false)
          .finishWorkout(widget.workoutLog['id'], _exercises, endDate);
      Navigator.pop(context, true);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unsaved Changes'),
        content: Text('Do you want to discard your changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit Workout'),
          actions: [
            TextButton(
              onPressed: _saveChanges,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'SAVE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Workout Time Details Card
            Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Start Time'),
                      trailing: TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDateTimePicker(
                            context: context,
                            initialDate: startDate!,
                          );
                          if (picked != null) {
                            setState(() {
                              startDate = picked;
                              _hasUnsavedChanges = true;
                            });
                          }
                        },
                        child: Text(
                          formatDateTime(startDate!),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text('End Time'),
                      trailing: TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDateTimePicker(
                            context: context,
                            initialDate: endDate!,
                          );
                          if (picked != null) {
                            setState(() {
                              endDate = picked;
                              _hasUnsavedChanges = true;
                            });
                          }
                        },
                        child: Text(
                          formatDateTime(endDate!),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Exercises List
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _exercises.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _exercises.removeAt(oldIndex);
                    _exercises.insert(newIndex, item);
                    _hasUnsavedChanges = true;
                  });
                },
                itemBuilder: (context, index) =>
                    _buildExerciseCard(index, key: ValueKey(_exercises[index])),
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        for (var exercise in _exercises) {
                          for (var set in exercise.sets) {
                            set.isFinished = 1;
                          }
                        }
                        _hasUnsavedChanges = true;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.green, width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(Icons.check, color: Colors.green),
                    label: Text('All', style: TextStyle(color: Colors.green)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final exercise = await Navigator.push<ExerciseWithMuscle>(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SelectExerciseScreen()),
                        );

                        if (exercise != null) {
                          setState(() {
                            _exercises.add(
                              WorkoutPlanExercise(
                                exercise: exercise,
                                sets: [
                                  WorkoutSet(
                                      setNumber: 1,
                                      weight: 0,
                                      reps: 0,
                                      isFinished: 0)
                                ],
                              ),
                            );
                            _hasUnsavedChanges = true;
                          });
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Add Exercise',
                              style: TextStyle(fontSize: 16, color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(int exerciseIndex, {required Key key}) {
    final exercise = _exercises[exerciseIndex];
    bool isExpanded = _expandedState[exerciseIndex] ?? false;
    bool allSetsCompleted = exercise.sets.every((set) => set.isFinished == 1);

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
            title: Text(exercise.exercise.name,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                if (allSetsCompleted) ...[
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 18,
                  ),
                  SizedBox(width: 3),
                ],
                Text(
                  '${exercise.sets.where((set) => set.isFinished == 1).length}/${exercise.sets.length} sets',
                  style: TextStyle(
                      color: allSetsCompleted
                          ? Colors.green
                          : Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
            trailing: Icon(isExpanded
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down, color: Colors.green,),
            onExpansionChanged: (expanded) {
              setState(() => _expandedState[exerciseIndex] = expanded);
            },
            children: [
              ...exercise.sets.asMap().entries.map((entry) {
                final setIndex = entry.key;
                final set = entry.value;
                final weightController =
                TextEditingController(text: set.weight.toCleanString());
                final repsController =
                TextEditingController(text: set.reps.toString());
                final weightFocusNode = FocusNode();
                final repsFocusNode = FocusNode();

                return Dismissible(
                  key: Key(
                      'set_${exerciseIndex}_${setIndex}_${exercise.sets.length}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() {
                      exercise.sets.removeAt(setIndex);
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
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: set.isFinished == 1
                          ? Colors.green.withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              '${setIndex + 1}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                controller: weightController,
                                focusNode: weightFocusNode,
                                onTapOutside: (event) => FocusManager
                                    .instance.primaryFocus
                                    ?.unfocus(),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  border: InputBorder.none,
                                  suffixText: _isKgUnit ? 'kg' : 'lb',
                                  suffixStyle: TextStyle(color: Colors.grey),
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                controller: repsController,
                                focusNode: repsFocusNode,
                                onTapOutside: (event) =>
                                    FocusManager.instance.primaryFocus?.unfocus(),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: InputBorder.none,
                                  suffixText: 'reps',
                                  suffixStyle: TextStyle(color: Colors.grey),
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
                          ),
                          Transform.scale(
                            scale: 1.1,
                            child: Checkbox(
                              value: set.isFinished == 1,
                              onChanged: (value) {
                                setState(() {
                                  set.isFinished = value! ? 1 : 0;
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              activeColor: Colors.green,
                              checkColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              Padding(
                padding: EdgeInsets.all(5),
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => exercise.addSet());
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.green, width: 1),
                    // Green outline
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: Icon(Icons.add, color: Colors.green),
                  label: Text('Add Set', style: TextStyle(color: Colors.green)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<DateTime?> showDateTimePicker({
  required BuildContext context,
  required DateTime initialDate,
}) async {
  final DateTime? date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  if (date == null) return null;

  final TimeOfDay? time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate),
  );

  if (time == null) return null;

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}

String formatDateTime(DateTime dateTime) {
  return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}
