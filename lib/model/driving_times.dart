import 'package:firebase_database/firebase_database.dart';

/// Represents different amounts of driving times for different categories.
/// Valid categories are given by the list of [types].
class DrivingTimes {
  /// List holding categories of driving times.
  static final List<String> types = <String>[
    "total",
    "day",
    "night",
    "weather",
    "adverse"
  ];

  /// Corresponding List holding the times for each category.
  List<int> _drivingTimes = [0, 0, 0, 0, 0];

  /// Constructs a new [DrivingTimes] object. Users can optionally specify
  /// times for the categories listed in [types].
  DrivingTimes({total = 0, day = 0, night = 0, weather = 0, adverse = 0}) {
    _drivingTimes = [total, day, night, weather, adverse];
  }

  /// Gets the time corresponding to the given type. Throws an [ArgumentError]
  /// if the given type is not one of the valid [types].
  int getTime(String type) {
    int typeIndex = types.indexOf(type);
    if (typeIndex == -1) {
      throw ArgumentError("Invalid driving time type: " + type);
    }
    return _drivingTimes[typeIndex];
  }

  /// Sets the time corresponding to the given type. Throws an [ArgumentError]
  /// if the given type is not one of the valid [types].
  void setTime(String type, int time) {
    int typeIndex = types.indexOf(type);
    if (typeIndex == -1) {
      throw ArgumentError("Invalid driving time type: " + type);
    }
    if (time < 0) {
      throw ArgumentError("Driving time must be non-negative.");
    }

    _drivingTimes[typeIndex] = time;
  }

  /// Adds the time to the total for the given type.
  void addTime(String type, int time) {
    setTime(type, getTime(type) + time);
  }

  /// Updates the DrivingTimes object based off a Firebase event from
  /// the user's goals.
  void updateWithEvent(Event event) {
    // Get the data and go through every type of goal.
    Map data = event.snapshot.value ?? Map();

    for (String type in DrivingTimes.types) {
      if (data.containsKey(type))
        setTime(type, data[type]);
      else
        setTime(type, 0);
    }
  }
}
