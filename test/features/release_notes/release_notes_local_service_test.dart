import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/release_notes/data/release_notes_local_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('exibe a versão atual somente uma vez', () async {
    final service = ReleaseNotesLocalService();

    expect(await service.shouldShowCurrentRelease(), isTrue);

    await service.markCurrentReleaseAsSeen();

    expect(await service.shouldShowCurrentRelease(), isFalse);
  });

  test('exibe novamente quando a versão salva é anterior', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'release_notes_seen_version': '1.3.0',
    });

    final service = ReleaseNotesLocalService();

    expect(await service.shouldShowCurrentRelease(), isTrue);
  });
}
