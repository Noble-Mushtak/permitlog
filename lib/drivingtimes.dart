/// Class that holds different amounts of driving hours for different categories
class DrivingTimes {
  /// List holding categories of driving times.
  static final List<String> TIME_TYPES = <String>["total", "day", "night", "weather", "adverse"];
  /// Corresponding List holding the times for each category.
  List<int> _drivingTimes = [0, 0, 0, 0, 0];

  /// Constructor
  DrivingTimes({int total = 0, int day = 0, int night = 0, int weather = 0, int adverse = 0}) {
    /// Create a corresponding list of the driving times.
    _drivingTimes = [total, day, night, weather, adverse];
  }

  /// Gets the time corresponding to a type.
  int getTime(String type) {
    /// Find the type in TIME_TYPES.
    int typeIndex = TIME_TYPES.indexOf(type);
    /// Throw an error if the type is not found.
    if (typeIndex == -1) throw("Invalid driving time type: "+type);
    /// Return the corresponding time.
    return _drivingTimes[typeIndex];
  }

  /// Sets the time corresponding to a type.
  void setTime(String type, int time) {
    /// Find the type in TIME_TYPES.
    int typeIndex = TIME_TYPES.indexOf(type);
    /// Throw an error if the type is not found.
    if (typeIndex == -1) throw("Invalid driving time type: "+type);
    /// Set the corresponding time.
    _drivingTimes[typeIndex] = time;
  }
}