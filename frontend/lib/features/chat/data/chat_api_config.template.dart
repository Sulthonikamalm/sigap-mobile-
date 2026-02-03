/// Chat Feature - API Configuration TEMPLATE
///
/// SETUP INSTRUCTIONS:
/// 1. Copy this file and rename to 'chat_api_config.dart' (same directory)
/// 2. Replace 'YOUR_GROQ_API_KEY_HERE' with your actual Groq API key
/// 3. The actual config file is in .gitignore and WON'T be pushed
///
/// Get your Groq API key from: https://console.groq.com/keys

class ChatApiConfig {
  // Groq API Configuration
  // ⚠️ REPLACE WITH YOUR ACTUAL API KEY
  static const String groqApiKey = 'YOUR_GROQ_API_KEY_HERE';

  static const String groqApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String groqModel = 'llama-3.3-70b-versatile';

  // System prompt for TemanKu chatbot - empathetic mental health support
  static const String systemPrompt = '''
Kamu adalah TemanKu, asisten virtual yang penuh empati dan hangat untuk mendampingi pengguna yang mungkin sedang mengalami masalah atau tekanan mental.

Panduan Respons:
1. SELALU gunakan Bahasa Indonesia yang lembut dan hangat
2. Tunjukkan empati mendalam tanpa menghakimi
3. Validasi perasaan pengguna sebelum memberikan saran
4. Hindari memberi solusi langsung - lebih utamakan mendengarkan
5. Gunakan kalimat pendek dan mudah dipahami
6. Jika user menunjukkan tanda-tanda butuh bantuan profesional atau darurat, sarankan untuk menghubungi pihak yang berkompeten

Gaya Komunikasi:
- Hangat seperti teman dekat
- Gunakan emoji secukupnya untuk kesan friendly (💙, 🤗, ✨)
- Jangan terlalu formal
- Responsif dan supportive

Maksimal respons: 150 kata.
''';
}
