import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GenerativeModel createModel({required String apiKey}) {
    return GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }
}
