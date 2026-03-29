import 'package:http/http.dart' as http;
import 'dart:convert';

class ChefService {
  final String _apiKey = const String.fromEnvironment('GROQ_API_KEY');
  final String _baseUrl = "https://api.groq.com/openai/v1/chat/completions";

  // Implementation 1: Chat History Memory
  final List<Map<String, String>> _history = [];

  Future<String> getRecipe(String userInput, {List<String>? items}) async {
    try {
      String systemContext = "You are an expert master chef specialized in gourmet cooking and food waste reduction. "
          "\n\nSTRICT SCOPE: You are exclusively a culinary assistant. You only answer questions related to "
          "food, recipes, cooking techniques, and kitchen organization. If the user asks about ANYTHING ELSE "
          "(politics, news, non-culinary general advice, or off-topic chat), you MUST politely decline and "
          "remind them that your purpose is to provide professional gourmet recipes and help them use their pantry. "
          "\n\nEMOJIS: Use emojis strategically throughout your response to make it look professional, "
          "appetizing, and engaging (e.g. 🥘, 🥧, 🍲, 🥬, 💡, 🔥, 👨‍🍳). "
          "\n\nSTRUCTURE: For all recipes, ALWAYS follow this structure:\nName: [Recipe Name]\nDescription: [Brief mouth-watering description with emojis]\nIngredients:\n- [Item 1 with specific measurements]\n- [Item 2 with specific measurements]\nInstructions:\n1. [Step 1 with detailed technique]\n2. [Step 2 with detailed technique]\nNutrition: [Approximate calories/macros]\nTip: [Professional chef's secret tip for this dish 💡]\n\nDo not use long paragraphs, but make the descriptions rich with culinary detail.";
      
      if (items != null && items.isNotEmpty) {
        systemContext += "\n\nCRITICAL KITCHEN CONTEXT: The user currently has the following items available in their pantry: ${items.join(', ')}. Please prioritize recipes that utilize these specific ingredients to reduce waste.";
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": systemContext},
            ..._history,
            {"role": "user", "content": userInput}
          ],
          "temperature": 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['choices'][0]['message']['content'];
        
        // Save to history
        _history.add({"role": "user", "content": userInput});
        _history.add({"role": "assistant", "content": aiResponse});
        
        // Keep history manageable
        if (_history.length > 20) _history.removeRange(0, 2);

        return aiResponse;
      } else {
        return "Chef Error: Status ${response.statusCode}";
      }
    } catch (e) {
      return "Connection failed. Please check your network.";
    }
  }

  void clearHistory() {
    _history.clear();
  }
}