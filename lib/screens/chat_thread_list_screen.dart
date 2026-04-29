import 'package:flutter/material.dart';

import '../models/chat_thread_model.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import 'chat_thread_screen.dart';

class ChatThreadListScreen extends StatefulWidget {
  const ChatThreadListScreen({
    super.key,
    required this.role,
  });

  static const patientRouteName = '/patient-chats';
  static const specialistRouteName = '/specialist-chats';

  final String role;

  @override
  State<ChatThreadListScreen> createState() => _ChatThreadListScreenState();
}

class _ChatThreadListScreenState extends State<ChatThreadListScreen> {
  late final ChatService _service;
  List<ChatThreadModel> _threads = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ChatService(ApiService());
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _service.fetchThreads();
      if (!mounted) {
        return;
      }
      setState(() {
        _threads = items;
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
        _error = 'Unable to load chats';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.role == 'specialist' ? 'Patient Chats' : 'My Chats';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_threads.isEmpty) {
      return const Center(child: Text('No chats yet.'));
    }

    return RefreshIndicator(
      onRefresh: _loadThreads,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _threads.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final thread = _threads[index];
          final title = widget.role == 'specialist'
              ? (thread.patientName ?? 'Patient')
              : (thread.specialistName ?? 'Specialist');

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(title.isNotEmpty ? title[0].toUpperCase() : 'C'),
              ),
              title: Text(title),
              subtitle: Text(
                thread.lastMessageText.trim().isEmpty
                    ? 'No messages yet'
                    : thread.lastMessageText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatThreadScreen(
                      thread: thread,
                      role: widget.role,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
