import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/features/home/presentation/widgets/category_icon_mapper.dart';

void main() {
  group('categoryIconFor', () {
    group('L1 category icons', () {
      test('car returns car icon', () {
        expect(
          categoryIconFor('car'),
          PhosphorIcons.car(PhosphorIconsStyle.duotone),
        );
      });

      test('device-mobile returns devices icon', () {
        expect(
          categoryIconFor('device-mobile'),
          PhosphorIcons.devices(PhosphorIconsStyle.duotone),
        );
      });

      test('devices returns devices icon (alias)', () {
        expect(
          categoryIconFor('devices'),
          PhosphorIcons.devices(PhosphorIconsStyle.duotone),
        );
      });

      test('house returns armchair icon', () {
        expect(
          categoryIconFor('house'),
          PhosphorIcons.armchair(PhosphorIconsStyle.duotone),
        );
      });

      test('armchair returns armchair icon (alias)', () {
        expect(
          categoryIconFor('armchair'),
          PhosphorIcons.armchair(PhosphorIconsStyle.duotone),
        );
      });

      test('t-shirt returns tShirt icon', () {
        expect(
          categoryIconFor('t-shirt'),
          PhosphorIcons.tShirt(PhosphorIconsStyle.duotone),
        );
      });

      test('bicycle returns bicycle icon', () {
        expect(
          categoryIconFor('bicycle'),
          PhosphorIcons.bicycle(PhosphorIconsStyle.duotone),
        );
      });

      test('baby returns baby icon', () {
        expect(
          categoryIconFor('baby'),
          PhosphorIcons.baby(PhosphorIconsStyle.duotone),
        );
      });

      test('wrench returns wrench icon', () {
        expect(
          categoryIconFor('wrench'),
          PhosphorIcons.wrench(PhosphorIconsStyle.duotone),
        );
      });

      test('dots-three returns package icon', () {
        expect(
          categoryIconFor('dots-three'),
          PhosphorIcons.package(PhosphorIconsStyle.duotone),
        );
      });

      test('package returns package icon (alias)', () {
        expect(
          categoryIconFor('package'),
          PhosphorIcons.package(PhosphorIconsStyle.duotone),
        );
      });
    });

    group('L2 subcategory icons', () {
      test('phone returns phone icon', () {
        expect(
          categoryIconFor('phone'),
          PhosphorIcons.phone(PhosphorIconsStyle.duotone),
        );
      });

      test('laptop returns laptop icon', () {
        expect(
          categoryIconFor('laptop'),
          PhosphorIcons.laptop(PhosphorIconsStyle.duotone),
        );
      });

      test('game-controller returns gameController icon', () {
        expect(
          categoryIconFor('game-controller'),
          PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
        );
      });

      test('motorcycle returns motorcycle icon', () {
        expect(
          categoryIconFor('motorcycle'),
          PhosphorIcons.motorcycle(PhosphorIconsStyle.duotone),
        );
      });

      test('scooter returns scooter icon', () {
        expect(
          categoryIconFor('scooter'),
          PhosphorIcons.scooter(PhosphorIconsStyle.duotone),
        );
      });

      test('cooking-pot returns cookingPot icon', () {
        expect(
          categoryIconFor('cooking-pot'),
          PhosphorIcons.cookingPot(PhosphorIconsStyle.duotone),
        );
      });

      test('flower returns flower icon', () {
        expect(
          categoryIconFor('flower'),
          PhosphorIcons.flower(PhosphorIconsStyle.duotone),
        );
      });

      test('paint-roller returns paintRoller icon', () {
        expect(
          categoryIconFor('paint-roller'),
          PhosphorIcons.paintRoller(PhosphorIconsStyle.duotone),
        );
      });

      test('dress returns dress icon', () {
        expect(
          categoryIconFor('dress'),
          PhosphorIcons.dress(PhosphorIconsStyle.duotone),
        );
      });

      test('pants returns pants icon', () {
        expect(
          categoryIconFor('pants'),
          PhosphorIcons.pants(PhosphorIconsStyle.duotone),
        );
      });

      test('sneaker returns sneaker icon', () {
        expect(
          categoryIconFor('sneaker'),
          PhosphorIcons.sneaker(PhosphorIconsStyle.duotone),
        );
      });

      test('handbag returns handbag icon', () {
        expect(
          categoryIconFor('handbag'),
          PhosphorIcons.handbag(PhosphorIconsStyle.duotone),
        );
      });

      test('soccer-ball returns soccerBall icon', () {
        expect(
          categoryIconFor('soccer-ball'),
          PhosphorIcons.soccerBall(PhosphorIconsStyle.duotone),
        );
      });

      test('tennis-ball returns tennisBall icon', () {
        expect(
          categoryIconFor('tennis-ball'),
          PhosphorIcons.tennisBall(PhosphorIconsStyle.duotone),
        );
      });

      test('running returns personSimpleRun icon', () {
        expect(
          categoryIconFor('running'),
          PhosphorIcons.personSimpleRun(PhosphorIconsStyle.duotone),
        );
      });

      test('waves returns waves icon', () {
        expect(
          categoryIconFor('waves'),
          PhosphorIcons.waves(PhosphorIconsStyle.duotone),
        );
      });

      test('snowflake returns snowflake icon', () {
        expect(
          categoryIconFor('snowflake'),
          PhosphorIcons.snowflake(PhosphorIconsStyle.duotone),
        );
      });

      test('toy-brick returns lego icon', () {
        expect(
          categoryIconFor('toy-brick'),
          PhosphorIcons.lego(PhosphorIconsStyle.duotone),
        );
      });

      test('baby-carriage returns babyCarriage icon', () {
        expect(
          categoryIconFor('baby-carriage'),
          PhosphorIcons.babyCarriage(PhosphorIconsStyle.duotone),
        );
      });

      test('backpack returns backpack icon', () {
        expect(
          categoryIconFor('backpack'),
          PhosphorIcons.backpack(PhosphorIconsStyle.duotone),
        );
      });

      test('hammer returns hammer icon', () {
        expect(
          categoryIconFor('hammer'),
          PhosphorIcons.hammer(PhosphorIconsStyle.duotone),
        );
      });

      test('chalkboard-teacher returns chalkboardTeacher icon', () {
        expect(
          categoryIconFor('chalkboard-teacher'),
          PhosphorIcons.chalkboardTeacher(PhosphorIconsStyle.duotone),
        );
      });

      test('truck returns truck icon', () {
        expect(
          categoryIconFor('truck'),
          PhosphorIcons.truck(PhosphorIconsStyle.duotone),
        );
      });

      test('vinyl-record returns vinylRecord icon', () {
        expect(
          categoryIconFor('vinyl-record'),
          PhosphorIcons.vinylRecord(PhosphorIconsStyle.duotone),
        );
      });

      test('music-notes returns musicNotes icon', () {
        expect(
          categoryIconFor('music-notes'),
          PhosphorIcons.musicNotes(PhosphorIconsStyle.duotone),
        );
      });

      test('paint-brush returns paintBrush icon', () {
        expect(
          categoryIconFor('paint-brush'),
          PhosphorIcons.paintBrush(PhosphorIconsStyle.duotone),
        );
      });

      test('barbell returns barbell icon', () {
        expect(
          categoryIconFor('barbell'),
          PhosphorIcons.barbell(PhosphorIconsStyle.duotone),
        );
      });
    });

    group('fallback', () {
      test('unknown name returns tag icon', () {
        expect(
          categoryIconFor('nonexistent-icon'),
          PhosphorIcons.tag(PhosphorIconsStyle.duotone),
        );
      });

      test('empty string returns tag icon', () {
        expect(
          categoryIconFor(''),
          PhosphorIcons.tag(PhosphorIconsStyle.duotone),
        );
      });
    });
  });
}
