import 'package:flutter/material.dart';
import 'package:hor_fit/models/exercise_models.dart';
import 'package:hor_fit/providers/exercises_provider.dart';
import 'package:hor_fit/screens/exercises/add_exercise_screen.dart';
import 'package:hor_fit/screens/exercises/exercise_detail_screen.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:provider/provider.dart';

class ExerciseScreen extends StatefulWidget {
  @override
  _ExerciseScreenState createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  List<ExerciseWithMuscle> filteredExercises = [];
  String searchQuery = '';
  String? selectedMuscleId;
  String? selectedEquipment;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // Add focus node

  @override
  void initState() {
    super.initState();
    fetchExercises(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void fetchExercises(BuildContext context) async {
    final provider = Provider.of<ExerciseProvider>(context, listen: false);
    await provider.loadExercises();
    setState(() {
      filteredExercises = provider.exercises;
    });
  }

  void filterExercises(BuildContext context) {
    final provider = Provider.of<ExerciseProvider>(context, listen: false);
    setState(() {
      filteredExercises = provider.exercises.where((exercise) {
        //exact match
        //bool matchesSearch = exercise.name.toLowerCase().contains(searchQuery.toLowerCase());

        //approximate match
        List<String> searchWords = searchQuery.split(' ').map((word) => word.trim().toLowerCase()).toList();

        bool matchesSearch = searchWords.any((word) =>
            exercise.name.toLowerCase().contains(word)
        );
        if(searchQuery.isEmpty)
        {
          matchesSearch = true;
        }
        bool matchesMuscle = selectedMuscleId == null || exercise.muscleId.toString() == selectedMuscleId;
        bool matchesEquipment = selectedEquipment == null ||
            exercise.name.toLowerCase().contains(selectedEquipment!);
        return matchesSearch && matchesMuscle && matchesEquipment;
      }).toList();

    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExerciseProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Exercises')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                    setState(() {  // Add this setState
                      searchQuery = '';
                      filterExercises(context);
                    });
                  },
                ) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  filterExercises(context);
                });
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text('All', style: TextStyle(fontWeight: FontWeight.bold)),
                    selectedColor: Colors.teal,
                    selected: selectedMuscleId == null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: selectedMuscleId == null
                            ? Colors.teal
                            : Colors.grey.withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedMuscleId = null;
                        filterExercises(context);
                      });
                    },
                  ),
                ),
                ...provider.muscles.map((muscle) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(muscle.name, style: TextStyle(fontWeight: FontWeight.bold),),
                    selectedColor: Colors.teal,
                    selected: selectedMuscleId == muscle.id,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: selectedMuscleId == muscle.id
                            ? Colors.teal
                            : Colors.grey.withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() {
                        if(selectedMuscleId == muscle.id)
                        {
                          selectedMuscleId = null;
                        } else {
                          selectedMuscleId = muscle.id;
                        }

                        filterExercises(context);
                      });
                    },
                  ),
                )),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  for (final equipment in ['Barbell', 'Dumbbell', 'Machine'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(equipment, style: TextStyle(fontSize: 12),
                        ),
                        selectedColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selectedEquipment == equipment.toLowerCase()
                                ? Colors.teal
                                : Colors.grey.withValues(alpha: 0.4),
                            width: 0.5,
                          ),
                        ),
                        selected: selectedEquipment == equipment.toLowerCase(),
                        onSelected: (_) {
                          setState(() {
                            if (selectedEquipment == equipment.toLowerCase()) {
                              selectedEquipment = null;
                            } else {
                              selectedEquipment = equipment.toLowerCase();
                            }

                            filterExercises(context);
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = filteredExercises[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: ClipRRect(
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
                    title: Text(
                      exercise.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(exercise.muscle, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Floating Action Button to Create a New Exercise
      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(),
        backgroundColor: mainColor1,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddExerciseScreen()),
          ).then((_) => fetchExercises(context)); // Refresh the list after adding
        },
        child: Icon(Icons.add),
      ),
    );
  }
}