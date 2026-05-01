import 'package:flutter/foundation.dart';

import '../../../core/repositories/profile_repository.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({ProfileRepository? profileRepository})
    : _profileRepository = profileRepository ?? getIt<ProfileRepository>();

  final ProfileRepository _profileRepository;

  bool isLoading = false;
  Map<String, dynamic>? profile;
  String? error;

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _profileRepository.getCurrentProfile();
      switch (result) {
        case Success(data: final data):
          profile = data;
        case Failure(error: final failure):
          profile = null;
          error = failure.message;
      }
    } on Exception catch (e) {
      error = 'Failed to refresh profile: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
