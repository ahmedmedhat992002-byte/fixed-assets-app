import 'dart:async';
import 'dart:ui';
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

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  late RtcEngine _engine;
  bool _engineReady = false;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _videoDisabled = false;
  bool _speakerOn = false;
  String? _initError;

  Timer? _callTimer;
  int _callDurationSeconds = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Agora App ID — Testing Mode project (App Certificate disabled)
  static const String appId = "d6d723b01d20462989f38be2cb291e3c";

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initAgora();
  }

  void _startTimer() {
    if (_callTimer != null) return;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  String get _formattedDuration {
    final minutes = (_callDurationSeconds / 60).floor();
    final seconds = _callDurationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _initAgora() async {
    try {
      // 1. Request permissions
      final statuses = await [
        Permission.microphone,
        Permission.camera,
      ].request();
      debugPrint(
        '[Agora] Mic: ${statuses[Permission.microphone]}, Cam: ${statuses[Permission.camera]}',
      );

      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
      if (!micGranted) {
        if (mounted) {
          setState(
            () => _initError =
                'Microphone permission denied. Please allow it in Settings.',
          );
        }
        return;
      }

      // 2. Initialize engine
      _engine = createAgoraRtcEngine();
      debugPrint('[Agora] Initializing with appId: $appId');
      await _engine.initialize(
        const RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      debugPrint('[Agora] Engine initialized OK');

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint(
              "[Agora] Joined channel. localUid=${connection.localUid}",
            );
            if (mounted) setState(() => _localUserJoined = true);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("[Agora] Remote user $remoteUid joined");
            if (mounted) {
              setState(() => _remoteUid = remoteUid);
              _startTimer();
            }
          },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                debugPrint(
                  "[Agora] Remote user $remoteUid left. Reason: $reason",
                );
                if (mounted) setState(() => _remoteUid = null);
                _endCall();
              },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint("[Agora] Left channel");
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint("[Agora Error] Code: $err, Message: $msg");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Call Error ($err): $msg')),
              );
            }
          },
        ),
      );

      if (widget.call.isVideo) {
        await _engine.enableVideo();
        await _engine.startPreview();
        _speakerOn = true;
        await _engine.setEnableSpeakerphone(true);
      } else {
        await _engine.disableVideo();
        _speakerOn = false;
        await _engine.setEnableSpeakerphone(false);
      }

      if (mounted) setState(() => _engineReady = true);

      // 3. Join channel — token must be '' only when App Certificate is DISABLED in Agora Console
      debugPrint('[Agora] Joining channel: "${widget.call.channelId}"');
      await _engine.joinChannel(
        token: '',
        channelId: widget.call.channelId,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: false,
          autoSubscribeAudio: true,
          autoSubscribeVideo: false,
        ),
      );
      debugPrint('[Agora] joinChannel called OK');
    } catch (e, stack) {
      debugPrint('[Agora FATAL] Init failed: $e\n$stack');
      if (mounted) {
        setState(
          () => _initError =
              'Failed to initialize call engine.\n\n$e\n\nMake sure your Agora App ID is valid and App Certificate is DISABLED in Agora Console.',
        );
      }
    }
  }

  void _switchCamera() async {
    await _engine.switchCamera();
  }

  void _onToggleMute() async {
    setState(() => _muted = !_muted);
    await _engine.muteLocalAudioStream(_muted);
  }

  void _onToggleSpeaker() async {
    setState(() => _speakerOn = !_speakerOn);
    await _engine.setEnableSpeakerphone(_speakerOn);
  }

  void _onToggleVideo() async {
    if (!widget.call.isVideo) return;
    setState(() => _videoDisabled = !_videoDisabled);
    await _engine.muteLocalVideoStream(_videoDisabled);
  }

  void _endCall() async {
    _callTimer?.cancel();
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
    _callTimer?.cancel();
    _pulseController.dispose();
    if (_engineReady) {
      _engine.leaveChannel();
      _engine.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Show error screen if initialization failed
    if (_initError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.redAccent,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Connection Failed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _initError!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.call_end_rounded),
                  label: const Text('End Call'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep modern slate background
      body: Stack(
        children: [
          // Background UI
          _buildBackground(),

          // Remote Video (Full Screen) if Video Call
          if (widget.call.isVideo && _remoteUid != null) _remoteVideoView(),

          // Gradient overlay for better text visibility
          if (widget.call.isVideo && _remoteUid != null)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),

          // Local Video (Small Overlay)
          if (widget.call.isVideo && !_videoDisabled && _localUserJoined)
            Positioned(
              right: 20,
              top: MediaQuery.of(context).padding.top + 20,
              width: 110,
              height: 160,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),

          // Call Info & Controls
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Caller Name & Status
                _buildCallHeader(),

                const Spacer(),

                // Avatar for Audio Call
                if (!widget.call.isVideo || _remoteUid == null)
                  _buildAudioAvatar(),

                const Spacer(),

                // Toolbar Controls
                _buildToolbar(size),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        // Base Color
        Container(color: const Color(0xFF0F172A)),
        // Top right blob
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
        ),
        // Bottom left blob
        Positioned(
          bottom: -50,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.1),
            ),
          ),
        ),
        // Blur Effect
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildCallHeader() {
    return Column(
      children: [
        Text(
          widget.isIncoming ? widget.call.callerName : widget.call.receiverName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _remoteUid != null ? _formattedDuration : "Calling...",
            style: TextStyle(
              color: _remoteUid != null ? Colors.greenAccent : Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioAvatar() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _remoteUid == null ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: _remoteUid == null
                      ? 10 * _pulseAnimation.value
                      : 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 80,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _remoteVideoView() {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: _remoteUid!),
        connection: RtcConnection(channelId: widget.call.channelId),
      ),
    );
  }

  Widget _buildToolbar(Size size) {
    return Container(
      width: size.width,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.85),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Speaker
          _controlButton(
            icon: _speakerOn
                ? Icons.volume_up_rounded
                : Icons.volume_down_rounded,
            isActive: _speakerOn,
            onPressed: _onToggleSpeaker,
          ),

          // Video Toggle
          if (widget.call.isVideo)
            _controlButton(
              icon: _videoDisabled
                  ? Icons.videocam_off_rounded
                  : Icons.videocam_rounded,
              isActive: !_videoDisabled,
              onPressed: _onToggleVideo,
            ),

          // Mute
          _controlButton(
            icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
            isActive: !_muted,
            onPressed: _onToggleMute,
          ),

          // Switch Camera
          if (widget.call.isVideo && !_videoDisabled)
            _controlButton(
              icon: Icons.flip_camera_ios_rounded,
              isActive: false,
              onPressed: _switchCamera,
            ),

          // End Call
          GestureDetector(
            onTap: _endCall,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF1E293B) : Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
