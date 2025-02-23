import 'package:flutter/material.dart';
import 'package:hor_fit/providers/workout_provider.dart';
import 'package:provider/provider.dart';

import '../../../utils/constants.dart';

class WeeklyMuscleOverviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<WorkoutProvider>(
          builder: (context, provider, child) {
            return FutureBuilder<Map<String, int>>(
              future: provider.getWeeklyMuscleOverview(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final muscleData = snapshot.data!;
                if (muscleData.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: Text('No muscles trained this week')),
                  );
                }

                return Column(
                  children: muscleData.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${entry.value} sets',
                                style: TextStyle(
                                  color: mainColor1,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: entry.value / (muscleData.values.reduce((a, b) => a > b ? a : b)),
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(mainColor1),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}