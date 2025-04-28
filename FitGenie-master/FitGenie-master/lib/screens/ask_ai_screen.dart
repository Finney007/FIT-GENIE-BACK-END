import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';


class AskAiScreen extends StatefulWidget {
  final int userId;

  const AskAiScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AskAiScreenState createState() => _AskAiScreenState();
}

class _AskAiScreenState extends State<AskAiScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isLoading = false;
  String errorMessage = '';
  List<Map<String, dynamic>> conversationHistory = [];

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Process AI response text to:
  // 1. Remove content within <think></think> tags
  // 2. Format content within ** ** as bold
  String processAiResponse(String text) {
    // Remove content within <think></think> tags
    final thinkPattern = RegExp(r'<think>.*?</think>', dotAll: true);
    String processed = text.replaceAll(thinkPattern, '');

    // We'll handle bold formatting when rendering
    return processed.trim();
  }

  Future<void> _askAi() async {
    if (_questionController.text.trim().isEmpty) return;

    final question = _questionController.text.trim();

    setState(() {
      isLoading = true;
      errorMessage = '';
      conversationHistory.add({'type': 'user', 'text': question});
    });
    _questionController.clear();

    try {
      final result = await apiService.askAi(
        userId: widget.userId,
        question: question,
      );

      if (!mounted) return;

      setState(() {
        final answer = result['answer'] ?? 'No response from AI';
        final processedAnswer = processAiResponse(answer);
        conversationHistory.add({'type': 'ai', 'text': processedAnswer});
        _questionController.clear();
      });

      // Scroll to the bottom of the conversation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        conversationHistory.add({'type': 'error', 'text': 'Error: $errorMessage'});
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: conversationHistory.isEmpty
              ? _buildEmptyState()
              : _buildConversation(),
        ),
        if (errorMessage.isNotEmpty && conversationHistory.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red),
            ),
          ),
        _buildInputArea(),
      ],
    );
  }

  // Renders rich text with bold formatting for ** text **
  Widget _renderFormattedText(String text, Color textColor) {
    List<InlineSpan> spans = [];

    // Split by ** markers
    final parts = text.split('**');
    bool isBold = false;

    for (var part in parts) {
      if (part.isEmpty) continue;

      spans.add(
        TextSpan(
          text: part,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: textColor,
          ),
        ),
      );

      isBold = !isBold;
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: textColor),
        children: spans,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Ask me anything about health and nutrition',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'I can provide personalized advice based on your health profile',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversation() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: conversationHistory.length,
      itemBuilder: (context, index) {
        final message = conversationHistory[index];
        final isUser = message['type'] == 'user';
        final isError = message['type'] == 'error';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              top: 8,
              bottom: 8,
              left: isUser ? 64 : 0,
              right: isUser ? 0 : 64,
            ),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? Colors.deepPurple
                  : (isError ? Colors.red.shade100 : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isUser || isError
                ? Text(
                    message['text'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : (isError ? Colors.red : Colors.black87),
                    ),
                  )
                : _renderFormattedText(
                    message['text'] ?? '',
                    Colors.black87,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    // Input area unchanged
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Ask a health or nutrition question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _askAi(),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: isLoading ? null : _askAi,
              icon: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.send, color: Colors.white),
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }
}