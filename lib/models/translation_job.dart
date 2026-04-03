// lib/models/translation_job.dart

enum JobStatus { pending, processing, done, error }

class TranslationJob {
  final String jobId;
  final String videoId;
  final String targetLanguage;
  final JobStatus status;
  final int progress; // 0-100
  final String? currentStep;
  final int? estimatedRemaining; // secondes
  final String? errorMessage;
  final String? outputUrl;

  const TranslationJob({
    required this.jobId,
    required this.videoId,
    required this.targetLanguage,
    this.status = JobStatus.pending,
    this.progress = 0,
    this.currentStep,
    this.estimatedRemaining,
    this.errorMessage,
    this.outputUrl,
  });

  factory TranslationJob.fromJson(Map<String, dynamic> json) {
    return TranslationJob(
      jobId: json['job_id'] as String,
      videoId: json['video_id'] as String? ?? '',
      targetLanguage: json['target_language'] as String? ?? '',
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      progress: json['progress'] as int? ?? 0,
      currentStep: json['current_step'] as String?,
      estimatedRemaining: json['estimated_remaining'] as int?,
      errorMessage: json['error_message'] as String?,
      outputUrl: json['output_url'] as String?,
    );
  }

  static JobStatus _parseStatus(String s) {
    switch (s) {
      case 'processing':
        return JobStatus.processing;
      case 'done':
        return JobStatus.done;
      case 'error':
        return JobStatus.error;
      default:
        return JobStatus.pending;
    }
  }

  /// Libellé lisible de l'étape en cours
  String get stepLabel {
    switch (currentStep) {
      case 'audio_extraction':
        return 'Extraction audio…';
      case 'speech_to_text':
        return 'Transcription Whisper…';
      case 'emotion_analysis':
        return 'Analyse du ton…';
      case 'translation':
        return 'Traduction NLP…';
      case 'tts_synthesis':
        return 'Synthèse vocale & clonage…';
      case 'synchronization':
        return 'Synchronisation vidéo…';
      case 'finalization':
        return 'Finalisation…';
      default:
        return 'En attente…';
    }
  }
}