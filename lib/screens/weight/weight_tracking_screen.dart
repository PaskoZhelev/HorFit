import 'package:flutter/material.dart';
import 'package:hor_fit/database/database_helper.dart';
import 'package:hor_fit/models/weight_models.dart';
import 'package:hor_fit/utils/constants.dart';
import 'package:intl/intl.dart';

class WeightTrackingPage extends StatefulWidget {
  @override
  _WeightTrackingPageState createState() => _WeightTrackingPageState();
}

class _WeightTrackingPageState extends State<WeightTrackingPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weight Tracking'),
      ),
      body: FutureBuilder<List<WeightRecord>>(
        future: _dbHelper.getWeightRecords(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final record = snapshot.data![index];
              return ListTile(
                title: Text('${record.weight} kg'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(record.date), style: TextStyle(color: Colors.grey[600])),
                    Text(record.notes!, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit button
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        _showEditWeightDialog(record);
                      },
                    ),
                    // Delete button
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Delete Weight Record'),
                              content: Text('Are you sure you want to delete this weight record?'),
                              actions: [
                                TextButton(
                                  child: Text('Cancel', style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                  onPressed: () async {
                                    await _dbHelper.deleteWeight(record.id!);
                                    setState(() {});
                                    Navigator.of(context).pop();
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
              );
            },
          );
        },
      ),
      // Floating button to show the add weight dialog
      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(),
        backgroundColor: mainColor1,
        onPressed: _showAddWeightDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddWeightDialog() async {
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Add Weight Record'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Weight input
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Weight'),
                    ),
                    // Notes input
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(labelText: 'Notes'),
                    ),
                    SizedBox(height: 8),
                    // Date selection row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}",
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                // Cancel button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.white)),
                ),
                // Save button
                ElevatedButton(
                  onPressed: () async {
                    if (weightController.text.isNotEmpty) {
                      double weightValue = double.parse(weightController.text);
                      final newRecord = WeightRecord(
                        weight: weightValue,
                        date: selectedDate,
                        notes: notesController.text,
                      );
                      await _dbHelper.insertWeight(newRecord);
                      Navigator.pop(context);
                      setState(() {});
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditWeightDialog(WeightRecord record) async {
    final weightController =
    TextEditingController(text: record.weight.toString());
    final notesController = TextEditingController(text: record.notes);
    DateTime selectedDate = record.date;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Edit Weight Record'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pre-filled weight field
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Weight'),
                    ),
                    // Pre-filled notes field
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(labelText: 'Notes'),
                    ),
                    SizedBox(height: 8),
                    // Date selection row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}",
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                // Cancel editing
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.white)),
                ),
                // Save changes
                ElevatedButton(
                  onPressed: () async {
                    if (weightController.text.isNotEmpty) {
                      double weightValue = double.parse(weightController.text);
                      final updatedRecord = WeightRecord(
                        id: record.id, // ensure you pass the record id
                        weight: weightValue,
                        date: selectedDate,
                        notes: notesController.text,
                      );
                      await _dbHelper.updateWeight(updatedRecord);
                      Navigator.pop(context);
                      setState(() {});
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
