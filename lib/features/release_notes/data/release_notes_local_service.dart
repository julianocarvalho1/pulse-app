import 'package:shared_preferences/shared_preferences.dart';

class ReleaseNotesLocalService {
  ReleaseNotesLocalService({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const String currentRelease = '1.4.1';
  static const String _seenReleaseKey = 'release_notes_seen_version';

  final Future<SharedPreferences> Function() _preferencesLoader;

  Future<bool> shouldShowCurrentRelease() async {
    final preferences = await _preferencesLoader();
    return preferences.getString(_seenReleaseKey) != currentRelease;
  }

  Future<void> markCurrentReleaseAsSeen() async {
    final preferences = await _preferencesLoader();
    await preferences.setString(_seenReleaseKey, currentRelease);
  }
}
