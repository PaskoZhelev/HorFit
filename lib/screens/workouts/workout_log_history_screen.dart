import 'package:flutter/material.dart';
import 'package:hor_fit/models/exercise_models.dart';
import 'package:hor_fit/providers/workout_provider.dart';
import 'package:provider/provider.dart';
import 'package:hor_fit/screens/exercises/exercise_detail_screen.dart';

class WorkoutLogDetailScreen extends StatelessWidget {
  final Map<String, dynamic> workoutLog;

  WorkoutLogDetailScreen({required this.workoutLog});

  String _formatDateTime(String dateTime) {
    final date = DateTime.parse(dateTime);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(String startDate, String endDate) {
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    final duration = end.difference(start);

    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(workoutLog['workout_name']),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Provider.of<WorkoutProvider>(context, listen: false)
            .getWorkoutLogDetails(workoutLog['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final exercises = snapshot.data!;

          return Column(
            children: [
              Card(
                margin: EdgeInsets.all(16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Started',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _formatDateTime(workoutLog['start_date']),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Duration',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _formatDuration(
                              workoutLog['start_date'],
                              workoutLog['end_date'],
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    final sets = exercise['sets'] as List<Map<String, dynamic>>;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ExerciseDetailScreen(
                                    exercise: ExerciseWithMuscle(
                                      id: exercise['id'],
                                      name: exercise['name'],
                                      typeId: exercise['type_id'],
                                      muscleId: exercise['muscle_id'],
                                      equipmentId: exercise['equipment_id'],
                                      bodyPartId: exercise['bodyPart_id'],
                                      mediaId: exercise['mediaId'],
                                      ownType: exercise['own_type'],
                                      priority: exercise['priority'],
                                      muscle: '',  // Add if available
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/exercises/${exercise['mediaId'] ?? 'default'}.png',
                                width: 120,
                                height: 90,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          title: Text(exercise['name']),
                          subtitle: Text('${sets.where((set) => set['is_finished'] == 1).length}/${sets.length} sets'),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Set',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Weight',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Reps',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Finished',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(),
                                  ...sets.map((set) => Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text('${set['set_number']}'),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text('${set['weight']}'),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text('${set['reps']}'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Icon(
                                            set['is_finished'] == 1
                                                ? Icons.check_circle_outline
                                                : Icons.cancel_outlined,
                                            color: set['is_finished'] == 1
                                                ? Colors.green
                                                : Colors.red,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}