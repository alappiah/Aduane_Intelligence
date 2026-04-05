import 'package:capstone_frontend/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../widgets/recipe_card.dart';
import '../services/api_service.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  // Catch the user data passed from Login/Home
  final Map<String, dynamic> user;
  final int todayCalories;
  const ChatScreen({
    super.key,
    required this.user,
    required this.todayCalories,
  });

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
  int _currentCaloriesEatenToday = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory(); // Load private history on startup
    _fetchTodayCalories();
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

  Future<void> _handleLogAction(
    int index,
    Map<String, dynamic> actionData,
  ) async {
    // Use your static ApiService function!
    bool success = await ApiService.logMeal(
      userId: widget.user['id'],
      name: actionData['food_name'],
      mealType: "Lunch",
      calories: actionData['calories'],
      carbs: 0,
      protein: 0,
      fats: 0,
      sodium: 0,
      sugar: 0, // Fill these as needed
      time: DateTime.now().toIso8601String(),
    );

    if (success) {
      // 🌟 1. Refresh Global Dashboard (Steps/Cals)
      await AppState().loadDashboardData(widget.user['id']);

      // 🌟 2. HIDE THE BUTTON: Clear log_data from this specific message
      setState(() {
        _messages[index]['log_data'] = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Meal logged!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    if (_editingUserMsgId != null && _editingUiIndex != null) {
      // --- 🟢 IN-PLACE UPDATE MODE ---
      final uIdx = _editingUiIndex!;
      int aIdx = uIdx + 1; // Changed from 'final' to 'int'

      setState(() {
        _messages[uIdx]['text'] = text; // Update user bubble

        // 🌟 THE FIX: Safely check if the AI bubble exists!
        if (aIdx < _messages.length && _messages[aIdx]['isMe'] == false) {
          // The AI bubble exists, clear it for re-streaming
          _messages[aIdx]['text'] = "";
          _messages[aIdx]['recipes'] = [];
        } else {
          // There is no AI bubble here! Insert a brand new placeholder
          _messages.insert(aIdx, {"isMe": false, "text": "", "recipes": []});
        }

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

  Future<void> _fetchTodayCalories() async {
    final dashboardData = await ApiService.fetchTodayDashboard(
      widget.user['id'],
    );

    if (dashboardData != null && mounted) {
      setState(() {
        // NOTE: Change 'total_calories' to match the exact key your FastAPI dashboard returns!
        _currentCaloriesEatenToday = dashboardData['total_calories'] ?? 0;
      });
    }
  }

  Future<void> _startAiStream(
    String text,
    int aiIndex, {
    int? existingAiId,
  }) async {
    _cancelToken = CancelToken();
    setState(() => _isGenerating = true);

    // 🌟 1. THE SAFETY LOCK: Prevents saving the same message twice
    bool hasSaved = false;

    // 🌟 2. THE HELPER: A single source of truth for saving to the DB
    Future<void> finalizeAndSave() async {
      if (hasSaved) return; // If we already saved it, stop.
      hasSaved = true;

      final currentText = _messages[aiIndex]['text'];
      final currentRecipes = _messages[aiIndex]['recipes'];

      if (existingAiId != null) {
        await ApiService.updateChatMessage(
          existingAiId,
          currentText,
          recipes: currentRecipes,
        );
      } else if (_messages[aiIndex]['id'] != null) {
        await ApiService.updateChatMessage(
          _messages[aiIndex]['id'],
          currentText,
          recipes: currentRecipes,
        );
      } else {
        int? newAiId = await ApiService.saveChatMessage(
          widget.user['id'],
          currentText,
          'ai',
          recipes: currentRecipes,
        );
        if (newAiId != null && mounted) {
          setState(() => _messages[aiIndex]['id'] = newAiId);
        }
      }
    }

    try {
      // 1. Get the Goal
      int userCalorieGoal = widget.user['goal_calories'] ?? 2000;

      // 2. THE BULLETPROOF FETCH: Ask the backend for the real math!
      int dynamicCaloriesEaten = 0;
      final dashboardData = await ApiService.fetchTodayDashboard(
        widget.user['id'],
      );
      if (dashboardData != null) {
        dynamicCaloriesEaten = widget.todayCalories;
      }

      // 3. FORCE THE PRINT TO SHOW UP
      debugPrint(
        "📱 FLUTTER CHECK -> Goal: $userCalorieGoal | Eaten: $dynamicCaloriesEaten",
      );

      // 4. SEND TO AI
      final response = await _dio.post<ResponseBody>(
        '/chat/message',
        data: {
          "query": text,
          "health_condition": widget.user['health_condition'],
          "current_calories": dynamicCaloriesEaten,
          "calorie_goal": userCalorieGoal,
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
                  }
                  // 🌟 FIXED SYNTAX HERE:
                  else if (packet['type'] == 'log_action') {
                    setState(() {
                      _messages[aiIndex]['log_data'] = packet;
                    });
                    _scrollToBottom();
                  } else if (packet['type'] == 'done') {
                    setState(() {
                      _isLoading = false;
                      _isGenerating = false;
                    });
                    await finalizeAndSave();
                  }
                } catch (e) {
                  debugPrint("JSON Parsing error: $e");
                }
              }
            },

            // 🟢 SCENARIO B: The stream threw an error (or was canceled violently)
            onError: (error) {
              setState(() {
                _isLoading = false;
                _isGenerating = false;

                if (_cancelToken?.isCancelled == true ||
                    (error is DioException &&
                        error.type == DioExceptionType.cancel)) {
                  if (!_messages[aiIndex]['text'].endsWith(
                    "You stopped this response",
                  )) {
                    _messages[aiIndex]['text'] +=
                        " ... You stopped this response";
                  }
                } else {
                  _messages[aiIndex]['text'] += "\n\n[Connection Lost]";
                }
              });
              finalizeAndSave(); // Save!
            },

            // 🟢 SCENARIO C: The socket closed silently (usually happens when canceled)
            onDone: () {
              setState(() {
                _isLoading = false;
                _isGenerating = false;

                // If it finished but the cancel token is active, we append the text
                if (_cancelToken?.isCancelled == true) {
                  if (!_messages[aiIndex]['text'].endsWith(
                    "You stopped this response",
                  )) {
                    _messages[aiIndex]['text'] +=
                        " ... You stopped this response";
                  }
                }
              });
              finalizeAndSave(); // Save!
            },
          );

      // 🟢 SCENARIO D: It crashed before it even connected to the server
    } catch (e) {
      print("Streaming Error: $e");
      setState(() {
        _isLoading = false;
        _isGenerating = false;
        if (e is DioException && e.type == DioExceptionType.cancel) {
          if (!_messages[aiIndex]['text'].endsWith(
            "You stopped this response",
          )) {
            _messages[aiIndex]['text'] += " ... You stopped this response";
          }
        } else {
          _messages[aiIndex]['text'] += "\n\n[Server Offline]";
        }
      });
      finalizeAndSave(); // Save!
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
    final int lastUserIndex = _messages.lastIndexWhere(
      (msg) => msg['isMe'] == true,
    );
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
                  isEditable: index == lastUserIndex,
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
    required bool isEditable,
  }) {
    // 🌟 FIX 1: Define 'msg' so the widget knows which message data to look at
    final msg = _messages[index];

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

            if (isEditable)
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  if (_isGenerating) _cancelToken?.cancel();

                  setState(() {
                    _editingUserMsgId = _messages[index]['id'];
                    _editingUiIndex = index;

                    if (index + 1 < _messages.length &&
                        !_messages[index + 1]['isMe']) {
                      _editingAiMsgId = _messages[index + 1]['id'];
                    }
                  });

                  _textController.text = text;
                  _focusNode.requestFocus();
                },
              ),

            if (isEditable) const SizedBox(width: 8),

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
                child: SelectableText(
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

        // 🌟 FIX 2: LOG ACTION CARD
        // Check if log_data exists and isn't null
        if (msg['log_data'] != null) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(
              left: 44,
            ), // Align with the text bubble
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF41B9A1).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  // Changed from the Japanese character error to Icons.bolt
                  const Icon(Icons.bolt, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Log ${msg['log_data']['food_name']} (${msg['log_data']['calories']} kcal)?",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleLogAction(index, msg['log_data']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF41B9A1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Log"),
                  ),
                ],
              ),
            ),
          ),
        ],

        if (recipes.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 44),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                return RecipeCard(recipe: recipes[index]);
              },
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      color: Colors.white,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end, // Keeps the Send button at the bottom!
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,

              // 🌟 THE MAGIC 3 LINES FOR AUTO-EXPANDING:
              minLines: 1, // Starts as a normal 1-line box
              maxLines:
                  5, // Grows taller up to 5 lines, then scrolls internally
              keyboardType: TextInputType.multiline,

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
            ), // <-- Properly closes TextField
          ), // <-- Properly closes Expanded

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
                // 🌟 1. CAPTURE THE MESSENGER BEFORE DOING ANYTHING ELSE
                // This saves the tool we need while the context is still perfectly valid.
                final messenger = ScaffoldMessenger.of(context);

                // 2. Close the popup dialog
                Navigator.pop(context);

                // 3. Start loading on the main screen
                if (!mounted) return;
                setState(() => _isLoading = true);

                // 4. Call the backend to wipe PostgreSQL
                bool success = await ApiService.deleteChatHistory(
                  widget.user['id'],
                );

                // 🌟 5. CRITICAL FIX: Check if the screen is still open after the await!
                if (!mounted) return;

                if (success) {
                  setState(() {
                    // Clear the local UI list
                    _messages.clear();

                    // Re-insert the welcome message so the screen isn't empty
                    _messages.add({
                      "isMe": false,
                      "text":
                          "Hello ${widget.user['firstName']}! Your history has been cleared. How can I help with your meal planning today?",
                      "recipes": [],
                    });
                  });

                  // 🌟 6. SHOW THE SNACKBAR SAFELY
                  // We use the 'messenger' variable we captured in Step 1, completely bypassing the context error.
                  messenger.showSnackBar(
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
