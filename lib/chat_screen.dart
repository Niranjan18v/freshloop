import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chef_service.dart';

class FreshLoopChat extends StatefulWidget {
  @override
  _FreshLoopChatState createState() => _FreshLoopChatState();
}

class _FreshLoopChatState extends State<FreshLoopChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  final ChefService _chef = ChefService();
  bool _isLoading = false;

  final List<String> _suggestions = [
    "Quick Breakfast",
    "Vegetarian Dinner",
    "Healthy Snacks",
    "3-Ingredient Meals"
  ];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<List<String>> _getInventoryItems() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('products')
          .orderBy('expiryDate')
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  void _sendMessage([String? text]) async {
    String message = text ?? _controller.text.trim();
    if (message.isEmpty) return;

    if (mounted) {
      setState(() {
        _messages.add({"role": "user", "content": message});
        _isLoading = true;
      });
      _controller.clear();
      _scrollToBottom();
    }

    List<String> userItems = await _getInventoryItems();
    String aiResponse = await _chef.getRecipe(message, items: userItems);

    if (mounted) {
      setState(() {
        _messages.add({"role": "assistant", "content": aiResponse});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FBF9),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F3E8), Color(0xFFF9FBF9)],
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _messages.isEmpty ? _buildWelcomeScreen() : _buildChatList(),
            ),
            if (_isLoading) _buildLoadingIndicator(),
            _buildSuggestions(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 15, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF557C55), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Hero(
            tag: 'chef_ai_sparkle_hero',
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF557C55).withValues(alpha: 0.1),
              backgroundImage: AssetImage('assets/chef_avatar.png'),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Gourmet Chef AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3E2D))),
                Text("Virtual Culinary Expert", style: TextStyle(fontSize: 12, color: Color(0xFF557C55))),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF557C55)),
            onPressed: () {
              _chef.clearHistory();
              setState(() => _messages.clear());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Color(0xFF557C55).withValues(alpha: 0.2)),
            SizedBox(height: 20),
            Text("Ready to cook something?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Text(
                "I can help you with recipes, tips, and culinary inspiration. Ask me anything!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        bool isUser = _messages[index]["role"] == "user";
        return _buildChatBubble(_messages[index]["content"]!, isUser);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF557C55))),
          SizedBox(width: 10),
          Text("Chef is seasoning your response...", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 10),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: ActionChip(
              label: Text(_suggestions[index], style: TextStyle(color: Color(0xFF557C55), fontSize: 13, fontWeight: FontWeight.w600)),
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: Color(0xFF557C55).withValues(alpha: 0.3)),
              onPressed: () => _sendMessage(_suggestions[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    if (isUser) {
      return _buildUserBubble(text);
    } else {
      return _buildRecipeCard(text);
    }
  }

  Widget _buildUserBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              margin: EdgeInsets.only(left: 50, right: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 4))],
                gradient: LinearGradient(colors: [Color(0xFF557C55), Color(0xFF6B946B)]),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(text, style: TextStyle(color: Colors.white, height: 1.4, fontSize: 15)),
            ),
          ),
          _buildAvatar('assets/user_avatar.png'),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(String text) {
    // Basic Parsing (Enhanced)
    String name = "Chef's Suggestion";
    String description = "";
    String nutrition = "";
    String tip = "";
    List<String> ingredients = [];
    List<String> instructions = [];

    // Parse logic
    List<String> lines = text.split("\n");
    String currentSection = "";

    for (var line in lines) {
      String cleanLine = line.trim();
      if (cleanLine.toLowerCase().startsWith("name:")) {
        name = cleanLine.substring(5).trim();
      } else if (cleanLine.toLowerCase().startsWith("description:")) {
        description = cleanLine.substring(12).trim();
      } else if (cleanLine.toLowerCase().contains("ingredients:")) {
        currentSection = "ingredients";
      } else if (cleanLine.toLowerCase().contains("instructions:")) {
        currentSection = "instructions";
      } else if (cleanLine.toLowerCase().startsWith("nutrition:")) {
        nutrition = cleanLine.substring(10).trim();
        currentSection = "";
      } else if (cleanLine.toLowerCase().startsWith("tip:")) {
        tip = cleanLine.substring(4).trim();
        currentSection = "";
      } else if (cleanLine.isNotEmpty) {
        if (currentSection == "ingredients") {
          ingredients.add(cleanLine.replaceAll(RegExp(r'^[-*•]\s*'), "").trim());
        } else if (currentSection == "instructions") {
          instructions.add(cleanLine.replaceFirst(RegExp(r'^\d+\.\s*'), "").trim());
        }
      }
    }

    // Default to show full text if parsing failed to extract anything useful
    if (ingredients.isEmpty && instructions.isEmpty) {
      return _buildSimpleAiBubble(text);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 0, right: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar('assets/chef_avatar.png'),
          SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[100]!, width: 1.5),
                boxShadow: [BoxShadow(color: Color(0xFF557C55).withValues(alpha: 0.08), blurRadius: 20, offset: Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF2D3E2D), letterSpacing: -0.5)),
                      ),
                      _buildFeatureBadge(),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                  ],
                  SizedBox(height: 16),
                  
                  // Ingredients Section
                  if (ingredients.isNotEmpty) ...[
                    _buildSectionTitle("INGREDIENTS"),
                    SizedBox(height: 10),
                    ...ingredients.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(color: Color(0xFF557C55).withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: Icon(Icons.check, size: 10, color: Color(0xFF557C55)),
                          ),
                          SizedBox(width: 10),
                          Expanded(child: Text(item, style: TextStyle(fontSize: 14, color: Color(0xFF4A4A4A)))),
                        ],
                      ),
                    )).toList(),
                  ],

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Colors.grey[200], thickness: 1.0),
                  ),

                  // Instructions Section
                  if (instructions.isNotEmpty) ...[
                    _buildSectionTitle("STEPS"),
                    SizedBox(height: 12),
                    ...instructions.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${entry.key + 1}.", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF557C55))),
                          SizedBox(width: 12),
                          Expanded(child: Text(entry.value, style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF2D3E2D)))),
                        ],
                      ),
                    )).toList(),
                  ],

                  // Nutrition & Tip (Added Details)
                  if (nutrition.isNotEmpty || tip.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Color(0xFFF1F5F1), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (nutrition.isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.fitness_center, size: 14, color: Color(0xFF557C55)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 11, color: Color(0xFF557C55)),
                                      children: [
                                        TextSpan(text: "NUTRITION: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: nutrition),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (nutrition.isNotEmpty && tip.isNotEmpty) SizedBox(height: 8),
                          if (tip.isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb_outline, size: 14, color: Colors.orange[700]),
                                SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                      children: [
                                        TextSpan(text: "CHEF'S TIP: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800])),
                                        TextSpan(text: tip),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Footer Actions
                  _buildCardActions(name, text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.grey[500], letterSpacing: 1.2));
  }

  Widget _buildSimpleAiBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 50),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatar('assets/chef_avatar.png'),
          SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(4)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Text(text, style: TextStyle(height: 1.5, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 12, color: Colors.orange),
          SizedBox(width: 4),
          Text("15m", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildCardActions(String name, String fullText) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => _buildShareSheet(fullText),
              );
            },
            icon: Icon(Icons.share_outlined, size: 16, color: Color(0xFF557C55)),
            label: Text("Share", style: TextStyle(fontSize: 12, color: Color(0xFF557C55))),
          ),
          TextButton.icon(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('saved_recipes')
                    .add({
                  'name': name,
                  'content': fullText,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.bookmark_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Text("Recipe saved to your profile!", style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      backgroundColor: Color(0xFF557C55),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  );
                }
              }
            },
            icon: Icon(Icons.favorite_border, size: 16, color: Color(0xFF557C55)),
            label: Text("Save", style: TextStyle(fontSize: 12, color: Color(0xFF557C55))),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
        borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF1F5F1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: "What are we making today?",
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF557C55), Color(0xFF6B946B)]),
              ),
              child: IconButton(
                icon: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareSheet(String text) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
          SizedBox(height: 25),
          Text("Share Recipe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3E2D))),
          SizedBox(height: 15),
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: Color(0xFF557C55).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.copy_rounded, color: Color(0xFF557C55)),
            ),
            title: Text("Copy Recipe Text", style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("Copy full recipe to your clipboard"),
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Text("Recipe copied!", style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  backgroundColor: Color(0xFF557C55),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAvatar(String assetPath) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        image: DecorationImage(image: AssetImage(assetPath), fit: BoxFit.cover),
      ),
    );
  }
}

