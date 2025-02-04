import 'package:flutter/material.dart';
import 'package:hor_fit/models/exercise_models.dart';
import 'package:hor_fit/providers/workout_provider.dart';
import 'package:hor_fit/screens/exercises/exercise_detail_screen.dart';
import 'package:hor_fit/screens/workouts/select_exercise_screen.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class WorkoutRunningScreen extends StatefulWidget {
  final Workout workout;
  final int workoutLogId;

  WorkoutRunningScreen({
    required this.workout,
    required this.workoutLogId,
  });

  @override
  _WorkoutRunningScreenState createState() => _WorkoutRunningScreenState();
}

class _WorkoutRunningScreenState extends State<WorkoutRunningScreen> {
  final List<WorkoutPlanExercise> _exercises = [];
  final Map<int, bool> _expandedState = {};
  Timer? _timer;
  final ValueNotifier<Duration> _durationNotifier = ValueNotifier(Duration.zero);
  bool _isKgUnit = true;

  var startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _startTimer();

    _loadWeightUnit();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadWeightUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isKgUnit = prefs.getBool('weightUnit') ?? true;
    });
  }

  void _startTimer() {
    _durationNotifier.value = DateTime.now().difference(startDate);
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _durationNotifier.value = DateTime.now().difference(startDate);
    });
  }

  Future<void> _loadExercises() async {
    final exerciseSets = await Provider.of<WorkoutProvider>(context, listen: false)
        .getWorkoutLogExercisesDetailed(widget.workoutLogId);

    setState(() => _exercises.addAll(exerciseSets));
  }

  Future<void> _finishWorkout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Finish Workout'),
        content: Text('Do you want to finish this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Finish'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Provider.of<WorkoutProvider>(context, listen: false)
          .finishWorkout(widget.workoutLogId, _exercises);
      Navigator.pop(context);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: ValueListenableBuilder<Duration>(
            valueListenable: _durationNotifier,
            builder: (context, duration, child) {
              return Text(_formatDuration(duration), style: TextStyle(fontWeight: FontWeight.bold)); // Only timer text updates, not the whole widget
            },
          ),
          actions: [
            TextButton(
              onPressed: _finishWorkout,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'FINISH',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
        Expanded(
        child: ReorderableListView.builder(
          itemCount: _exercises.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _exercises.removeAt(oldIndex);
              _exercises.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) => _buildExerciseCard(index, key: ValueKey(_exercises[index])),
        ),
      ),
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
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.teal, width: 2), // Green outline
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(Icons.check, color: Colors.teal),
                    label: Text('All', style: TextStyle(color: Colors.teal)),
                  ),
                  SizedBox(width: 12), // Space between buttons

                  // "Add Exercise" Button
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
                          MaterialPageRoute(builder: (context) => SelectExerciseScreen()),
                        );

                        if (exercise != null) {
                          setState(() {
                            _exercises.add(
                              WorkoutPlanExercise(
                                exercise: exercise,
                                sets: [WorkoutSet(setNumber: 1, weight: 0, reps: 0, isFinished: 0)],
                              ),
                            );
                          });
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add),
                          SizedBox(width: 8),
                          Text('Add Exercise', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Finish Workout'),
        content: Text('Do you want to finish this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Finish'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Provider.of<WorkoutProvider>(context, listen: false)
          .finishWorkout(widget.workoutLogId, _exercises);
      return true;
    }
    return false;
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
            title: Text(exercise.exercise.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                if (allSetsCompleted) ...[
                  Icon(Icons.check_circle, color: Colors.green, size: 18,),
                  SizedBox(width: 3),
                ],
                Text(
                  '${exercise.sets.where((set) => set.isFinished == 1).length}/${exercise.sets.length} sets',
                  style: TextStyle(color: allSetsCompleted ? Colors.green : Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
            trailing: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            onExpansionChanged: (expanded) {
              setState(() => _expandedState[exerciseIndex] = expanded);
            },
            children: [
              ...exercise.sets.asMap().entries.map((entry) {
                final setIndex = entry.key;
                final set = entry.value;
                final weightController = TextEditingController(text: set.weight.toString());
                final repsController = TextEditingController(text: set.reps.toString());
                final weightFocusNode = FocusNode();
                final repsFocusNode = FocusNode();

                return Dismissible(
                  key: Key('set_${exerciseIndex}_${setIndex}_${exercise.sets.length}'),
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
                    color: set.isFinished == 1 ? Colors.green.withOpacity(0.2) : null,
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
                          Transform.scale(
                            scale: 1.3,
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