import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddSlot extends StatefulWidget {
  final Function(String, String) onSlotAdded;

  const AddSlot({super.key, required this.onSlotAdded});

  @override
  State<AddSlot> createState() => _AddSlotState();
}

class _AddSlotState extends State<AddSlot> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _formKey = GlobalKey<FormState>();

  // Add duration options for meeting length
  final List<int> _durationOptions = [30, 60, 90, 120]; // in minutes
  int _selectedDuration = 60; // default duration

  void _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _pickStartTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _startTime = pickedTime;
        // Calculate end time based on selected duration
        _updateEndTime();
      });
    }
  }

  void _updateEndTime() {
    if (_startTime != null) {
      // Convert TimeOfDay to minutes since midnight
      int startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      int endMinutes = startMinutes + _selectedDuration;

      // Convert back to TimeOfDay
      int endHour = endMinutes ~/ 60;
      int endMinute = endMinutes % 60;

      // Handle overflow to next day
      if (endHour >= 24) {
        endHour = endHour - 24;
      }

      setState(() {
        _endTime = TimeOfDay(hour: endHour, minute: endMinute);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate != null && _startTime != null && _endTime != null) {
        // Format date as "E, MMM d" (e.g., "Mon, Mar 17")
        String formattedDate = DateFormat('E, MMM d').format(_selectedDate!);

        // Format time slot as "10:00 AM - 12:30 PM"
        final DateTime startDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _startTime!.hour,
          _startTime!.minute,
        );

        final DateTime endDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );

        String formattedStartTime = DateFormat('h:mm a').format(startDateTime);
        String formattedEndTime = DateFormat('h:mm a').format(endDateTime);
        String timeslot = '$formattedStartTime - $formattedEndTime';

        widget.onSlotAdded(formattedDate, timeslot);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please complete all fields")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Available Slot"),
        backgroundColor: Colors.teal,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Date",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(top: 10, bottom: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? "Choose a Date"
                            : DateFormat(
                              'E, MMM d, yyyy',
                            ).format(_selectedDate!),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const Text(
                "Start Time",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: _pickStartTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(top: 10, bottom: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _startTime == null
                            ? "Choose Start Time"
                            : _startTime!.format(context),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.access_time, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const Text(
                "Meeting Duration",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<int>(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    value: _selectedDuration,
                    items:
                        _durationOptions.map((int minutes) {
                          return DropdownMenuItem<int>(
                            value: minutes,
                            child: Text('$minutes minutes'),
                          );
                        }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedDuration = newValue;
                          // Recalculate end time if start time is already selected
                          if (_startTime != null) {
                            _updateEndTime();
                          }
                        });
                      }
                    },
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ),

              // Show calculated end time
              if (_endTime != null && _startTime != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    children: [
                      const Text(
                        "End Time: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _endTime!.format(context),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _submitForm,
                  child: const Text(
                    "Add Slot",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
