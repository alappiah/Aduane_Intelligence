import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../widgets/recipe_card.dart';
import '../services/api_service.dart'; // Import your service

class ChatScreen extends StatefulWidget {
  // Catch the user data passed from Login/Home
  final Map<String, dynamic> user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory(); // Load private history on startup
  }

  // Load history from PostgreSQL
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await ApiService.getChatHistory(widget.user['id']);

    setState(() {
      for (var msg in history) {
        _messages.add({
          "isMe": msg['sender'] == 'user',
          "text": msg['content'],
          "recipes": msg['recipes'] ?? [],
        });
      }
      // If history is empty, add the welcome message
      if (_messages.isEmpty) {
        _messages.add({
          "isMe": false,
          "text":
              "Hello ${widget.user['firstName']}! I am your personal nutritionist. What are you craving today?",
          "recipes": [],
        });
      }
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. UI Update & Save User Message to DB
    setState(() {
      _messages.add({"isMe": true, "text": text, "recipes": []});
      _isLoading = true;
    });

    // Save to DB in background
    ApiService.saveChatMessage(widget.user['id'], text, 'user');

    _textController.clear();
    _scrollToBottom();

    try {
      // 2. Call recommendation engine using USER'S condition
      final response = await _dio.post(
        '/chat/message',
        data: {
          "query": text,
          "health_condition": widget.user['health_condition'],
        },
      );

      final data = response.data;
      final aiMsg = data['ai_message'] ?? "Here are some options:";

      // 3. UI Update & Save AI Message to DB
      setState(() {
        _messages.add({
          "isMe": false,
          "text": aiMsg,
          "recipes": data['results'] ?? [],
        });
        _isLoading = false;
      });

      ApiService.saveChatMessage(
        widget.user['id'],
        aiMsg,
        'ai',
        recipes: data['results'],
      );
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          "isMe": false,
          "text": "Connection error. Is the server running?",
          "recipes": [],
        });
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3EAEF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // CHAT LIST
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageRow(
                  isMe: msg['isMe'],
                  text: msg['text'],
                  recipes: msg['recipes'],
                );
              },
            ),
          ),

          // LOADING INDICATOR
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Consulting the nutritionist...",
                style: TextStyle(color: Colors.grey),
              ),
            ),

          // INPUT AREA
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageRow({
    required bool isMe,
    required String text,
    required List<dynamic> recipes,
  }) {
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              const CircleAvatar(
                backgroundColor: Color(0xFFD9D9D9),
                radius: 16,
                child: Icon(
                  Icons.health_and_safety,
                  size: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(width: 12),
            ],

            // TEXT BUBBLE
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF41B9A1) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft:
                        isMe
                            ? const Radius.circular(12)
                            : const Radius.circular(2),
                    bottomRight:
                        isMe
                            ? const Radius.circular(2)
                            : const Radius.circular(12),
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),

        // RECIPE CARDS CAROUSEL (Only if there are recipes)
        if (recipes.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 240, // Height for the card row
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              // Add left padding to align with the bot text
              padding: const EdgeInsets.only(left: 44),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                // Use the RecipeCard widget we created earlier
                return RecipeCard(recipe: recipes[index]);
              },
            ),
          ),
        ],

        const SizedBox(height: 24), // Spacing between messages
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Ask (e.g., Spicy Lunch)...",
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onSubmitted: _sendMessage, // Allow Enter key to send
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF41B9A1),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}
