import 'package:flutter/material.dart';
import 'package:hor_fit/providers/workout_provider.dart';
import 'package:hor_fit/screens/workouts/plans/workout_plans_screen.dart';
import 'package:hor_fit/screens/workouts/reports/last_workouts_screen.dart';
import 'package:hor_fit/screens/workouts/reports/monthly_workout_log_screen.dart';
import 'package:hor_fit/screens/workouts/select_workout_screen.dart';
import 'package:hor_fit/screens/workouts/reports/weekly_muscle_overview_card.dart';
import 'package:hor_fit/screens/workouts/reports/weekly_overview_card.dart';
import 'package:hor_fit/screens/workouts/reports/workout_log_history_screen.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:provider/provider.dart';

import '../../utils/date_picker_dialog.dart';

class WorkoutOverviewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Workouts Overview')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectWorkoutScreen(isNewWorkout: true),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mainColor1.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: mainColor1,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start New Workout',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Start logging workout from existing workout plan',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 5),

              Card(
                child: InkWell(
                  onTap: () async {
                    final selectedDate = await showDialog<DateTime>(
                      context: context,
                      builder: (context) => DateSelectionDialog(),
                    );

                    if (selectedDate != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectWorkoutScreen(
                            isNewWorkout: false,
                            customStartDate: selectedDate,
                          ),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.history,
                            color: Colors.orange,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Log Completed Workout',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Add a workout from a previous date',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 5),

              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutPlansScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.app_registration,
                            color: Colors.deepPurpleAccent,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Workout Plans',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Create or edit your workout plans',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 15),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MonthlyWorkoutLogScreen(),
                    ),
                  );
                },
                child: Text(
                  'Weekly Overview',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MonthlyWorkoutLogScreen(),
                      ),
                    );
                  },
                  child: WeeklyOverviewCard()
              ),
              SizedBox(height: 24),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LastWorkoutsScreen(),
                    ),
                  );
                },
                child: Text(
                  'Last Workouts',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Consumer<WorkoutProvider>(
                builder: (context, provider, child) {
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: provider.getRecentWorkoutLogs(),
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
                              padding: const EdgeInsets.all(8.0),
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

              SizedBox(height: 24),
              Text(
                'Muscles Trained This Week',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              WeeklyMuscleOverviewCard(),

            ],
          ),
        ),
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
