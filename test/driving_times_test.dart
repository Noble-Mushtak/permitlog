import 'package:test/test.dart';

import 'package:permitlog/model/driving_times.dart';

void main() {
  DrivingTimes dt1, dt2;

  setUp(() {
    dt1 = new DrivingTimes();
    dt2 = new DrivingTimes(total: 1, day: 7, night: 9, weather: 2, adverse: 3);
  });

  test("correct types", () {
    expect(DrivingTimes.types, ["total", "day", "night", "weather", "adverse"]);
  });

  test("get invalid time type", () {
    expect(() => dt1.getTime("foo"), throwsArgumentError);
  });

  test("set invalid time type", () {
    expect(() => dt1.setTime("bar", 5), throwsArgumentError);
  });

  test("set invalid time", () {
    expect(() => dt1.setTime("total", -1), throwsArgumentError);
    expect(dt1.getTime("total"), 0);
  });

  test("get/set valid time types", () {
    // Initial expectations
    expect(dt1.getTime("total"), 0);
    expect(dt1.getTime("day"), 0);
    expect(dt1.getTime("night"), 0);
    expect(dt1.getTime("weather"), 0);
    expect(dt1.getTime("adverse"), 0);
    expect(dt2.getTime("total"), 1);
    expect(dt2.getTime("day"), 7);
    expect(dt2.getTime("night"), 9);
    expect(dt2.getTime("weather"), 2);
    expect(dt2.getTime("adverse"), 3);
    // Set some times
    dt1.setTime("total", 55);
    dt1.setTime("day", 108);
    dt1.setTime("night", 2 * 10 ^ 5);
    dt1.setTime("weather", 1);
    dt1.setTime("adverse", 42);
    dt2.setTime("total", 55);
    dt2.setTime("day", 108);
    dt2.setTime("weather", 1);
    dt2.setTime("adverse", 42);
    // Final expectations
    expect(dt1.getTime("total"), 55);
    expect(dt1.getTime("day"), 108);
    expect(dt1.getTime("night"), 2 * 10 ^ 5);
    expect(dt1.getTime("weather"), 1);
    expect(dt1.getTime("adverse"), 42);
    expect(dt2.getTime("total"), 55);
    expect(dt2.getTime("day"), 108);
    expect(dt2.getTime("night"), 9);
    expect(dt2.getTime("weather"), 1);
    expect(dt2.getTime("adverse"), 42);
  });

  test("add invalid time type", () {
    expect(() => dt2.addTime("baz", 18), throwsArgumentError);
  });

  test("add invalid time", () {
    expect(() => dt2.addTime("schlecht", -1), throwsArgumentError);
  });

  test("add valid time", () {
    expect(dt2.getTime("total"), 1);
    expect(dt2.getTime("day"), 7);
    dt2.addTime("total", 12);
    expect(dt2.getTime("total"), 13);
    expect(dt2.getTime("day"), 7);
  });
}
