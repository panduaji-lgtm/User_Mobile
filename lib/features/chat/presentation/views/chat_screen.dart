import 'package:flutter/material.dart';
import 'package:app/features/chat/presentation/viewmodels/chat_viewmodel.dart';

class ChatScreen extends StatefulWidget {
  final ChatViewModel viewModel;

  const ChatScreen({super.key, required this.viewModel});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

  void _handleSend([String? presetText]) {
    final text = presetText ?? _controller.text;
    if (text.trim().isEmpty) return;

    widget.viewModel.send(text);
    if (presetText == null) {
      _controller.clear();
    }
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        // Auto scroll saat ada pesan baru
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return Container(
          constraints: const BoxConstraints(
            maxWidth: 420,
            maxHeight: 620,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F3EA),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C322B),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3F5243),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                        ),
                        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Brawijaya Asisten',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'AI Resmi Museum Brawijaya',
                                  style: TextStyle(
                                    color: Color(0xFFDCD6CD),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        tooltip: 'Tutup',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Message List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: vm.messages.length,
                    itemBuilder: (context, index) {
                      final msg = vm.messages[index];
                      final isUser = msg.role == 'user';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment:
                              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(top: 4, right: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3F5243),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37),
                                    width: 1.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.smart_toy_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFF2C322B)
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                  border: Border.all(
                                    color: isUser
                                        ? Colors.transparent
                                        : Colors.black.withValues(alpha: 0.08),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  msg.content,
                                  style: TextStyle(
                                    color: isUser ? Colors.white : const Color(0xFF1E1E1E),
                                    fontSize: 13.5,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Loading Indicator
                if (vm.isLoading) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C322B)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Brawijaya Asisten sedang mengetik...',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Quick Prompt Suggestions (Chips)
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildQuickChip('Jam Buka & Tiket', 'Berapa jam buka dan harga tiket museum?'),
                      _buildQuickChip('Sisa Kuota Tiket', 'Berapa sisa kuota tiket hari ini?'),
                      _buildQuickChip('Gerbong Maut', 'Ceritakan tentang koleksi Gerbong Maut'),
                      _buildQuickChip('Meriam Si Jagur', 'Apa itu Meriam Si Jagur?'),
                      _buildQuickChip('Kontak Admin', 'Bagaimana cara menghubungi admin museum?'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Input Area
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EFE6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _handleSend(),
                            decoration: const InputDecoration(
                              hintText: 'Tanyakan sesuatu tentang museum...',
                              hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF2C322B),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          tooltip: 'Kirim Pesan',
                          onPressed: vm.isLoading ? null : () => _handleSend(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickChip(String label, String prompt) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF2C322B), fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        onPressed: () => _handleSend(prompt),
      ),
    );
  }
}
