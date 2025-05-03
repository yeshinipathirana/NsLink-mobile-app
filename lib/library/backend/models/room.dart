// Room Model
// Represents a library room in the system, including identification, name, capacity, and availability.

class Room {
  // Unique identifier for the room
  final String id;

  // Human-readable name of the room (e.g., "Study Room 1")
  final String name;

  // Maximum number of people the room can accommodate
  final int capacity;

  // Availability status of the room
  final bool isAvailable;

  // Constructor that requires all essential room information
  Room({
    required this.id,
    required this.name,
    required this.capacity,
    required this.isAvailable,
  });

  // Creates a Room object from Firestore data
  // This makes our database operations more readable and maintainable
  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as String,
      name: map['name'] as String,
      capacity: map['capacity'] as int,
      isAvailable: map['isAvailable'] as bool,
    );
  }

  // Converts Room object to a format suitable for Firestore
  // This ensures consistent data structure in our database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'isAvailable': isAvailable,
    };
  }

  // String representation of the room for debugging and logging
  @override
  String toString() {
    return 'Room: $name (Capacity: $capacity)';
  }
}
