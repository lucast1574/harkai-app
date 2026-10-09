import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../shared/widgets.dart';

class VoiceInput extends StatefulWidget {
  final bool disabled;
  final void Function(String, Analysis) onTranscript;
  const VoiceInput({
    super.key,
    required this.disabled,
    required this.onTranscript,
  });
  @override
  State<VoiceInput> createState() => _VoiceInputState();
}

class _VoiceInputState extends State<VoiceInput> {
  final recorder = AudioRecorder();
  Timer? timer;
  String? path, error;
  bool recording = false, busy = false;
  int seconds = 0;
  @override
  void dispose() {
    timer?.cancel();
    unawaited(cleanup());
    super.dispose();
  }

  Future<bool> cleanup() async {
    await recorder.dispose();
    if (path != null) await removeRecording(path!);
    return true;
  }

  Future<bool> removeRecording(String value) async {
    final file = File(value);
    if (await file.exists()) await file.delete();
    return true;
  }

  Future<bool> start() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (!await recorder.hasPermission()) {
        throw Exception(
          'Permite el micrófono para describir con tu voz. También puedes escribir.',
        );
      }
      final directory = await getTemporaryDirectory();
      path =
          '${directory.path}/harkai-${DateTime.now().microsecondsSinceEpoch}.wav';
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path!,
      );
      if (!mounted) {
        await recorder.cancel();
        return false;
      }
      setState(() {
        recording = true;
        seconds = 0;
      });
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => seconds++);
        if (seconds >= 59) unawaited(finish());
      });
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> finish() async {
    if (busy || !recording) return false;
    timer?.cancel();
    setState(() {
      busy = true;
      recording = false;
      error = null;
    });
    final api = AppScope.of(context).api;
    try {
      final value = await recorder.stop();
      if (value == null) throw Exception('No pudimos grabar el audio.');
      final file = File(value);
      if (await file.length() > 4 * 1024 * 1024) {
        throw Exception('El audio debe ocupar hasta 4 MB.');
      }
      final result = await api.request(
        'POST',
        'analysis/audio',
        bytes: await file.readAsBytes(),
        contentType: 'audio/wav',
      );
      if (mounted) {
        widget.onTranscript(
          result['text'] as String,
          Analysis.fromJson(result['analysis'] as Map<String, dynamic>),
        );
      }
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    } finally {
      if (path != null) await removeRecording(path!);
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      OutlinedButton.icon(
        onPressed: widget.disabled || busy
            ? null
            : recording
            ? finish
            : start,
        icon: Icon(recording ? Icons.stop : Icons.mic_none),
        label: Text(
          busy
              ? 'Transcribiendo…'
              : recording
              ? 'Finalizar audio · $seconds s'
              : 'Describir con mi voz',
        ),
      ),
      const Text(
        'Hasta 60 segundos. Revisa y corrige el texto antes de publicar.',
      ),
      if (error != null) MessageCard(error!, error: true),
      const SizedBox(height: 16),
    ],
  );
}
