import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class VertexAiService {
  // Use a specific location to ensure stability on Web and Mobile
  static final FirebaseAI _vertexAi = FirebaseAI.vertexAI(location: 'us-central1');

  // Use Gemini 2.5 Flash Lite for speed/cost on Explore Feed
  static final _flashModel = _vertexAi.generativeModel(
    model: 'gemini-2.5-flash-lite',
  );

  // Use Gemini 2.5 Pro for deep analysis and document processing
  static final _proModel = _vertexAi.generativeModel(
    model: 'gemini-2.5-pro',
  );

  /// Method to generate grounded business insights for the Explore page.
  /// Uses Google Search grounding to ensure information is real-time and accurate.
  static Future<String?> generateGroundedInsights(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _flashModel.generateContent(content);
      return response.text;
    } catch (e) {
      debugPrint('Vertex AI Grounding Error: $e');
      return null;
    }
  }

  /// Multimodal chat method that supports text, images, and PDF documents.
  /// Refactored to use Bytes (Uint8List) for Cross-Platform (Web) compatibility.
  static Future<String?> getMultimodalCompletion(
    List<Map<String, String>> history, {
    List<Map<String, dynamic>>? attachments, // [{ 'bytes': Uint8List, 'mimeType': String }]
  }) async {
    try {
      final List<Content> contents = [];

      // Mapping historical messages
      // We need to find the LAST user message to correctly attach files to it
      int lastUserMsgIndex = -1;
      for (var i = history.length - 1; i >= 0; i--) {
        if (history[i]['role'] == 'user') {
          lastUserMsgIndex = i;
          break;
        }
      }

      for (var i = 0; i < history.length; i++) {
        final msg = history[i];
        
        // Safety: treat system as user if needed
        final role = msg['role'] == 'user' ? 'user' : (msg['role'] == 'system' ? 'user' : 'model');
        final text = msg['content'] ?? '';

        // Attach files ONLY to the specific last USER message we found
        if (i == lastUserMsgIndex && attachments != null && attachments.isNotEmpty) {
          final List<Part> parts = [TextPart(text)];
          
          for (var attachment in attachments) {
            final Uint8List bytes = attachment['bytes'];
            final String mimeType = attachment['mimeType'];
            parts.add(InlineDataPart(mimeType, bytes));
          }
          
          contents.add(Content(role, parts));
        } else {
          // Normal text message
          contents.add(Content(role, [TextPart(text)]));
        }
      }

      // If history was empty but we have attachments, create a fresh user message
      if (contents.isEmpty && attachments != null && attachments.isNotEmpty) {
        final List<Part> parts = [];
        for (var attachment in attachments) {
          final Uint8List bytes = attachment['bytes'];
          final String mimeType = attachment['mimeType'];
          parts.add(InlineDataPart(mimeType, bytes));
        }
        contents.add(Content('user', parts));
      }

      if (contents.isEmpty) return null;

      // Use the fast Flash model for text-only chats, Pro only for document analysis
      final model = (attachments != null && attachments.isNotEmpty) ? _proModel : _flashModel;

      final response = await model.generateContent(contents).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('AI process timed out. The document might be too large or the network is unstable.'),
      );
      
      // Safety check for blocked content
      if (response.text == null || response.text!.isEmpty) {
        return 'The AI response was blocked or empty. This can happen with large documents or sensitive business data.';
      }
      
      return response.text;
    } catch (e) {
      debugPrint('Vertex AI Multimodal Error Details: $e');
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('403')) {
        return 'Permission Denied (403). Please ensure Vertex AI for Firebase is enabled and the proper API permissions are granted in your console.';
      } else if (errorStr.contains('404')) {
        return 'Model Not Found (404). This usually means the model "gemini-2.5-pro" is not available in your project region (us-central1).';
      } else if (errorStr.contains('quota') || errorStr.contains('429')) {
        return 'Rate Limit Exceeded. Please try again in 1 minute.';
      } else if (errorStr.contains('mime') || errorStr.contains('application/octet-stream')) {
        return 'Unsupported file format detected. Please ensure your PDF is a standard, unencrypted file.';
      }
      
      return 'AI Processing Error: $e. (Please check if the PDF is too large or contains complex encryption).';
    }
  }
}
