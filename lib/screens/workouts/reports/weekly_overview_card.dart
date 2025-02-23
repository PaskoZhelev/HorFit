import 'package:flutter/material.dart';
import 'package:hor_fit/providers/workout_provider.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:provider/provider.dart';

class WeeklyOverviewCard extends StatefulWidget {
  @override
  _WeeklyOverviewCardState createState() => _WeeklyOverviewCardState();
}

class _WeeklyOverviewCardState extends State<WeeklyOverviewCard> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>>? _selectedDayWorkouts;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekDays.map((date) {
                return Column(
                  children: [
                    Text(
                      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Consumer<WorkoutProvider>(
                      builder: (context, provider, child) {
                        return FutureBuilder<bool>(
                          future: provider.hasWorkoutOnDate(date),
                          builder: (context, snapshot) {
                            final hasWorkout = snapshot.data ?? false;

                            return GestureDetector(
                              onTap: () async {
                                setState(() {
                                  _selectedDate = date;
                                  _selectedDayWorkouts = null;
                                });
                                final workouts = await provider.getWorkoutLogsForDate(date);
                                setState(() {
                                  _selectedDayWorkouts = workouts;
                                });
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hasWorkout ? mainColor1 : Colors.white10,
                                ),
                                child: Center(
                                  child: Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      color: hasWorkout ? Colors.white : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
            if (_selectedDayWorkouts != null) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              if (_selectedDayWorkouts!.isEmpty)
                Text('No workouts on this day')
              else
                Column(
                  children: _selectedDayWorkouts!.map((workout) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(workout['workout_name']),
                          Text(_formatDuration(
                            workout['start_date'],
                            workout['end_date'],
                          )),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ],
        ),
      ),
    );
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