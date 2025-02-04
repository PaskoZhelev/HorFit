import 'package:flutter/material.dart';
import 'package:hor_fit/providers/exercises_provider.dart';
import 'package:hor_fit/screens/exercises/exercise_detail_screen.dart';
import 'package:provider/provider.dart';

class SelectExerciseScreen extends StatefulWidget {
  @override
  _SelectExerciseScreenState createState() => _SelectExerciseScreenState();
}

class _SelectExerciseScreenState extends State<SelectExerciseScreen> {
  String searchQuery = '';
  String? selectedMuscleId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExerciseProvider>(context, listen: false).loadExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Exercise'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
            ),
          ),
        ),
      ),
      body: Consumer<ExerciseProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text('All', style: TextStyle(fontWeight: FontWeight.bold)),
                        selected: selectedMuscleId == null,
                        onSelected: (_) {
                          setState(() {
                            selectedMuscleId = null;
                          });
                        },
                      ),
                    ),
                    ...provider.muscles.map((muscle) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(muscle.name, style: TextStyle(fontWeight: FontWeight.bold)),
                        selected: selectedMuscleId == muscle.id,
                        onSelected: (_) {
                          setState(() {
                            if(selectedMuscleId == muscle.id)
                            {
                              selectedMuscleId = null;
                            } else {
                              selectedMuscleId = muscle.id;
                            }

                          });
                        },
                      ),
                    )),
                  ],
                ),
              ),
              Expanded(
                child: _buildExercisesList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExercisesList(ExerciseProvider provider) {
    final exercises = provider.exercises.where((exercise) {
      bool matchesSearch = exercise.name.toLowerCase().contains(searchQuery);
      bool matchesMuscle = selectedMuscleId == null || exercise.muscleId.toString() == selectedMuscleId;
      return matchesSearch && matchesMuscle;
    }).toList();

    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(exercise.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            leading: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExerciseDetailScreen(
                      exercise: exercise,
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
                    'assets/images/exercises/${exercise.mediaId ?? 'default'}.png',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            subtitle: Text(provider.getMuscleNameById(exercise.muscleId), style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
            onTap: () => Navigator.pop(context, exercise),
          ),
        );
      },
    );
  }

}