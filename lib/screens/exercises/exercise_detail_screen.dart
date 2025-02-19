import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hor_fit/models/exercise_models.dart';
import 'package:provider/provider.dart';

import '../../providers/workout_provider.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final ExerciseWithMuscle exercise;

  const ExerciseDetailScreen({
    Key? key,
    required this.exercise,
  }) : super(key: key);

  @override
  _ExerciseDetailScreenState createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  List<ExerciseHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExerciseHistory();
  }

  Future<void> _loadExerciseHistory() async {
    try {
      final history = await Provider.of<WorkoutProvider>(context, listen: false)
          .getExerciseHistory(widget.exercise.id);
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading exercise history: $e');
      setState(() {
        _history = [];
        _isLoading = false;
      });
    }
  }

  double _getMaxWeight() {
    if (_history.isEmpty) return 0;
    return _history.map((h) => h.weight).reduce(max);
  }

  Widget _buildStatistics() {
    if (_history.isEmpty) return SizedBox.shrink();

    final maxWeight = _getMaxWeight();
    final lastWeight = _history.last.weight;
    final firstWeight = _history.first.weight;
    final progress = lastWeight - firstWeight;

    // Count unique workout sessions
    final uniqueSessions = _history.map((h) => h.workoutLogId).toSet().length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Personal Best', '${maxWeight.toStringAsFixed(1)} kg'),
                _buildStatItem('Progress',
                    '${progress >= 0 ? "+" : ""}${progress.toStringAsFixed(1)} kg'),
                _buildStatItem('Sessions', '$uniqueSessions'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressList() {
    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No history available for this exercise'),
        ),
      );
    }

    // Group sets by workout date
    final Map<DateTime, List<ExerciseHistory>> groupedSets = {};
    for (var history in _history) {
      final date = DateTime(
        history.date.year,
        history.date.month,
        history.date.day,
      );
      if (!groupedSets.containsKey(date)) {
        groupedSets[date] = [];
      }
      groupedSets[date]!.add(history);
    }

    final sortedDates = groupedSets.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Sort newest first

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final sets = groupedSets[date]!;
        final maxWeightForDay = sets.map((s) => s.weight).reduce(max);

        return Card(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Max: ${maxWeightForDay.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ...sets.map((set) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${set.weight.toStringAsFixed(1)} kg × ${set.reps} reps',
                    style: TextStyle(
                      color: Colors.grey[300],
                    ),
                  ),
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name,
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                margin: EdgeInsets.all(8),
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(
                    child: SizedBox(
                      height: 250,
                      child: Image.asset(
                        'assets/images/exercises/${widget.exercise.mediaId ?? 'default'}.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Muscle: ${widget.exercise.muscle}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else ...[
                _buildStatistics(),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildProgressList(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


