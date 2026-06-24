import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_webrtc/flutter_webrtc.dart';

class RtcManager {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _latestRemoteStream;
  StreamController<MediaStream>? _remoteStreamController;
  StreamController<RTCPeerConnectionState>? _connectionStateController;
  RTCDataChannel? _dataChannel;

  Stream<MediaStream> get remoteStream {
    _remoteStreamController ??= StreamController<MediaStream>.broadcast();
    return _remoteStreamController!.stream;
  }

  Stream<RTCPeerConnectionState> get connectionState {
    _connectionStateController ??= StreamController<RTCPeerConnectionState>.broadcast();
    return _connectionStateController!.stream;
  }

  RTCPeerConnection? get peerConnection => _peerConnection;
  MediaStream? get latestRemoteStream => _latestRemoteStream;
  MediaStream? get localStream => _localStream;

  Future<void> createConnection({
    List<Map<String, dynamic>>? iceServers,
    Function(Map<String, dynamic> candidate)? onCandidate,
  }) async {
    developer.log('RTC createConnection', name: 'RtcManager');
    _remoteStreamController ??= StreamController<MediaStream>.broadcast();
    _connectionStateController ??= StreamController<RTCPeerConnectionState>.broadcast();

    if (_peerConnection != null) {
      developer.log('RTC closing existing connection', name: 'RtcManager');
      _dataChannel?.close();
      _dataChannel = null;
      await _peerConnection!.close();
      _peerConnection = null;
    }

    final config = <String, dynamic>{
      'iceServers': iceServers ?? [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (candidate) {
      developer.log('RTC onIceCandidate', name: 'RtcManager');
      onCandidate?.call({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _peerConnection!.onTrack = (event) {
      developer.log('RTC onTrack: kind=${event.track.kind}, streams=${event.streams.length}', name: 'RtcManager');
      if (event.streams.isNotEmpty) {
        _latestRemoteStream = event.streams[0];
        _remoteStreamController?.add(event.streams[0]);
      } else if (_latestRemoteStream != null) {
        _latestRemoteStream!.addTrack(event.track);
        _remoteStreamController?.add(_latestRemoteStream!);
      }
    };

    _peerConnection!.onConnectionState = (state) {
      developer.log('RTC state: $state', name: 'RtcManager');
      _connectionStateController?.add(state);
    };

    _peerConnection!.onIceConnectionState = (state) {
      developer.log('RTC ice state: $state', name: 'RtcManager');
    };
  }

  Future<void> addTransceivers({TransceiverDirection direction = TransceiverDirection.RecvOnly}) async {
    if (_peerConnection == null) return;
    await _peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: direction),
    );
    await _peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: direction),
    );
    developer.log('RTC transceivers added ($direction)', name: 'RtcManager');
  }

  Future<void> ensureDataChannel() async {
    if (_peerConnection == null || _dataChannel != null) return;
    _dataChannel = await _peerConnection!.createDataChannel('control', RTCDataChannelInit());
    developer.log('RTC dataChannel created', name: 'RtcManager');
  }

  Future<void> setLocalStream(MediaStream stream) async {
    _localStream = stream;
    for (final track in stream.getTracks()) {
      _peerConnection?.addTrack(track, stream);
    }
  }

  Future<void> createOfferAndSend(
    Function(Map<String, dynamic> offer) onOffer,
  ) async {
    developer.log('RTC createOfferAndSend', name: 'RtcManager');
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    onOffer({
      'type': offer.type,
      'sdp': offer.sdp,
    });
  }

  Future<void> handleOffer(Map<String, dynamic> offer) async {
    developer.log('RTC handleOffer', name: 'RtcManager');
    final sdp = offer['sdp'] as String;
    final type = (offer['type'] as String?) ?? 'offer';
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, type),
    );
  }

  Future<Map<String, dynamic>> createAnswer() async {
    developer.log('RTC createAnswer', name: 'RtcManager');
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return {'type': answer.type, 'sdp': answer.sdp};
  }

  Future<void> handleAnswer(Map<String, dynamic> answer) async {
    developer.log('RTC handleAnswer', name: 'RtcManager');
    final sdp = answer['sdp'] as String;
    final type = (answer['type'] as String?) ?? 'answer';
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, type),
    );
  }

  Future<void> addCandidate(Map<String, dynamic> candidate) async {
    developer.log('RTC addCandidate', name: 'RtcManager');
    await _peerConnection?.addCandidate(
      RTCIceCandidate(
        candidate['candidate'],
        candidate['sdpMid'],
        candidate['sdpMLineIndex'],
      ),
    );
  }

  void dispose() {
    developer.log('RTC dispose', name: 'RtcManager');
    if (_peerConnection != null) {
      _peerConnection!.onIceCandidate = null;
      _peerConnection!.onTrack = null;
      _peerConnection!.onConnectionState = null;
      _peerConnection!.onIceConnectionState = null;
      _peerConnection!.onDataChannel = null;
      _peerConnection!.close();
      _peerConnection = null;
    }
    _dataChannel?.close();
    _dataChannel = null;
    _localStream?.dispose();
    _localStream = null;
    _latestRemoteStream = null;

  }
}
