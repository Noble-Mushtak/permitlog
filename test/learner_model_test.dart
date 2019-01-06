import 'package:firebase_database/firebase_database.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:permitlog/model/learner_model.dart';

/// Mock [DatabaseReference] so we can test without touching the actual database.
class MockReference extends Mock implements DatabaseReference {}

void main() {
  var learnerModel;
  setUp(() {
    var testReference = MockReference();
    learnerModel = LearnerModel(userRef: testReference, callback: null);
  });

  test("todo", () {
    // TODO
  });
}
