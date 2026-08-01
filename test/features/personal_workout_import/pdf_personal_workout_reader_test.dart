import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/personal_workout_import/data/services/pdf_personal_workout_reader.dart';

void main() {
  test('aceita texto extraído de um PDF criado digitalmente', () {
    final result = PdfPersonalWorkoutReader.normalizeAndValidateExtractedText(
      'Treino A - Peito\nSupino reto com barra - 3x10 - 60s',
    );

    expect(result, contains('Treino A'));
  });

  test('identifica PDF sem texto extraível suficiente', () {
    expect(
      () => PdfPersonalWorkoutReader.normalizeAndValidateExtractedText('   '),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'mensagem',
          contains('fontes incorporadas incompatíveis'),
        ),
      ),
    );
  });
}
