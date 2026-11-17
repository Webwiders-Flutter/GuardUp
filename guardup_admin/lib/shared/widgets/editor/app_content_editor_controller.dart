import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

/// Enterprise controller for managing content editor state, conversions, and metrics.
///
/// Supports bidirectional conversions between Quill Delta, clean HTML, and Plain Text.
class AppContentEditorController extends ChangeNotifier {
  late final QuillController quillController;
  final bool _ownsController;

  AppContentEditorController({
    QuillController? customController,
    String? initialHtml,
    String? initialText,
    List<dynamic>? initialDeltaJson,
  }) : _ownsController = customController == null {
    if (customController != null) {
      quillController = customController;
    } else if (initialHtml != null && initialHtml.trim().isNotEmpty) {
      final delta = HtmlToDelta().convert(initialHtml);
      quillController = QuillController(
        document: Document.fromDelta(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else if (initialDeltaJson != null && initialDeltaJson.isNotEmpty) {
      quillController = QuillController(
        document: Document.fromJson(initialDeltaJson),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else if (initialText != null && initialText.isNotEmpty) {
      final doc = Document()..insert(0, initialText);
      quillController = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      quillController = QuillController.basic();
    }

    quillController.addListener(_onQuillChanged);
  }

  /// Factory constructor to initialize with an HTML string.
  factory AppContentEditorController.fromHtml(String html) {
    return AppContentEditorController(initialHtml: html);
  }

  /// Factory constructor to initialize with a plain text string.
  factory AppContentEditorController.fromText(String text) {
    return AppContentEditorController(initialText: text);
  }

  /// Factory constructor to initialize with Quill Delta JSON.
  factory AppContentEditorController.fromDeltaJson(List<dynamic> json) {
    return AppContentEditorController(initialDeltaJson: json);
  }

  void _onQuillChanged() {
    notifyListeners();
  }

  /// Document plain text without formatting.
  String get plainText => quillController.document.toPlainText().trim();

  /// Whether the editor content is empty.
  bool get isEmpty => plainText.isEmpty;

  /// Whether the editor has text.
  bool get isNotEmpty => !isEmpty;

  /// Total word count.
  int get wordCount {
    final text = plainText;
    if (text.isEmpty) return 0;
    return text
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .length;
  }

  /// Total character count (excluding trailing newline).
  int get charCount => plainText.length;

  /// Estimated reading time in minutes (average 200 words per minute).
  int get readTimeMinutes {
    final words = wordCount;
    if (words == 0) return 0;
    final mins = (words / 200).ceil();
    return mins < 1 ? 1 : mins;
  }

  /// Human-readable reading time estimate (e.g. "< 1 min read", "4 min read").
  String get readTimeEstimate {
    final mins = readTimeMinutes;
    if (mins <= 1) return '1 min read';
    return '$mins min read';
  }

  /// Exports current document as formatted HTML.
  String toHtml() {
    final deltaJson = quillController.document.toDelta().toJson();
    if (deltaJson.isEmpty) return '';

    final converter = QuillDeltaToHtmlConverter(
      List<Map<String, dynamic>>.from(deltaJson),
      ConverterOptions(multiLineBlockquote: true, multiLineHeader: true),
    );

    return converter.convert();
  }

  /// Helper to safely apply programmatic document modifications without requesting keyboard or focus
  void _applySilently(VoidCallback action) {
    quillController.skipRequestKeyboard = true;
    try {
      action();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        quillController.skipRequestKeyboard = false;
      });
    }
  }

  /// Sets content from an HTML string.
  void setHtml(String html) {
    _applySilently(() {
      if (html.trim().isEmpty) {
        quillController.document = Document();
        return;
      }

      try {
        final delta = HtmlToDelta().convert(html);
        quillController.document = Document.fromDelta(delta);
      } catch (_) {
        quillController.document = Document();
        quillController.document.insert(0, html);
      }
    });
  }

  /// Sets content from plain text.
  void setText(String text) {
    _applySilently(() {
      quillController.document = Document();
      if (text.isNotEmpty) {
        quillController.document.insert(0, text);
      }
    });
  }

  /// Exports Delta operations as JSON list.
  List<dynamic> toDeltaJson() {
    return quillController.document.toDelta().toJson();
  }

  /// Sets content from Delta JSON.
  void setDeltaJson(List<dynamic> json) {
    _applySilently(() {
      quillController.document = Document.fromJson(json);
    });
  }

  /// Clears the editor.
  void clear() {
    _applySilently(() {
      quillController.document = Document();
    });
  }

  @override
  void dispose() {
    quillController.removeListener(_onQuillChanged);
    if (_ownsController) {
      quillController.dispose();
    }
    super.dispose();
  }
}
