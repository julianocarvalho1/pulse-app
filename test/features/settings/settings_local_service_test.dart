import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/settings/data/settings_local_service.dart';
import 'package:pulse/features/settings/domain/pulse_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'mantém tema escuro quando ainda não existe preferência salva',
    () async {
      final settings = await SettingsLocalService().load();

      expect(settings.themeMode, PulseThemeMode.dark);
    },
  );

  test('persiste modo do tema e cor principal', () async {
    final service = SettingsLocalService();
    final expected = PulseSettings.defaults().copyWith(
      themeMode: PulseThemeMode.light,
      themeColorValue: 0xFF2979FF,
    );

    await service.save(expected);
    final restored = await service.load();

    expect(restored.themeMode, PulseThemeMode.light);
    expect(restored.themeColorValue, 0xFF2979FF);
  });

  test('ignora valor de tema desconhecido e usa o padrão', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings_theme_mode': 'desconhecido',
    });

    final settings = await SettingsLocalService().load();

    expect(settings.themeMode, PulseThemeMode.dark);
  });

  test('persiste o caminho local da foto do perfil', () async {
    final service = SettingsLocalService();
    final expected = PulseSettings.defaults().copyWith(
      profile: PulseSettings.defaults().profile.copyWith(
        photoPath: '/data/user/0/pulse/profile/foto.jpg',
      ),
    );

    await service.save(expected);
    final restored = await service.load();

    expect(restored.profile.photoPath, '/data/user/0/pulse/profile/foto.jpg');
  });
}
