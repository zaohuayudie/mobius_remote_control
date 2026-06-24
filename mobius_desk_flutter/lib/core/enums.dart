enum WsEventType {
  deskJoin('desk:join'),
  deskJoined('desk:joined'),
  deskUpdateStatus('desk:update-status'),
  deskStartRemote('desk:start-remote'),
  deskStartRemoteResult('desk:start-remote-result'),
  deskAcceptRemote('desk:accept-remote'),
  deskRejectRemote('desk:reject-remote'),
  deskStopRemoteResult('desk:stop-remote-result'),
  deskOffer('desk:offer'),
  deskAnswer('desk:answer'),
  deskCandidate('desk:candidate'),
  deskBehavior('desk:behavior'),
  deskChangeParams('desk:change-params'),
  deskStopRemote('desk:stop-remote');

  const WsEventType(this.value);
  final String value;
}

enum DeskBehaviorType {
  mouseMove('mouseMove'),
  mouseDrag('mouseDrag'),
  leftClick('leftClick'),
  rightClick('rightClick'),
  doubleClick('doubleClick'),
  pressButtonLeft('pressButtonLeft'),
  releaseButtonLeft('releaseButtonLeft'),
  scrollUp('scrollUp'),
  scrollDown('scrollDown'),
  scrollLeft('scrollLeft'),
  scrollRight('scrollRight'),
  keyboardType('keyboardType'),
  keyboardPressKey('keyboardPressKey'),
  keyboardReleaseKey('keyboardReleaseKey'),
  performDown('performDown'),
  performMove('performMove'),
  performUp('performUp');

  const DeskBehaviorType(this.value);
  final String value;
}

enum Resolution {
  p360('360p', 640, 360),
  p480('480p', 854, 480),
  p720('720p', 1280, 720),
  p1080('1080p', 1920, 1080),
  p2k('2k', 2560, 1440),
  p4k('4k', 3840, 2160);

  const Resolution(this.label, this.width, this.height);
  final String label;
  final int width;
  final int height;
}

enum VideoContentHint {
  fluid('fluid', '流畅'),
  detailed('detailed', '细节'),
  text('text', '文本');

  const VideoContentHint(this.value, this.label);
  final String value;
  final String label;
}

enum AudioContentHint {
  speech('speech', '语音'),
  music('music', '音乐');

  const AudioContentHint(this.value, this.label);
  final String value;
  final String label;
}

enum ConnectionMode {
  control,
  view,
}