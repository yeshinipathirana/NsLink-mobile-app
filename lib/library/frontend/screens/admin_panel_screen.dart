import 'package:flutter/material.dart';
import '../../backend/services/database_service.dart';
import '../../backend/models/room.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final DatabaseService _databaseService = DatabaseService();

  void _showRoomDialog({Room? room}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: room?.name ?? '');
    final capacityController = TextEditingController(
      text: room != null ? room.capacity.toString() : '',
    );
    bool isAvailable = room?.isAvailable ?? true;

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(room == null ? 'Add Room' : 'Edit Room'),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Room Name',
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Enter room name'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: capacityController,
                          decoration: const InputDecoration(
                            labelText: 'Capacity',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final cap = int.tryParse(value ?? '');
                            if (cap == null || cap <= 0)
                              return 'Enter valid capacity';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Available'),
                          value: isAvailable,
                          onChanged: (value) {
                            setState(() => isAvailable = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          if (room == null) {
                            // Add new room
                            await _databaseService.addRoom(
                              name: nameController.text,
                              capacity: int.parse(capacityController.text),
                              isAvailable: isAvailable,
                            );
                          } else {
                            // Update room
                            await _databaseService.roomsCollection
                                .doc(room.id)
                                .update({
                                  'name': nameController.text,
                                  'capacity': int.parse(
                                    capacityController.text,
                                  ),
                                  'isAvailable': isAvailable,
                                });
                          }
                          if (mounted) Navigator.pop(dialogContext);
                        }
                      },
                      child: Text(room == null ? 'Add' : 'Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Room Management'),
        backgroundColor: Colors.teal,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRoomDialog(),
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
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final rooms = snapshot.data ?? [];
          if (rooms.isEmpty) {
            return const Center(child: Text('No rooms available.'));
          }
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        room.isAvailable ? Colors.green : Colors.red,
                    child: Text(
                      room.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text('Room \\${room.name}'),
                  subtitle: Text('Capacity: \\${room.capacity}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showRoomDialog(room: room),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _databaseService.deleteRoom(room.id);
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
