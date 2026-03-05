import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../core/chat/call_service.dart';
import '../../../core/theme/app_colors.dart';

class CallScreen extends StatefulWidget {
  final CallModel call;
  final bool isIncoming;

  const CallScreen({super.key, required this.call, required this.isIncoming});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late RtcEngine _engine;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _videoDisabled = false;

  // IMPORTANT: Replace with actual Agora App ID if available.
  // For now using a placeholder string.
  static const String appId = "91d1ce4da0dc4b6983ecb18fe5d4960f";

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // 1. Request permissions
    await [Permission.microphone, Permission.camera].request();

    // 2. Initialize engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user ${connection.localUid} joined");
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user $remoteUid joined");
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint("Remote user $remoteUid left");
              setState(() => _remoteUid = null);
              _endCall();
            },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint("Local user left channel");
        },
      ),
    );

    if (widget.call.isVideo) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.disableVideo();
    }

    // 3. Join channel
    await _engine.joinChannel(
      token: '', // Use a token server in production
      channelId: widget.call.channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _switchCamera() async {
    await _engine.switchCamera();
  }

  void _onToggleMute() async {
    setState(() => _muted = !_muted);
    await _engine.muteLocalAudioStream(_muted);
  }

  void _onToggleVideo() async {
    if (!widget.call.isVideo) return;
    setState(() => _videoDisabled = !_videoDisabled);
    await _engine.muteLocalVideoStream(_videoDisabled);
  }

  void _endCall() async {
    await _engine.leaveChannel();
    await _engine.release();
    if (mounted) {
      final callService = Provider.of<CallService>(context, listen: false);
      await callService.endCall(widget.call.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video (Full Screen)
          _remoteVideoView(),

          // Local Video (Small Overlay)
          if (widget.call.isVideo && !_videoDisabled && _localUserJoined)
            Positioned(
              right: 20,
              top: 50,
              width: 120,
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),

          // Call Info & Controls
          Column(
            children: [
              const SizedBox(height: 100),
              Text(
                widget.isIncoming
                    ? widget.call.callerName
                    : widget.call.receiverName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _remoteUid != null ? "Ongoing Call" : "Calling...",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Spacer(),
              _toolbar(),
              const SizedBox(height: 50),
            ],
          ),
        ],
      ),
    );
  }

  Widget _remoteVideoView() {
    if (widget.call.isVideo) {
      if (_remoteUid != null) {
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: _remoteUid),
            connection: RtcConnection(channelId: widget.call.channelId),
          ),
        );
      } else {
        return Container(
          color: Colors.black87,
          child: const Center(
            child: Text(
              'Waiting for recipient...',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } else {
      // Audio Call UI
      return Container(
        color: AppColors.primary.withValues(alpha: 0.1),
        child: Center(
          child: CircleAvatar(
            radius: 80,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: const Icon(Icons.person, size: 80, color: AppColors.primary),
          ),
        ),
      );
    }
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Keep it as small as possible
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RawMaterialButton(
            onPressed: _onToggleMute,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: _muted ? AppColors.primary : Colors.white24,
            padding: const EdgeInsets.all(10.0), // Reduced from 12
            child: Icon(
              _muted ? Icons.mic_off : Icons.mic,
              color: _muted ? Colors.white : Colors.white70,
              size: 24.0, // Reduced from 28
            ),
          ),
          if (widget.call.isVideo) ...[
            const SizedBox(width: 12), // Reduced from 20
            RawMaterialButton(
              onPressed: _onToggleVideo,
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: _videoDisabled ? AppColors.primary : Colors.white24,
              padding: const EdgeInsets.all(10.0), // Reduced from 12
              child: Icon(
                _videoDisabled
                    ? Icons.videocam_off_outlined
                    : Icons.videocam_outlined,
                color: _videoDisabled ? Colors.white : Colors.white70,
                size: 24.0, // Reduced from 28
              ),
            ),
          ],
          const SizedBox(width: 12), // Reduced from 20
          RawMaterialButton(
            onPressed: _endCall,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(14.0), // Reduced from 16
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 32.0, // Reduced from 35
            ),
          ),
          if (widget.call.isVideo) ...[
            const SizedBox(width: 12), // Reduced from 20
            RawMaterialButton(
              onPressed: _switchCamera,
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white24,
              padding: const EdgeInsets.all(10.0), // Reduced from 12
              child: const Icon(
                Icons.switch_camera,
                color: Colors.white70,
                size: 24.0, // Reduced from 28
              ),
            ),
          ],
        ],
      ),
    );
  }
}
