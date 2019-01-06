import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:permitlog/utilities.dart';

/// This is a mock for Firebase [DatabaseReference], used in testing
/// some of the utility functions.
class MockReference extends Mock implements DatabaseReference {}

void main() {
  group("formatMilliseconds", () {
    test("format negative milliseconds throws an error", () {
      expect(() => formatMilliseconds(-52), throwsArgumentError);
    });
    test("format a small number of milliseconds returns 0", () {
      expect(formatMilliseconds(1), "0:00");
      expect(formatMilliseconds(1000), "0:00");
    });
    test("format milliseconds with only a minutes component", () {
      expect(formatMilliseconds(60000), "0:01");
      expect(formatMilliseconds(670300), "0:11");
    });
    test("format milliseconds with hours and minutes", () {
      expect(formatMilliseconds(12600000), "3:30");
      expect(formatMilliseconds(126000000), "35:00");
    });
    test("format milliseconds greater than 24 hours", () {
      expect(formatMilliseconds(129600000), "36:00");
    });
  });

  group("getCurrentLearnerRef", () {
    var testUserReference, testSubReference, testLearnerReference;
    setUp(() {
      // Setup mock behavior so we can test; note that this is different
      // from normal DatabaseReference behavior.
      testUserReference = MockReference();
      testSubReference = MockReference();
      testLearnerReference = MockReference();
      when(testUserReference.key).thenReturn("testUserRef");
      when(testUserReference.child("learners")).thenReturn(testSubReference);
      when(testSubReference.key).thenReturn("testSubRef");
      when(testSubReference.child("foo")).thenReturn(testLearnerReference);
      when(testLearnerReference.key).thenReturn("foo");
    });
    test("null database reference with empty learner key", () {
      expect(() => getCurrentLearnerRef(null, ""), throwsArgumentError);
    });
    test("null database reference with non-empty learner key", () {
      expect(() => getCurrentLearnerRef(null, "any"), throwsArgumentError);
    });
    test("valid database reference with empty learner key", () {
      expect(getCurrentLearnerRef(testUserReference, "").key, "testUserRef");
      expect(getCurrentLearnerRef(testSubReference, "").key, "testSubRef");
    });
    test("valid database reference with valid learner key", () {
      expect(getCurrentLearnerRef(testUserReference, "foo").key, "foo");
    });
    test("valid database reference with invalid learner key", () {
      expect(getCurrentLearnerRef(testUserReference, "bar"), null);
    });
  });

  group("logIsValid", () {
    test("non-map log yields false", () {
      expect(logIsValid("invalid log"), isFalse);
    });
    test("map without the proper keys yields false", () {
      expect(logIsValid(new Map()), isFalse);
    });
    test("map with the proper keys yields true", () {
      expect(logIsValid({"start": 0, "end": 3, "night": true, "driver_id": -5}),
          isTrue);
    });
  });

  group("hasCompleteName", () {
    test("non-map data yields false", () {
      expect(hasCompleteName(3.14), isFalse);
    });
    test("map without the proper keys yields false", () {
      expect(hasCompleteName(new Map()), isFalse);
    });
    test("map with the proper keys yields true", () {
      expect(
          hasCompleteName({
            "name": {"first": "Boaty", "last": "McBoat Face"}
          }),
          isTrue);
    });
  });

  group("createDropdownItems", () {
    test("empty list of strings yields an empty list", () {
      expect(createDropdownItems([]), []);
    });
    test("non-empty list of strings yields a non-empty list", () {
      var menuItems = createDropdownItems(["test1", "test2"]);
      Text test1 = menuItems[0].child;
      Text test2 = menuItems[1].child;
      expect(menuItems[0].value, 0);
      expect(test1.data, "test1");
      expect(menuItems[1].value, 1);
      expect(test2.data, "test2");
    });
  });
}
