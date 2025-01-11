import 'package:flutter_test/flutter_test.dart';
import 'package:rnd_game/cell.dart';

void main() {
  group('copyWith works properly', () {
    test('Cell.copyWith return a Cell object', () {
      Cell cell1 = Cell(atomCount: 2, x: 2, y: 2);
      var cell2 = cell1.copyWith();

      expect(cell2, isA<Cell>());
      expect(cell1, cell2);
    });

    test('Cell.copyWith return a Cell with correct values', () {
      Cell cell1 = Cell(atomCount: 2, x: 2, y: 2, playerId: 'noPlayerId');
      var cell2 =
          cell1.copyWith(atomCount: 1, x: 1, y: 1, playerId: 'playerId');

      expect(cell2.atomCount, 1);
      expect(cell2.x, 1);
      expect(cell2.y, 1);
      expect(cell2.playerId, 'playerId');
    });
  });

  group('toJson works properly', () {
    test('toJson return a Map<String, dynamic>', () {
      Cell cell1 = Cell(atomCount: 1, x: 1, y: 1, playerId: 'playerId');
      var cell2 = cell1.toJson();

      expect(cell2, isA<Map<String, dynamic>>());
    });

    test('toJson return a Map', () {
      Cell cell1 = Cell(atomCount: 1, x: 1, y: 1, playerId: 'playerId');
      var cell2 = cell1.toJson();

      expect(cell2['playerId'], 'playerId');
      expect(cell2['x'], 1);
      expect(cell2['y'], 1);
      expect(cell2['atomCount'], 1);
    });
  });

  group('fromJson works properly', () {
    test('fromJson create a Cell object', () {
      Map<String, dynamic> json = {
        'playerId': 'playerId',
        'x': 1,
        'y': 1,
        'atomCount': 1,
      };

      expect(Cell.fromJson(json), isA<Cell>());
    });

    test('fromJson create a Cell object with correct values', () {
      Map<String, dynamic> json = {
        'playerId': 'playerId',
        'x': 1,
        'y': 1,
        'atomCount': 1,
      };

      var cell = Cell.fromJson(json);

      expect(cell.atomCount, json['atomCount']);
      expect(cell.x, json['x']);
      expect(cell.y, json['y']);
      expect(cell.playerId, json['playerId']);
    });
  });

  group('hashCode\'s override works properly', () {
    test('hashCode is correctly overrided', () {
      var cell1 = Cell(atomCount: 1, x: 1, y: 1, playerId: 'playerId');

      expect(
        cell1.hashCode,
        cell1.playerId.hashCode ^
            cell1.atomCount.hashCode ^
            cell1.x.hashCode ^
            cell1.y.hashCode,
      );
    });
  });

  group('Getter maxAmount works properly', () {
    test('Getter maxAmount return 4 when Cell is in the middle of the board',
        () {
      Cell cell1 = Cell(atomCount: 3, x: 3, y: 3, playerId: 'playerId');

      expect(cell1.maxAmount, 4);
    });

    test('Getter maxAmount return 2 when Cell is in the corner of the board',
        () {
      Cell cell1 = Cell(atomCount: 3, x: 0, y: 0, playerId: 'playerId');

      expect(cell1.maxAmount, 2);
    });

    test('Getter maxAmount return 3 when Cell is on the side of the board', () {
      Cell cell1 = Cell(atomCount: 3, x: 7, y: 3, playerId: 'playerId');

      expect(cell1.maxAmount, 3);
    });
  });

  group('isExploding works properly', () {
    group('isExploding is true when atomCount is greater than his maxAmount',
        () {
      test(
          'should return true when atomCount is 4 and is in the middle of the board ',
          () {
        Cell cell1 = Cell(atomCount: 4, x: 3, y: 3);

        expect(cell1.isExploding, true);
      });
    });

    group('isExploding is false when atomCount is lower than his maxAmount',
        () {
      test(
          'should return false when atomCount is 3 and is in the middle of the board ',
          () {
        Cell cell1 = Cell(atomCount: 3, x: 3, y: 3);

        expect(cell1.isExploding, false);
      });
    });
  });
}
