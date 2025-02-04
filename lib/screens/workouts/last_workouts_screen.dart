import 'package:flutter/material.dart';
import 'package:hor_fit/providers/workout_provider.dart';
import 'package:hor_fit/screens/workouts/workout_log_history_screen.dart';
import 'package:provider/provider.dart';

class LastWorkoutsScreen extends StatefulWidget {
  const LastWorkoutsScreen({super.key});

  @override
  State<LastWorkoutsScreen> createState() => _LastWorkoutsScreenState();
}

class _LastWorkoutsScreenState extends State<LastWorkoutsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Last Workouts'),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: provider.getRecentWorkoutLogs(limit: 50),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final logs = snapshot.data!;

              if (logs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('No workout history yet'),
                );
              }

              return Column(
                children: logs
                    .map((log) => Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              WorkoutLogDetailScreen(
                                  workoutLog: log),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  log['workout_name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: Colors.white),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                            'Delete Workout Log'),
                                        content: Text(
                                            'Are you sure you want to delete this workout log?'),
                                        actions: [
                                          TextButton(
                                            child: Text('Cancel', style: TextStyle(color: Colors.white),),
                                            onPressed: () {
                                              Navigator.of(
                                                  context)
                                                  .pop();
                                            },
                                          ),
                                          TextButton(
                                            child: Text(
                                              'Delete',
                                              style: TextStyle(
                                                  color:
                                                  Colors.red),
                                            ),
                                            onPressed: () async {
                                              await provider
                                                  .deleteWorkoutLog(
                                                  log['id']);
                                              Navigator.of(
                                                  context)
                                                  .pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDateTime(
                                    log['start_date']),
                                style: TextStyle(
                                    color: Colors.grey[600]),
                              ),
                              Text(
                                _formatDuration(log['start_date'],
                                    log['end_date']),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
                    .toList(),
              );
            },
          );
        },
      ),
    );
  }

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
}
