import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class EngageAudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _humPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isHumming = false;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isHumming => _isHumming;

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
      await stopHumming();

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
      print('[EngageAI Audio] Recording start error: $e');
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
      print('[EngageAI Audio] Recording stop error: $e');
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
      await stopHumming();
      if (_isPlaying) await _player.stop();

      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/engageai_tts_response.mp3');
      await tempFile.writeAsBytes(audioBytes);

      _isPlaying = true;
      await _player.setFilePath(tempFile.path);
      await _player.play();
    } catch (e) {
      print('[EngageAI Audio] Playback error: $e');
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

  /// Start a gentle thinking hum sound.
  /// Generates a simple tone programmatically as a WAV file.
  Future<void> startHumming() async {
    if (_isHumming || _isPlaying || _isRecording) return;

    try {
      final dir = await getTemporaryDirectory();
      final humFile = File('${dir.path}/engageai_hum.wav');

      // Generate a gentle hum WAV
      if (!await humFile.exists()) {
        final wavBytes = _generateHumWav();
        await humFile.writeAsBytes(wavBytes);
      }

      _isHumming = true;
      await _humPlayer.setFilePath(humFile.path);
      await _humPlayer.setLoopMode(LoopMode.one);
      await _humPlayer.setVolume(0.15);
      await _humPlayer.play();
    } catch (e) {
      print('[EngageAI Audio] Hum error: $e');
      _isHumming = false;
    }
  }

  /// Stop the thinking hum.
  Future<void> stopHumming() async {
    if (!_isHumming) return;
    try {
      await _humPlayer.stop();
      _isHumming = false;
    } catch (_) {
      _isHumming = false;
    }
  }

  /// Generate a gentle humming WAV file.
  /// Creates a soft, warm tone that loops smoothly.
  Uint8List _generateHumWav() {
    const sampleRate = 22050;
    const durationSec = 2.0;
    final numSamples = (sampleRate * durationSec).toInt();
    const numChannels = 1;
    const bitsPerSample = 16;

    final samples = List<int>.filled(numSamples, 0);
    final rng = Random(42);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      // Base frequency — warm low hum around 180Hz
      final base = sin(2 * pi * 180 * t) * 0.3;

      // Soft harmonic at 270Hz
      final harmonic1 = sin(2 * pi * 270 * t) * 0.12;

      // Very subtle wobble
      final wobble = sin(2 * pi * 3.5 * t) * 0.08;

      // Combine
      var sample = (base + harmonic1) * (0.85 + wobble);

      // Fade in/out for seamless loop (first and last 0.1s)
      const fadeLen = sampleRate * 0.1;
      if (i < fadeLen) {
        sample *= i / fadeLen;
      } else if (i > numSamples - fadeLen) {
        sample *= (numSamples - i) / fadeLen;
      }

      // Clamp and convert to 16-bit
      sample = sample.clamp(-1.0, 1.0);
      samples[i] = (sample * 16000).toInt();
    }

    // Build WAV file
    final dataSize = numSamples * numChannels * (bitsPerSample ~/ 8);
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);
    int offset = 0;

    // RIFF header
    void writeString(String s) {
      for (int i = 0; i < s.length; i++) {
        buffer.setUint8(offset++, s.codeUnitAt(i));
      }
    }

    writeString('RIFF');
    buffer.setUint32(offset, fileSize, Endian.little); offset += 4;
    writeString('WAVE');

    // fmt chunk
    writeString('fmt ');
    buffer.setUint32(offset, 16, Endian.little); offset += 4;
    buffer.setUint16(offset, 1, Endian.little); offset += 2; // PCM
    buffer.setUint16(offset, numChannels, Endian.little); offset += 2;
    buffer.setUint32(offset, sampleRate, Endian.little); offset += 4;
    buffer.setUint32(offset, sampleRate * numChannels * (bitsPerSample ~/ 8), Endian.little); offset += 4;
    buffer.setUint16(offset, numChannels * (bitsPerSample ~/ 8), Endian.little); offset += 2;
    buffer.setUint16(offset, bitsPerSample, Endian.little); offset += 2;

    // data chunk
    writeString('data');
    buffer.setUint32(offset, dataSize, Endian.little); offset += 4;

    for (int i = 0; i < numSamples; i++) {
      buffer.setInt16(offset, samples[i], Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  Future<void> interruptAll() async {
    await stopPlayback();
    await stopHumming();
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
    await stopHumming();
    await _player.dispose();
    await _humPlayer.dispose();
    _recorder.dispose();
  }
}