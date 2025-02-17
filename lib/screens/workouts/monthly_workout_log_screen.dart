import 'package:flutter/material.dart';
import 'package:hor_fit/screens/workouts/workout_log_history_screen.dart';
import 'package:provider/provider.dart';
import 'package:hor_fit/providers/workout_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hor_fit/utils/constants.dart';

class MonthlyWorkoutLogScreen extends StatefulWidget {
  @override
  _MonthlyWorkoutLogScreenState createState() => _MonthlyWorkoutLogScreenState();
}

class _MonthlyWorkoutLogScreenState extends State<MonthlyWorkoutLogScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late DateTime _firstDay;
  late DateTime _lastDay;
  Set<DateTime> _workoutDates = {};

  @override
  void initState() {
    super.initState();
    _firstDay = DateTime(_focusedDay.year, _focusedDay.month - 12, 1);
    _lastDay = DateTime(_focusedDay.year, _focusedDay.month + 12, 0);
    _loadWorkoutDates();
  }

  Future<void> _loadWorkoutDates() async {
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    final dates = await provider.getWorkoutDatesForMonth(_focusedDay);
    setState(() {
      _workoutDates = dates;
    });
  }

  bool _hasWorkout(DateTime day) {
    return _workoutDates.contains(DateTime(day.year, day.month, day.day));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly Workout Log'),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Constrain the calendar height to prevent overflow
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: orientation == Orientation.portrait ? 400 : 250, // Adjust for landscape
                  ),
                  child: TableCalendar(
                    firstDay: _firstDay,
                    lastDay: _lastDay,
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month'
                    },
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                        _loadWorkoutDates();
                      });
                    },
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hasWorkout(day) ? Colors.green.withValues(alpha: 0.3) : Colors.transparent,
                          ),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: day.month == focusedDay.month ? Colors.white : Colors.grey,
                            ),
                          ),
                        );
                      },
                      selectedBuilder: (context, day, focusedDay) {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hasWorkout(day) ? Colors.green : mainColor1,
                          ),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hasWorkout(day)
                                ? Colors.green.withValues(alpha: 0.7)
                                : mainColor1.withValues(alpha: 0.7),
                          ),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Workout Logs Section (Scrollable)
                SizedBox(
                  height: orientation == Orientation.portrait ? 300 : 200, // Adjust size dynamically
                  child: Consumer<WorkoutProvider>(
                    builder: (context, provider, child) {
                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: provider.getWorkoutLogsForMonth(_focusedDay),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }

                          final logs = snapshot.data!;

                          if (logs.isEmpty) {
                            return Center(
                              child: Text('No workouts logged this month'),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: AlwaysScrollableScrollPhysics(),
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              final log = logs[index];
                              final startDate = DateTime.parse(log['start_date']);
                              final endDate = DateTime.parse(log['end_date']);
                              final duration = endDate.difference(startDate);

                              return InkWell(
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
                                child: Card(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    title: Text(log['workout_name']),
                                    subtitle: Text(
                                      '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year} - ${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}',
                                    ),
                                    trailing: Text(
                                      '${duration.inHours}h ${duration.inMinutes % 60}m',
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}