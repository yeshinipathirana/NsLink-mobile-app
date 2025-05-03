import 'package:flutter/material.dart';
import '../../../../backend/services/database_service.dart';
import '../../../../backend/models/room.dart';

class RoomsTab extends StatefulWidget {
  const RoomsTab({super.key});

  @override
  State<RoomsTab> createState() => _RoomsTabState();
}

class _RoomsTabState extends State<RoomsTab> {
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  bool _isAvailable = true;
  Room? _selectedRoom;

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _showAddRoomDialog() {
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Room'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Room Name',
                  hintText: 'e.g., 101',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter room name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  hintText: 'e.g., 4',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter capacity';
                  }
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Available'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() => _isAvailable = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              _capacityController.clear();
              _isAvailable = true;
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await _databaseService.addRoom(
                    name: _nameController.text,
                    capacity: int.parse(_capacityController.text),
                    isAvailable: _isAvailable,
                  );

                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  if (!mounted) return;
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Room added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _nameController.clear();
                  _capacityController.clear();
                  _isAvailable = true;
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add Room'),
          ),
        ],
      ),
    );
  }

  void _blockTimeSlot() async {
    if (!mounted) return;
    final currentContext = context;

    final selectedRoom = _selectedRoom;
    if (selectedRoom == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Please select a room first')),
      );
      return;
    }

    try {
      final DateTime? selectedDate = await showDatePicker(
        context: currentContext,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)),
      );

      if (!mounted) return;
      if (selectedDate == null) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Please select a date')),
        );
        return;
      }

      final TimeOfDay? startTime = await showTimePicker(
        context: currentContext,
        initialTime: TimeOfDay.now(),
      );

      if (!mounted) return;
      if (startTime == null) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Please select a start time')),
        );
        return;
      }

      final TimeOfDay? endTime = await showTimePicker(
        context: currentContext,
        initialTime: TimeOfDay(
          hour: (startTime.hour + 2) % 24,
          minute: startTime.minute,
        ),
      );

      if (!mounted) return;
      if (endTime == null) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Please select an end time')),
        );
        return;
      }

      // Convert TimeOfDay to DateTime
      final startDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startTime.hour,
        startTime.minute,
      );

      final endDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        endTime.hour,
        endTime.minute,
      );

      await _databaseService.blockTimeSlot(
        selectedRoom.id,
        selectedDate,
        startDateTime,
        endDateTime,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text('Time slot blocked successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentContext = context;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Room>>(
        stream: _databaseService.rooms,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return const Center(
              child: Text(
                'No rooms available\nClick + to add a room',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        room.isAvailable ? Colors.green : Colors.red,
                    child: Text(
                      room.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('Room ${room.name}'),
                  subtitle: Text('Capacity: ${room.capacity} people'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: room.isAvailable,
                        onChanged: (value) {
                          _databaseService.updateRoomAvailability(
                            room.id,
                            value,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.block, color: Colors.orange),
                        onPressed: () {
                          setState(() => _selectedRoom = room);
                          _blockTimeSlot();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: currentContext,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Room'),
                              content: Text(
                                'Are you sure you want to delete Room ${room.name}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await _databaseService
                                          .deleteRoom(room.id);
                                      if (!mounted) return;
                                      Navigator.pop(dialogContext);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(currentContext)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Room deleted successfully'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(currentContext)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(e
                                              .toString()
                                              .replaceAll('Exception: ', '')),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
