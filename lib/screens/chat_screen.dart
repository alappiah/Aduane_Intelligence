import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../widgets/recipe_card.dart';
import '../services/api_service.dart';
import 'dart:convert';

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
  final FocusNode _focusNode = FocusNode(); // <-- ADD THI
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isGenerating = false; // Tracks if the AI is currently typing
  CancelToken? _cancelToken;

  int? _editingUserMsgId;
  int? _editingAiMsgId;
  int? _editingUiIndex; // Which bubble on the screen are we overwriting?

  @override
  void initState() {
    super.initState();
    _loadHistory(); // Load private history on startup
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose(); // <-- ADD THIS
    super.dispose();
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
          "id": msg['id'],
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

    if (_editingUserMsgId != null && _editingUiIndex != null) {
      // --- 🟢 IN-PLACE UPDATE MODE ---
      final uIdx = _editingUiIndex!;
      final aIdx = uIdx + 1;

      setState(() {
        _messages[uIdx]['text'] = text; // Update user bubble
        _messages[aIdx]['text'] = ""; // Clear AI bubble for re-streaming
        _messages[aIdx]['recipes'] = [];
        _isLoading = true;
      });

      _textController.clear();
      await ApiService.updateChatMessage(_editingUserMsgId!, text);

      // Pass the existing AI ID to update the same row
      await _startAiStream(text, aIdx, existingAiId: _editingAiMsgId);

      // Reset edit state
      setState(() {
        _editingUserMsgId = null;
        _editingAiMsgId = null;
        _editingUiIndex = null;
      });
    } else {
      // --- ⚪ NORMAL MODE ---
      setState(() {
        _messages.add({"isMe": true, "text": text, "recipes": []});
        _isLoading = true;
      });

      final uIdx = _messages.length - 1;
      _textController.clear();
      _scrollToBottom();

      // Save user prompt and capture ID
      int? newUserId = await ApiService.saveChatMessage(
        widget.user['id'],
        text,
        'user',
      );
      if (newUserId != null) {
        setState(() => _messages[uIdx]['id'] = newUserId);
      }

      // Create AI placeholder
      setState(() {
        _messages.add({"isMe": false, "text": "", "recipes": []});
      });

      final aIdx = _messages.length - 1;
      await _startAiStream(text, aIdx);
    }
  }

  Future<void> _startAiStream(
    String text,
    int aiIndex, {
    int? existingAiId,
  }) async {
    _cancelToken = CancelToken();
    setState(() => _isGenerating = true);

    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/message',
        data: {
          "query": text,
          "health_condition": widget.user['health_condition'],
        },
        cancelToken: _cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: {"Accept": "text/event-stream"},
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      response.data?.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (String line) async {
              if (line.startsWith('data: ')) {
                final jsonStr = line.substring(6);
                try {
                  final packet = jsonDecode(jsonStr);

                  if (packet['type'] == 'text') {
                    setState(
                      () => _messages[aiIndex]['text'] += packet['content'],
                    );
                    _scrollToBottom();
                  } else if (packet['type'] == 'recipe') {
                    setState(
                      () =>
                          _messages[aiIndex]['recipes'].add(packet['content']),
                    );
                    _scrollToBottom();
                  } else if (packet['type'] == 'done') {
                    setState(() {
                      _isLoading = false;
                      _isGenerating = false;
                    });

                    if (existingAiId != null) {
                      // In-place Update Mode
                      await ApiService.updateChatMessage(
                        existingAiId,
                        _messages[aiIndex]['text'],
                        recipes: _messages[aiIndex]['recipes'],
                      );
                    } else {
                      // Initial Save Mode
                      int? newAiId = await ApiService.saveChatMessage(
                        widget.user['id'],
                        _messages[aiIndex]['text'],
                        'ai',
                        recipes: _messages[aiIndex]['recipes'],
                      );
                      if (newAiId != null) {
                        setState(() => _messages[aiIndex]['id'] = newAiId);
                      }
                    }
                  }
                } catch (e) {
                  print("JSON Parsing error: $e");
                }
              }
            },
            onError: (error) {
              setState(() {
                _isLoading = false;
                _isGenerating = false;
              });
              // Add stop sign logic here if needed
            },
            onDone:
                () => setState(() {
                  _isLoading = false;
                  _isGenerating = false;
                }),
          );
    } catch (e) {
      print("Streaming Error: $e");
      setState(() {
        _isLoading = false;
        _isGenerating = false;
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
        // 🌟 ADD THIS ACTIONS BLOCK:
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: _showDeleteConfirmation,
          ),
          const SizedBox(width: 8),
        ],
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
                  index: index, // <-- ADD THIS
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
    required int index,
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
          crossAxisAlignment:
              CrossAxisAlignment.start, // aligns avatar/button to top
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

            // --- 🟢 NEW: ADD THE EDIT BUTTON FOR USER MESSAGES ---
            if (isMe)
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                padding:
                    EdgeInsets.zero, // Keeps it snug against the chat bubble
                constraints:
                    const BoxConstraints(), // Removes extra default padding
                onPressed: () async {
                  if (_isGenerating) _cancelToken?.cancel();

                  setState(() {
                    // 1. Store the IDs for the backend UPDATE
                    _editingUserMsgId = _messages[index]['id'];
                    _editingUiIndex = index;

                    // Grab the AI's ID (the bubble immediately after the user's)
                    if (index + 1 < _messages.length &&
                        !_messages[index + 1]['isMe']) {
                      _editingAiMsgId = _messages[index + 1]['id'];
                    }
                  });

                  // 2. Put text back into the controller for editing
                  _textController.text = text;
                  _focusNode.requestFocus();
                },
              ),

            if (isMe)
              const SizedBox(width: 8), // Small gap between pencil and bubble
            // ----------------------------------------------------

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
              focusNode: _focusNode,
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
            backgroundColor:
                _isGenerating ? Colors.redAccent : const Color(0xFF41B9A1),
            child: IconButton(
              // If generating, show a Stop icon. Otherwise, show Send.
              icon: Icon(
                _isGenerating ? Icons.stop : Icons.send,
                color: Colors.white,
              ),
              onPressed: () {
                if (_isGenerating) {
                  // Fire the kill-switch!
                  _cancelToken?.cancel("User pressed stop.");
                } else {
                  // Send the message normally
                  _sendMessage(_textController.text);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Clear All History?"),
          content: const Text(
            "This will permanently delete all your nutritional consultations. This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close the popup
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close the popup
                setState(() => _isLoading = true);

                // 1. Call the backend to wipe PostgreSQL
                bool success = await ApiService.deleteChatHistory(
                  widget.user['id'],
                );

                if (success) {
                  setState(() {
                    // 2. Clear the local UI list
                    _messages.clear();

                    // 3. Re-insert the welcome message so the screen isn't empty
                    _messages.add({
                      "isMe": false,
                      "text":
                          "Hello ${widget.user['firstName']}! Your history has been cleared. How can I help with your meal planning today?",
                      "recipes": [],
                    });
                  });

                  // 🌟 4. SHOW THE SNACKBAR (Toast)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Chat history successfully deleted"),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }

                setState(() => _isLoading = false);
              },
              child: const Text(
                "Delete Everything",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
