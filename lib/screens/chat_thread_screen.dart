import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_message_model.dart';
import '../models/chat_thread_model.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.thread,
    required this.role,
  });

  final ChatThreadModel thread;
  final String role;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _messageController = TextEditingController();
  late final ChatService _service;
  List<ChatMessageModel> _messages = [];
  List<Map<String, dynamic>> _pendingAttachments = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ChatService(ApiService());
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _service.fetchMessages(widget.thread.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = items;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Unable to load messages';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) {
      return;
    }

    setState(() => _isSending = true);

    try {
      final message = await _service.sendMessage(
        threadId: widget.thread.id,
        messageText: text,
        attachments: _pendingAttachments,
      );
      if (!mounted) {
        return;
      }
      _messageController.clear();
      setState(() {
        _messages = [..._messages, message];
        _pendingAttachments = [];
        _isSending = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to read selected file')),
      );
      return;
    }

    final attachmentType = _resolveAttachmentType(file);
    final mimeType = file.extension != null
        ? _mimeTypeFromExtension(file.extension!)
        : 'application/octet-stream';
    final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

    setState(() {
      _pendingAttachments = [
        ..._pendingAttachments,
        {
          'type': attachmentType,
          'name': file.name,
          'url': dataUrl,
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.role == 'specialist'
        ? (widget.thread.patientName ?? 'Patient')
        : (widget.thread.specialistName ?? 'Specialist');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          const Divider(height: 1),
          if (_pendingAttachments.isNotEmpty)
            _PendingAttachmentsBar(
              attachments: _pendingAttachments,
              onRemoveAt: (index) {
                setState(() {
                  _pendingAttachments = [
                    ..._pendingAttachments..removeAt(index),
                  ];
                });
              },
            ),
          _ChatComposer(
            controller: _messageController,
            isSending: _isSending,
            onSend: _sendMessage,
            onPickAttachment: _pickAttachment,
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_messages.isEmpty) {
      return const Center(child: Text('No messages yet.'));
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isMine = message.senderRole == widget.role;
          final alignment =
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
          final bubbleColor = isMine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest;

          return Column(
            crossAxisAlignment: alignment,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: alignment,
                  children: [
                    if (message.messageText.trim().isNotEmpty)
                      Text(message.messageText),
                    if (message.attachments.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final attachment in message.attachments)
                        _AttachmentPreview(attachment: attachment),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('d MMM, h:mm a').format(message.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onPickAttachment,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onPickAttachment;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconButton(
              onPressed: isSending ? null : onPickAttachment,
              icon: const Icon(Icons.attach_file),
              tooltip: 'Add attachment',
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: isSending ? null : onSend,
              child: Text(isSending ? '...' : 'Send'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingAttachmentsBar extends StatelessWidget {
  const _PendingAttachmentsBar({
    required this.attachments,
    required this.onRemoveAt,
  });

  final List<Map<String, dynamic>> attachments;
  final void Function(int index) onRemoveAt;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return InputChip(
            label: Text(
              attachment['name']?.toString() ?? 'Attachment',
              overflow: TextOverflow.ellipsis,
            ),
            avatar: Icon(_iconForAttachmentType(attachment['type']?.toString())),
            onDeleted: () => onRemoveAt(index),
          );
        },
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({
    required this.attachment,
  });

  final Map<String, dynamic> attachment;

  @override
  Widget build(BuildContext context) {
    final type = attachment['type']?.toString() ?? 'file';
    final name = attachment['name']?.toString() ?? 'Attachment';
    final url = attachment['url']?.toString() ?? '';

    if (type == 'image' && url.startsWith('data:image/')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                height: 140,
                width: 220,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForAttachmentType(type), size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$type: $name',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

String _resolveAttachmentType(PlatformFile file) {
  final extension = (file.extension ?? '').toLowerCase();
  if (['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(extension)) {
    return 'image';
  }
  if (['pdf', 'doc', 'docx'].contains(extension)) {
    return 'prescription';
  }
  return 'file';
}

String _mimeTypeFromExtension(String extension) {
  switch (extension.toLowerCase()) {
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'pdf':
      return 'application/pdf';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    default:
      return 'application/octet-stream';
  }
}

IconData _iconForAttachmentType(String? type) {
  switch (type) {
    case 'image':
      return Icons.image_outlined;
    case 'prescription':
      return Icons.description_outlined;
    default:
      return Icons.attach_file;
  }
}
