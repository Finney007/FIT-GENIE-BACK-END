import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class AskAiPictureScreen extends StatefulWidget {
  final int userId;

  const AskAiPictureScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AskAiPictureScreenState createState() => _AskAiPictureScreenState();
}

class _AskAiPictureScreenState extends State<AskAiPictureScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  File? _selectedImage;
  String errorMessage = '';
  bool isLoading = false;
  List<Map<String, dynamic>> conversationHistory = [];

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

Future<void> _pickImage(ImageSource source) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source);
  if (pickedFile != null) {
    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }
}

  Future<void> _askAi() async {
    if (_questionController.text.trim().isEmpty) return;
    if (_selectedImage == null) {
      setState(() {
        errorMessage = 'Please select an image.';
      });
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = '';
      conversationHistory.add({
        'type': 'user',
        'text': _questionController.text.trim(),
      });
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await apiService.askAiWithPicture(
        userId: widget.userId,
        question: _questionController.text.trim(),
        image: base64Image,
      );

      if (!mounted) return;
      setState(() {
        final answer = result['answer'] ?? 'No response from AI';
        conversationHistory.add({'type': 'ai', 'text': answer});
        _questionController.clear();
        _selectedImage = null;
      });

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

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
        ],
      ),
      child: Column(
        children: [
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton(
                    icon: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, color: Colors.white, size: 16),
                      radius: 12,
                    ),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              PopupMenuButton<ImageSource>(
                icon: Icon(Icons.add_photo_alternate, color: Colors.deepPurple),
                onSelected: _pickImage,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: ImageSource.camera,
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt),
                        SizedBox(width: 8),
                        Text('Camera'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ImageSource.gallery,
                    child: Row(
                      children: [
                        Icon(Icons.photo_library),
                        SizedBox(width: 8),
                        Text('Gallery'),
                      ],
                    ),
                  ),
                ],
                tooltip: 'Pick an image',
              ),
              Expanded(
                child: TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    hintText: 'Ask a question with picture...',
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
            child: Text(
              message['text'] ?? '',
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : (isError ? Colors.red : Colors.black87),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedImagePreview() {
    if (_selectedImage == null) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.file(
        _selectedImage!,
        height: 150,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Upload an image and ask a health-related question',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Get AI insights based on your image',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
        _buildSelectedImagePreview(),
        _buildInputArea(),
      ],
    );
  }
}
