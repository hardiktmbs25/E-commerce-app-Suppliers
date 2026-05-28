import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:get/get.dart';
import '../routes/app_routes.dart';

class VoiceService extends GetxService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final RxBool isListening = false.obs;
  final RxString lastWords = "".obs;

  Future<void> init() async {
    await _speech.initialize();
  }

  void startListening(Function(String) onResult) async {
    if (!_speech.isAvailable) return;
    
    isListening.value = true;
    _speech.listen(onResult: (val) {
      lastWords.value = val.recognizedWords;
      if (val.finalResult) {
        isListening.value = false;
        _processCommand(val.recognizedWords);
      }
    });
  }

  void stopListening() {
    _speech.stop();
    isListening.value = false;
  }

  void _processCommand(String text) {
    final command = text.toLowerCase();
    
    if (command.contains("add customer") || command.contains("ग्राहक जोड़ें")) {
      Get.toNamed(Routes.addCustomer);
    } else if (command.contains("show routes") || command.contains("रूट दिखाएं")) {
      Get.toNamed(Routes.routeList);
    } else if (command.contains("billing") || command.contains("बिलिंग")) {
      Get.toNamed(Routes.billing);
    } else if (command.contains("dashboard") || command.contains("डैशबोर्ड")) {
      Get.offAllNamed(Routes.dashboard);
    }
    // Add more commands as needed
  }
}