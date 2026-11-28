import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/design/widgets/service_art.dart';
import 'package:irondost_customer/features/catalogue/laundry.dart';
import 'package:irondost_customer/features/checkout/care_note.dart';

import '../helpers.dart';

void main() {
  group('laundry is the main service', () {
    test('a laundry or wash category counts; ironing and dry cleaning do not', () {
      expect(isLaundry(testCategory('laundry', 'Laundry', [])), isTrue);
      expect(isLaundry(testCategory('wash-and-iron', 'Wash & Iron', [])), isTrue);
      expect(isLaundry(testCategory('wash-and-fold', 'Wash & Fold', [])), isTrue);
      expect(isLaundry(testCategory('ironing', 'Ironing', [])), isFalse);
      expect(isLaundry(testCategory('dry-cleaning', 'Dry Cleaning', [])), isFalse);
    });

    test('"laundry" is never mistaken for dry cleaning', () {
      expect(mentionsDryCleaning('laundry'), isFalse);
      expect(mentionsDryCleaning('dry-cleaning'), isTrue);
      expect(mentionsDryCleaning('Dry Cleaning'), isTrue);
      expect(mentionsDryCleaning('dryclean'), isTrue);
      expect(careServiceOf('laundry'), CareService.washing);
      expect(ServiceArt.match('Laundry'), ServiceArt.laundry);
    });

    test('the laundry category is found wherever it sits in the price list', () {
      final list = [
        testCategory('ironing', 'Ironing', []),
        testCategory('laundry', 'Laundry', [], sortOrder: 1),
        testCategory('dry-cleaning', 'Dry Cleaning', [], sortOrder: 2),
      ];
      expect(laundryCategoryOf(list)?.slug, 'laundry');
      expect(laundryCategoryOf([testCategory('ironing', 'Ironing', [])]), isNull);
    });
  });
}
