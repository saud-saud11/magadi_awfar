import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class VoiceBasketScreen extends StatefulWidget {
  final Function(ProductItem) onAddToBasket;
  final VoidCallback onNavigateToBasketCompare;

  const VoiceBasketScreen({
    super.key,
    required this.onAddToBasket,
    required this.onNavigateToBasketCompare,
  });

  @override
  State<VoiceBasketScreen> createState() => _VoiceBasketScreenState();
}

class _VoiceBasketScreenState extends State<VoiceBasketScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final String _sessionId = 'mobile_user_session';
  bool _isRecording = false;
  bool _isLoading = false;
  String? _lastSpokenText;
  String? _statusMessage;
  bool _canUndo = false;

  // Clarification state
  String? _clarificationQuestion;
  List<String> _clarificationOptions = [];

  // Items currently recognized in the voice basket session
  List<VoiceBasketItem> _sessionItems = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _exampleVoiceCommands = [
    'أبي حليب السعودية واثنين جبن كيري وخبز توست',
    'لا خله كبير',
    'زيد واحدة',
    'خله اثنين',
    'شيل التوست',
    'لا تضيف عصير',
    'رجّع آخر تعديل',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fetchSession();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _fetchSession() async {
    // Initial parse to fetch existing items if any
    final res = await ApiService.parseVoiceCommand(
      query: '',
      sessionId: _sessionId,
    );
    if (res != null && mounted) {
      setState(() {
        _sessionItems = res.currentBasket;
        _canUndo = res.canUndo;
      });
    }
  }

  Future<void> _executeVoiceQuery(String queryText) async {
    final text = queryText.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _lastSpokenText = text;
      _clarificationQuestion = null;
      _clarificationOptions = [];
    });

    final res = await ApiService.parseVoiceCommand(
      query: text,
      sessionId: _sessionId,
      requestId: 'req_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res != null) {
          _statusMessage = res.messageAr;
          _sessionItems = res.currentBasket;
          _canUndo = res.canUndo;

          if (res.status == 'clarification_needed' && res.clarificationQuestion != null) {
            _clarificationQuestion = res.clarificationQuestion;
            _clarificationOptions = res.clarificationOptions;
          }
        } else {
          _statusMessage = 'تعذر معالجة الطلب، يرجى المحاولة مرة أخرى.';
        }
      });
    }
  }

  Future<void> _handleUndo() async {
    setState(() => _isLoading = true);
    final res = await ApiService.undoVoiceCommand(sessionId: _sessionId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res != null) {
          _statusMessage = res.messageAr;
          _sessionItems = res.currentBasket;
          _canUndo = res.canUndo;
        }
      });
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      // Stop recording and process
      setState(() => _isRecording = false);
      _executeVoiceQuery('أبي حليب السعودية واثنين جبن كيري وخبز توست');
    } else {
      // Start recording
      setState(() {
        _isRecording = true;
        _statusMessage = 'جاري الاستماع... تحدّث بلهجتك الطبيعية';
      });

      // Simulate voice completion after 2.5 seconds if user stops speaking
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (_isRecording && mounted) {
          setState(() => _isRecording = false);
          _executeVoiceQuery('أبي حليب السعودية واثنين جبن كيري وخبز توست');
        }
      });
    }
  }

  void _pushAllToComparisonBasket() {
    for (var item in _sessionItems) {
      for (int i = 0; i < item.quantity; i++) {
        widget.onAddToBasket(item.toProductItem());
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نقل ${_sessionItems.length} أصناف إلى مقارنة السلة'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.onNavigateToBasketCompare();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('السلة الصوتية بالذكاء الاصطناعي'),
          actions: [
            if (_canUndo)
              TextButton.icon(
                onPressed: _isLoading ? null : _handleUndo,
                icon: const Icon(Icons.undo, color: Colors.white, size: 20),
                label: const Text(
                  'تراجع',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Hero Voice Assistant Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Microphone Button with Pulse Animation
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: ScaleTransition(
                      scale: _isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? Colors.red.shade600 : AppTheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording ? Colors.red : AppTheme.primary).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: _isRecording ? 8 : 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isRecording
                        ? 'نسمعك الآن... جارٍ التقاط الصوت'
                        : 'اضغط على الميكروفون أو اكتب طلبك بالأسفل',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _isRecording ? Colors.red.shade700 : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'يدعم اللهجة السعودية: «حبتين حليب السعودية»، «لا خله كبير»، «زيد واحدة»',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Transcript / Status Card
            if (_lastSpokenText != null || _statusMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.record_voice_over, color: AppTheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_lastSpokenText != null)
                            Text(
                              '«$_lastSpokenText»',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          if (_statusMessage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _statusMessage!,
                              style: const TextStyle(fontSize: 13, color: AppTheme.primary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Clarification Question with Clickable Option Chips (Section 7)
            if (_clarificationQuestion != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.amber.shade800, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _clarificationQuestion!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _clarificationOptions.map((opt) {
                        return ActionChip(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.amber.shade400),
                          label: Text(opt, style: const TextStyle(fontSize: 12)),
                          onPressed: () => _executeVoiceQuery('شيل $opt'),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            // Quick Example Command Chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _exampleVoiceCommands.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final cmd = _exampleVoiceCommands[i];
                  return ActionChip(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    label: Text(cmd, style: const TextStyle(fontSize: 12)),
                    onPressed: _isLoading ? null : () => _executeVoiceQuery(cmd),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Items List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أصناف السلة الصوتية (${_sessionItems.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (_sessionItems.isNotEmpty)
                    TextButton(
                      onPressed: () => _executeVoiceQuery('شيل الكل'),
                      child: const Text('تفريغ السلة', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),

            // Items List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sessionItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text(
                                'السلة الصوتية فارغة',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'جرّب قول «أبي حليب السعودية واثنين جبن كيري»',
                                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _sessionItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final item = _sessionItems[idx];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Product Image / Icon
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.inventory_2, color: AppTheme.primary, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.nameAr,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (item.brandAr != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  item.brandAr!,
                                                  style: const TextStyle(fontSize: 11, color: AppTheme.textDark),
                                                ),
                                              ),
                                            const SizedBox(width: 6),
                                            if (item.notes != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  item.notes!,
                                                  style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quantity Controls
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, size: 22),
                                        color: Colors.grey.shade600,
                                        onPressed: () => _executeVoiceQuery('نقص حبة من ${item.nameAr}'),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 22),
                                        color: AppTheme.primary,
                                        onPressed: () => _executeVoiceQuery('زيد حبة على ${item.nameAr}'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // Bottom Typing Input & Compare Basket Action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
                ],
              ),
              child: Column(
                children: [
                  // Text Correction Input (Section 5 & 7)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'أو اكتب هنا للتصحيح: مثلاً «خله اثنين»...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          onSubmitted: (val) {
                            _executeVoiceQuery(val);
                            _textController.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.send, size: 20),
                        onPressed: () {
                          if (_textController.text.trim().isNotEmpty) {
                            _executeVoiceQuery(_textController.text);
                            _textController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Compare Basket Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.compare_arrows),
                      label: Text(
                        _sessionItems.isEmpty
                            ? 'قارن السلة بين المتاجر'
                            : 'قارن سلة المشتريات (${_sessionItems.length} أصناف)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _sessionItems.isEmpty ? null : _pushAllToComparisonBasket,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
