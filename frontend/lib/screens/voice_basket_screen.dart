import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import '../widgets/ui/ui_kit.dart';

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

class _VoiceBasketScreenState extends State<VoiceBasketScreen> with TickerProviderStateMixin {
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
  late AnimationController _waveController;

  final List<String> _exampleVoiceCommands = [
    'أبي حليب السعودية واثنين جبن كيري وخبز توست',
    'لا خله كبير',
    'زيد واحدة',
    'خله اثنين',
    'شيل التوست',
    'لا تضيف عصير',
    'رجّع آخر تعديل',
  ];

  void _startAnimations() {
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
    if (!_waveController.isAnimating) {
      _waveController.repeat();
    }
  }

  void _stopAnimations() {
    if (_pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
    if (_waveController.isAnimating) {
      _waveController.stop();
      _waveController.reset();
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fetchSession();
  }

  @override
  void dispose() {
    VoiceRecognitionService.stopListening();
    _pulseController.dispose();
    _waveController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _fetchSession() async {
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
      VoiceRecognitionService.stopListening();
      _stopAnimations();
      setState(() => _isRecording = false);
      return;
    }

    if (!VoiceRecognitionService.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('التعرف الصوتي غير مدعوم في هذا المتصفح. يمكنك كتابة طلبك بالأسفل.'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _statusMessage = 'المتصفح لا يدعم ميزة المايك مباشرة، يمكنك الكتابة في الحقل أدناه.';
      });
      return;
    }

    _startAnimations();
    setState(() {
      _isRecording = true;
      _statusMessage = 'جاري الاستماع... تحدّث بلهجتك الطبيعية الآن';
      _lastSpokenText = null;
    });

    final started = VoiceRecognitionService.startListening(
      onStart: () {
        if (mounted) {
          _startAnimations();
          setState(() {
            _isRecording = true;
            _statusMessage = 'نسمعك الآن... تحدّث بوضوح';
          });
        }
      },
      onResult: (transcript, isFinal) {
        if (mounted) {
          setState(() {
            _lastSpokenText = transcript;
            _statusMessage = isFinal ? 'تم التقاط الكلام' : 'نسمعك الآن...';
          });
        }
      },
      onError: (err) {
        if (mounted) {
          _stopAnimations();
          setState(() {
            _isRecording = false;
            if (err == 'no-speech') {
              _statusMessage = 'لم يتم التقاط أي صوت، يرجى التحدث بوضوح أو كتابة طلبك بالأسفل.';
            } else if (err == 'not-allowed' || err == 'permission-denied') {
              _statusMessage = 'يرجى السماح بصلاحية المايكروفون في إعدادات المتصفح.';
            } else {
              _statusMessage = 'توقف الاستماع ($err). يمكنك كتابة طلبك بالأسفل.';
            }
          });
        }
      },
      onEnd: (finalTranscript) {
        if (mounted) {
          _stopAnimations();
          setState(() => _isRecording = false);
          final text = finalTranscript.trim();
          if (text.isNotEmpty) {
            _executeVoiceQuery(text);
          } else {
            setState(() {
              _statusMessage = 'لم يتم التقاط أي كلام، يرجى الضغط على المايك والتحدث بوضوح.';
            });
          }
        }
      },
    );

    if (!started && mounted) {
      _stopAnimations();
      setState(() {
        _isRecording = false;
        _statusMessage = 'تعذر تشغيل المايكروفون، يرجى مراجعة إذن المتصفح.';
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
        content: Text('تم نقل ${_sessionItems.length} أصناف إلى مقارنة السلة ✨'),
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
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _handleUndo,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('تراجع', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // ── Glowing Microphone Orb Header ─────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: ScaleTransition(
                      scale: _isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isRecording
                              ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                              : AppTheme.heroGradient,
                          border: Border.all(
                            color: _isRecording ? Colors.white : AppTheme.accentGold,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording ? Colors.red : AppTheme.primary).withOpacity(0.4),
                              blurRadius: 28,
                              spreadRadius: _isRecording ? 10 : 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Sound waves animation when listening
                  if (_isRecording)
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (_, __) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(7, (i) {
                            final phase = (i * 0.4 + _waveController.value * 2 * math.pi);
                            final height = 8.0 + 16.0 * (0.5 + 0.5 * math.sin(phase));
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              width: 3.5,
                              height: height,
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        );
                      },
                    )
                  else
                    const SizedBox(height: 4),

                  const SizedBox(height: 8),
                  Text(
                    _isRecording ? 'نسمعك الآن... جارٍ التقاط الصوت' : 'اضغط على الميكروفون وتحدّث بحرية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _isRecording ? AppTheme.danger : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'يدعم اللهجة السعودية: «حبتين حليب السعودية»، «لا خله كبير»، «زيد واحدة»',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // ── Live Transcript & Feedback ─────────────────────
            if (_lastSpokenText != null || _statusMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SoftCard(
                  color: AppTheme.primaryContainer.withOpacity(0.6),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.record_voice_over_rounded, color: AppTheme.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_lastSpokenText != null)
                              Text(
                                '«$_lastSpokenText»',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                              ),
                            if (_statusMessage != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _statusMessage!,
                                style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Clarification Question ─────────────────────────
            if (_clarificationQuestion != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SoftCard(
                  color: const Color(0xFFFEF3C7),
                  border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.help_outline_rounded, color: Color(0xFFB45309), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _clarificationQuestion!,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
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
                            side: const BorderSide(color: AppTheme.accentGold),
                            label: Text(opt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            onPressed: () => _executeVoiceQuery('شيل $opt'),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Quick Example Command Chips ────────────────────
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _exampleVoiceCommands.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final cmd = _exampleVoiceCommands[i];
                  return ActionChip(
                    backgroundColor: AppTheme.surface,
                    elevation: 0,
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    label: Text(cmd, style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w600)),
                    onPressed: _isLoading ? null : () => _executeVoiceQuery(cmd),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // ── Recognized Items Header ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أصناف السلة الصوتية (${_sessionItems.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                  ),
                  if (_sessionItems.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _executeVoiceQuery('شيل الكل'),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.danger),
                      label: const Text('تفريغ السلة', style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                    ),
                ],
              ),
            ),

            // ── Items List ─────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sessionItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              EmptyIllustration(icon: Icons.mic_none_rounded, size: 110),
                              const SizedBox(height: 14),
                              const Text(
                                'السلة الصوتية فارغة حالياً',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: _sessionItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final item = _sessionItems[idx];
                            return FadeSlideIn(
                              index: idx,
                              child: SoftCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.inventory_2_rounded, color: AppTheme.primary, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.nameAr,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            children: [
                                              if (item.brandAr != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.surfaceAlt,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(item.brandAr!, style: const TextStyle(fontSize: 10.5, color: AppTheme.textDark)),
                                                ),
                                              if (item.notes != null)
                                                SavingsBadge(item.notes!),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                                          color: AppTheme.textMuted,
                                          onPressed: () => _executeVoiceQuery('نقص حبة من ${item.nameAr}'),
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_rounded, size: 22),
                                          color: AppTheme.primary,
                                          onPressed: () => _executeVoiceQuery('زيد حبة على ${item.nameAr}'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // ── Bottom Typing Input & Compare Basket Action ────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'أو اكتب للتصحيح: مثلاً «خله اثنين»...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.border),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 20),
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
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      label: _sessionItems.isEmpty
                          ? 'قارن السلة بين المتاجر'
                          : 'قارن سلة المشتريات (${_sessionItems.length} أصناف)',
                      icon: Icons.compare_arrows_rounded,
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
