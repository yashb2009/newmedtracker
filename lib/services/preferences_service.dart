import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyMediaType = 'media_type';
  static const String _keyDoNotAsk = 'do_not_ask_media_type';
  static const String _keyDoNotShowBottleInstructions = 'do_not_show_bottle_instructions';

  static PreferencesService? _instance;
  static SharedPreferences? _preferences;

  static const String mediaTypeVideo = 'video';
  static const String mediaTypeImage = 'image';

  PreferencesService._();

  static Future<PreferencesService> getInstance() async {
    _instance ??= PreferencesService._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Get the preferred media type (video or image)
  String getMediaType() {
    return _preferences?.getString(_keyMediaType) ?? mediaTypeVideo;
  }

  // Set the preferred media type
  Future<void> setMediaType(String type) async {
    await _preferences?.setString(_keyMediaType, type);
  }

  // Check if user selected "Do not ask me again"
  bool getDoNotAsk() {
    return _preferences?.getBool(_keyDoNotAsk) ?? false;
  }

  // Set the "Do not ask me again" preference
  Future<void> setDoNotAsk(bool value) async {
    await _preferences?.setBool(_keyDoNotAsk, value);
  }

  // Check if user selected "Do not show bottle instructions again"
  bool getDoNotShowBottleInstructions() {
    return _preferences?.getBool(_keyDoNotShowBottleInstructions) ?? false;
  }

  // Set the "Do not show bottle instructions again" preference
  Future<void> setDoNotShowBottleInstructions(bool value) async {
    await _preferences?.setBool(_keyDoNotShowBottleInstructions, value);
  }

  // Reset all preferences (useful for testing or settings reset)
  Future<void> resetPreferences() async {
    await _preferences?.remove(_keyMediaType);
    await _preferences?.remove(_keyDoNotAsk);
    await _preferences?.remove(_keyDoNotShowBottleInstructions);
  }
}
