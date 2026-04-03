// lib/screens/processing_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../models/translation_job.dart';
import '../services/api_service.dart';
import '../router/app_router.dart';

class ProcessingScreen extends StatefulWidget {
  final String jobId;
  const ProcessingScreen({super.key, required this.jobId});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  TranslationJob? _job;
  Timer? _pollingTimer;
  final _api = ApiService();

  // Animation pour la barre de progression
  late final AnimationController _pulseCtrl;

  // Les 7 étapes du pipeline
  static const _steps = [
    ('audio_extraction',  'Extraction audio',         Icons.audio_file_outlined),
    ('speech_to_text',    'Transcription Whisper',    Icons.mic_outlined),
    ('emotion_analysis',  'Analyse du ton',           Icons.psychology_outlined),
    ('translation',       'Traduction NLP',           Icons.translate_rounded),
    ('tts_synthesis',     'Clonage vocal & TTS',      Icons.record_voice_over_outlined),
    ('synchronization',   'Synchronisation vidéo',    Icons.sync_rounded),
    ('finalization',      'Finalisation',             Icons.check_circle_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _startPolling();
  }

  void _startPolling() {
    _fetchStatus();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 4),
          (_) => _fetchStatus(),
    );
  }

  Future<void> _fetchStatus() async {
    try {
      final job = await _api.getJobStatus(widget.jobId);
      setState(() => _job = job);

      if (job.status == JobStatus.done && job.outputUrl != null) {
        _pollingTimer?.cancel();
        if (mounted) {
          context.pushReplacement(AppRoutes.player, extra: job.outputUrl);
        }
      } else if (job.status == JobStatus.error) {
        _pollingTimer?.cancel();
      }
    } catch (_) { /* retry silencieux */ }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  int get _currentStepIndex {
    if (_job == null) return 0;
    final idx = _steps.indexWhere((s) => s.$1 == _job!.currentStep);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _job?.progress ?? 0;
    final isError  = _job?.status == JobStatus.error;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Traduction en cours'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // ── Cercle de progression ─────────────────────────────────────
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160, height: 160,
                    child: CircularProgressIndicator(
                      value: progress / 100,
                      strokeWidth: 8,
                      backgroundColor: AppColors.border,
                      color: isError ? AppColors.error : AppColors.primary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$progress%',
                        style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_job?.estimatedRemaining != null)
                        Text(
                          '~${_job!.estimatedRemaining}s restantes',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Étape courante ────────────────────────────────────────────
            if (!isError)
              Center(
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) => Opacity(
                    opacity: 0.6 + _pulseCtrl.value * 0.4,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      _job?.stepLabel ?? 'Initialisation…',
                      style: const TextStyle(
                        fontSize: 13, color: AppColors.primaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            // ── Message d'erreur ──────────────────────────────────────────
            if (isError) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withOpacity(0.4)),
                ),
                child: Text(
                  _job?.errorMessage ?? 'Une erreur est survenue',
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bgSurface),
                child: const Text('Retour à la bibliothèque'),
              ),
            ],

            const SizedBox(height: 32),

            // ── Étapes du pipeline ────────────────────────────────────────
            const Text('Pipeline de traitement',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
            const SizedBox(height: 12),
            ..._steps.asMap().entries.map((entry) {
              final i    = entry.key;
              final step = entry.value;
              final isDone    = i < _currentStepIndex;
              final isCurrent = i == _currentStepIndex &&
                  _job?.status == JobStatus.processing;
              return _PipelineStep(
                icon: step.$3,
                label: step.$2,
                isDone: isDone,
                isCurrent: isCurrent,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PipelineStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;
  final bool isCurrent;

  const _PipelineStep({
    required this.icon, required this.label,
    required this.isDone, required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    if (isDone) color = AppColors.accent;
    else if (isCurrent) color = AppColors.primary;
    else color = AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(
              isDone ? Icons.check_rounded : icon,
              color: color, size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDone || isCurrent
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}