/// Chat Feature - ChatPage (Halaman Percakapan)
/// Premium UI dengan DeepUI, DeepUX & DeepAnimation principles
/// Includes: Staggered animations, spring physics, micro-interactions

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/chat/data/chat_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final ChatService _chatService = ChatService();

  // === DeepAnimation Controllers ===
  late AnimationController _pageEntryController;
  late AnimationController _inputAreaController;

  // Staggered animations
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _inputFadeAnimation;
  late Animation<Offset> _inputSlideAnimation;
  late Animation<double> _inputScaleAnimation;

  final List<_ChatBubble> _messages = [];
  bool _isTyping = false;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _messageController.addListener(_onTextChanged);
  }

  void _setupAnimations() {
    // === Page Entry Animation (untuk header/body) ===
    _pageEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Header masuk dengan fade + slide dari atas
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageEntryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageEntryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // === Input Area Animation (masuk dari bawah dengan bounce) ===
    _inputAreaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _inputFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _inputAreaController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    _inputSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _inputAreaController,
        // Spring-like curve untuk bounce effect
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );
    _inputScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _inputAreaController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Start animations dengan stagger
    _pageEntryController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _inputAreaController.forward();
    });

    // Add welcome message dengan delay untuk efek dramatis
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _addBotMessage(_chatService.getWelcomeMessage());
      }
    });
  }

  @override
  void dispose() {
    _pageEntryController.dispose();
    _inputAreaController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _canSend = _messageController.text.trim().isNotEmpty;
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(_ChatBubble(
        text: text,
        isUser: false,
        time: _formatTime(DateTime.now()),
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(_ChatBubble(
        text: text,
        isUser: true,
        time: _formatTime(DateTime.now()),
      ));
    });
    _scrollToBottom();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    _messageController.clear();
    _addUserMessage(text);

    setState(() => _isTyping = true);

    // Get AI response
    final response = await _chatService.sendMessage(text);

    setState(() => _isTyping = false);
    _addBotMessage(response);
  }

  void _onVoicePressed() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fitur voice sedang dalam pengembangan 🎤'),
        backgroundColor: AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Chat Messages Area dengan fade animation
          Expanded(
            child: FadeTransition(
              opacity: _headerFadeAnimation,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  return _AnimatedMessageBubble(
                    bubble: _messages[index],
                    index: index,
                  );
                },
              ),
            ),
          ),

          // Input Area dengan slide + scale animation
          SlideTransition(
            position: _inputSlideAnimation,
            child: FadeTransition(
              opacity: _inputFadeAnimation,
              child: ScaleTransition(
                scale: _inputScaleAnimation,
                child: _buildInputArea(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: SlideTransition(
        position: _headerSlideAnimation,
        child: FadeTransition(
          opacity: _headerFadeAnimation,
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.grey.shade700, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: Row(
        children: [
          // Bot Avatar with Hero transition from Welcome Page
          Hero(
            tag: 'chatbot_avatar',
            // Smooth flight shuttle untuk transisi yang lebih halus
            flightShuttleBuilder:
                (flightContext, animation, direction, fromContext, toContext) {
              // Simplified Hero transition - return the destination widget
              return FadeTransition(
                opacity: animation,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/chatbot_avatar.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/chatbot_avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    child: Icon(Icons.smart_toy_rounded,
                        color: AppConstants.primaryColor, size: 24),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info dengan staggered fade
          Expanded(
            child: SlideTransition(
              position: _headerSlideAnimation,
              child: FadeTransition(
                opacity: _headerFadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TemanKu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Row(
                      children: [
                        // Animated online indicator
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Aktif - Siap Mendengarkan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        SlideTransition(
          position: _headerSlideAnimation,
          child: FadeTransition(
            opacity: _headerFadeAnimation,
            child: IconButton(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600),
              onPressed: () {},
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade100, height: 1),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            child: ClipOval(
              child: Image.asset(
                'assets/images/chatbot_avatar.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.primaryColor,
                        AppConstants.primaryColor.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Voice Button with micro-interaction
            _AnimatedIconButton(
              icon: Icons.mic_rounded,
              onPressed: _onVoicePressed,
              backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
              iconColor: AppConstants.primaryColor,
            ),

            const SizedBox(width: 8),

            // Text Input
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _inputFocusNode,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),

            const SizedBox(width: 8),

            // Send Button with scale animation
            AnimatedScale(
              scale: _canSend ? 1.0 : 0.85,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: _canSend ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: _AnimatedIconButton(
                  icon: Icons.send_rounded,
                  onPressed: _canSend && !_isTyping ? _sendMessage : null,
                  backgroundColor: _canSend
                      ? AppConstants.primaryColor
                      : Colors.grey.shade300,
                  iconColor: _canSend ? Colors.white : Colors.grey.shade500,
                  isGradient: _canSend,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === DeepAnimation: Animated Message Bubble ===
class _AnimatedMessageBubble extends StatelessWidget {
  final _ChatBubble bubble;
  final int index;

  const _AnimatedMessageBubble({required this.bubble, required this.index});

  @override
  Widget build(BuildContext context) {
    // Simple, smooth fade + slide animation
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)), // Slide up dari bawah
            child: child,
          ),
        );
      },
      child: _buildBubbleContent(context),
    );
  }

  Widget _buildBubbleContent(BuildContext context) {
    final isUser = bubble.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot Avatar
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/chatbot_avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppConstants.primaryColor,
                          AppConstants.primaryColor.withOpacity(0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],

          // Message Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppConstants.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bubble.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isUser ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bubble.time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === DeepAnimation: Typing Dots ===
class _TypingDots extends StatelessWidget {
  const _TypingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 200)),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            // Looping bounce effect
            final bounce = (0.5 - (value - 0.5).abs()) * 2;
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              transform: Matrix4.translationValues(0, -3 * bounce, 0),
              decoration: BoxDecoration(
                color:
                    AppConstants.primaryColor.withOpacity(0.4 + (bounce * 0.6)),
                shape: BoxShape.circle,
              ),
            );
          },
          onEnd: () {},
        );
      }),
    );
  }
}

// === DeepAnimation: Animated Icon Button ===
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final bool isGradient;

  const _AnimatedIconButton({
    required this.icon,
    this.onPressed,
    required this.backgroundColor,
    required this.iconColor,
    this.isGradient = false,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: widget.onPressed != null ? _onTapCancel : null,
      onTap: () {
        widget.onPressed?.call();
        HapticFeedback.lightImpact();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: widget.isGradient
                ? LinearGradient(
                    colors: [
                      widget.backgroundColor,
                      widget.backgroundColor.withOpacity(0.8),
                    ],
                  )
                : null,
            color: widget.isGradient ? null : widget.backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: widget.iconColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Model internal untuk bubble chat
class _ChatBubble {
  final String text;
  final bool isUser;
  final String time;

  _ChatBubble({
    required this.text,
    required this.isUser,
    required this.time,
  });
}
