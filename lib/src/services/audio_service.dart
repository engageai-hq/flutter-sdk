import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class EngageAudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;

  void Function()? onPlaybackComplete;
  void Function(double amplitude)? onAmplitudeChange;

  EngageAudioService() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        onPlaybackComplete?.call();
      }
    });
  }

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<bool> startRecording() async {
    try {
      if (_isRecording) return true;
      if (_isPlaying) await stopPlayback();

      final hasPerms = await _recorder.hasPermission();
      if (!hasPerms) return false;

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/engageai_recording.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      _isRecording = true;
      _monitorAmplitude();
      return true;
    } catch (e) {
      debugPrint('[EngageAI Audio] Recording start error: $e');
      return false;
    }
  }

  Future<Uint8List?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _recorder.stop();
      _isRecording = false;

      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          await file.delete();
          return bytes;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[EngageAI Audio] Recording stop error: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
      }
    } catch (e) {
      _isRecording = false;
    }
  }

  Future<void> playAudioBytes(Uint8List audioBytes) async {
    try {
      if (_isPlaying) await _player.stop();

      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/engageai_tts_response.mp3');
      await tempFile.writeAsBytes(audioBytes);

      _isPlaying = true;
      await _player.setFilePath(tempFile.path);
      await _player.play();
    } catch (e) {
      debugPrint('[EngageAI Audio] Playback error: $e');
      _isPlaying = false;
    }
  }

  Future<void> stopPlayback() async {
    try {
      if (_isPlaying) {
        await _player.stop();
        _isPlaying = false;
        onPlaybackComplete?.call();
      }
    } catch (_) {
      _isPlaying = false;
    }
  }

  Future<void> interruptAll() async {
    await stopPlayback();
    await cancelRecording();
  }

  void _monitorAmplitude() async {
    while (_isRecording) {
      try {
        final amplitude = await _recorder.getAmplitude();
        onAmplitudeChange?.call(amplitude.current);
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> dispose() async {
    if (_isRecording) await cancelRecording();
    await _player.dispose();
    _recorder.dispose();
  }
}
