import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:assets_management/core/theme/app_colors.dart';
import 'package:assets_management/app/routes/app_routes.dart';
import 'package:assets_management/core/models/receipt_data.dart';
import 'package:assets_management/core/assets/asset_service.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = true;

  // Permission state — start as granted so the scanner shows immediately
  // Real camera permission is handled by platform; we just show the UI.
  bool _permissionGranted = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnimation = CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    );

    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    // Attempt to request camera permission via permission_handler.
    // If the plugin is not available (e.g. desktop, hot-reload before rebuild),
    // fall back gracefully so the scanner UI still appears.
    try {
      // Dynamic import to avoid crash on unsupported platforms
      // ignore: unnecessary_import
      final result = await const MethodChannel(
        'flutter.baseflow.com/permissions/methods',
      ).invokeMethod<int>('requestPermissions', [1]); // 1 = camera
      if (!mounted) return;
      // 1 = granted, 3 = permanentlyDenied
      if (result == 1) {
        setState(() => _permissionGranted = true);
      } else {
        // Still show scanner; let system handle permission at camera open time
        setState(() => _permissionGranted = true);
      }
    } on PlatformException catch (e) {
      // Permission denied by system
      if (!mounted) return;
      if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        setState(() {
          _permissionGranted = false;
          _permissionDenied = true;
        });
      } else {
        // Any other error — still show scanner UI
        setState(() => _permissionGranted = true);
      }
    } on MissingPluginException {
      // Plugin not registered yet (hot reload before full rebuild) — show UI
      if (!mounted) return;
      setState(() => _permissionGranted = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _permissionGranted = true);
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09122C),
      body: Stack(
        children: [
          // ── Real Camera Preview ───────────────────────────────────────────
          if (_permissionGranted)
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                if (!_isScanning) return;
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  setState(() => _isScanning = false);
                  _handleQrResult(barcodes.first.rawValue ?? '');
                }
              },
            )
          else
            Container(color: const Color(0xFF09122C)),

          // ── Camera permission denied state ─────────────────────────────────
          if (_permissionDenied)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.no_photography_outlined,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Camera permission required',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please enable camera access in your device settings to scan QR codes.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        // Open app settings on Android/iOS
                        const MethodChannel(
                          'flutter.baseflow.com/permissions/methods',
                        ).invokeMethod('openAppSettings');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              ),
            ),

          // ── Permission granted — show scanner UI ───────────────────────────
          if (!_permissionDenied) ...[
            // Top title + subtitle
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Scan QR Code',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Focus your camera directly on\nthe QR code to scan it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Scan frame — centered
            if (_permissionGranted)
              Center(
                child: SizedBox(
                  width: 270,
                  height: 270,
                  child: Stack(
                    children: [
                      // Animated scan line
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (_, __) => Positioned(
                          top: 2 + _scanAnimation.value * 266,
                          left: 12,
                          right: 12,
                          child: Container(
                            height: 2,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white54,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Corner brackets
                      ..._buildCorners(),
                    ],
                  ),
                ),
              ),

            // Shutter button
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: GestureDetector(
                  onTap: _permissionGranted ? _onShutterPressed : null,
                  child: Opacity(
                    opacity: _permissionGranted ? 1.0 : 0.4,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Back button (always visible)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onShutterPressed() {
    // Simulate getting "actual data" after taking a photo
    final random = math.Random();

    // Dice roll for the outcome (per User Flow diagram)
    // 0 = Asset Found, 1 = Receipt Found, 2 = Unknown/Error
    final outcome = random.nextInt(3);

    if (outcome == 0) {
      // ── Asset Found ──────────────────────────────────────────────────────
      final assetNames = [
        'Excavator X-200',
        'Power Generator B',
        'Forklift T10',
        'CNC Lathe',
      ];
      final name = assetNames[random.nextInt(assetNames.length)];
      Navigator.of(
        context,
      ).pushNamed(AppRoutes.machineryDetail, arguments: name);
    } else if (outcome == 1) {
      // ── Receipt Found ────────────────────────────────────────────────────
      final vendors = [
        {
          'name': 'Amazon Egypt',
          'phone': '+20 2 21601000',
          'email': 'support@amazon.eg',
          'address': 'Cairo Festival City',
        },
        {
          'name': 'Carrefour Egypt',
          'phone': '16061',
          'email': 'cs-egy@mafcarrefour.com',
          'address': 'Maadi City Center',
        },
        {
          'name': 'B.TECH Egypt',
          'phone': '19966',
          'email': 'info@btech.com',
          'address': 'Nasr City, Cairo',
        },
      ];
      final vendor = vendors[random.nextInt(vendors.length)];
      final user = FirebaseAuth.instance.currentUser;

      final mockData = ReceiptData(
        senderName: vendor['name']!,
        senderPhone: vendor['phone']!,
        senderEmail: vendor['email']!,
        senderAddress: vendor['address']!,
        receiverName:
            user?.displayName ??
            user?.email?.split('@')[0] ??
            'Valued Customer',
        receiverPhone: user?.phoneNumber ?? '+20 123 456 789',
        receiverEmail: user?.email ?? 'user@example.com',
        receiverAddress: 'Cairo, Egypt',
        total: 100.0 + random.nextInt(4900).toDouble(),
        paymentMethod: random.nextBool() ? 'Credit Card' : 'Visa Debit',
        transactionId:
            'REC-${random.nextInt(1000000).toString().padLeft(6, '0')}',
        status: 'Verified',
        barcodeValue:
            '(01)${random.nextInt(1000000).toString().padLeft(7, '0')}${random.nextInt(1000000).toString().padLeft(7, '0')}',
      );
      Navigator.of(context).pushNamed(AppRoutes.eReceipt, arguments: mockData);
    } else {
      // ── Unknown QR ───────────────────────────────────────────────────────
      Navigator.of(context).pushNamed(AppRoutes.manualSearch);
    }
  }

  Future<void> _handleQrResult(String data) async {
    if (data.isEmpty) {
      Navigator.of(context).pushNamed(AppRoutes.manualSearch);
      return;
    }

    try {
      // 1. Attempt to parse as JSON first (Receipt Flow)
      final decoded = json.decode(data) as Map<String, dynamic>;

      if (decoded.containsKey('senderName') && decoded.containsKey('total')) {
        final user = FirebaseAuth.instance.currentUser;
        final receipt = ReceiptData(
          senderName: decoded['senderName']?.toString() ?? 'Unknown Merchant',
          senderPhone: decoded['senderPhone']?.toString() ?? '',
          senderEmail: decoded['senderEmail']?.toString() ?? '',
          senderAddress: decoded['senderAddress']?.toString() ?? '',
          receiverName:
              user?.displayName ??
              user?.email?.split('@')[0] ??
              'Valued Customer',
          receiverPhone: user?.phoneNumber ?? '',
          receiverEmail: user?.email ?? '',
          receiverAddress: 'Cairo, Egypt',
          total: double.tryParse(decoded['total']?.toString() ?? '0') ?? 0.0,
          paymentMethod: decoded['paymentMethod']?.toString() ?? 'Credit Card',
          transactionId:
              decoded['transactionId']?.toString() ??
              'REC-${math.Random().nextInt(1000000)}',
          status: 'Verified',
          barcodeValue: decoded['barcodeValue']?.toString() ?? data,
        );
        Navigator.of(context).pushNamed(AppRoutes.eReceipt, arguments: receipt);
        return;
      }
    } catch (_) {
      // Not JSON - proceed to real database lookup
    }

    final cleanData = data.trim();

    // 2. Real Database Lookup
    final assetService = context.read<AssetService>();
    final asset = await assetService.findAssetByNameOrId(cleanData);

    if (!mounted) return;

    if (asset != null) {
      // Capture location in background
      _updateAssetLocation(asset.id);

      final category = asset.category.toLowerCase();
      String route = AppRoutes.machineryDetail; // Default fallback

      if (category.contains('vehicle')) {
        route = AppRoutes.vehicleDetail;
      } else if (category.contains('furniture')) {
        route = AppRoutes.furnitureDetail;
      } else if (category.contains('hardware')) {
        route = AppRoutes.computerHardwareDetail;
      } else if (category.contains('software')) {
        route = AppRoutes.computerSoftwareDetail;
      } else if (category.contains('fixed')) {
        route = AppRoutes.fixedAssetDetail;
      } else if (category.contains('intangible')) {
        route = AppRoutes.intangibleAssetDetail;
      }

      Navigator.of(context).pushNamed(route, arguments: asset);
      return;
    }

    // 3. Fallback to Unknown sheet
    _showUnknownAssetSheet(cleanData);
  }

  Future<void> _updateAssetLocation(String assetId) async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );

        if (!mounted) return;
        final assetService = context.read<AssetService>();
        await assetService.updateAssetLocation(
          assetId: assetId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    } catch (e) {
      // Error capturing location
    }
  }

  void _showUnknownAssetSheet(String data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).canvasColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Unknown QR Code',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Content: "$data"',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.manualSearch, arguments: data);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).canvasColor,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Manual Search'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  _showCategoryPicker(data);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Register as New Asset'),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // Re-enable scanning when sheet is closed
      if (mounted) setState(() => _isScanning = true);
    });
  }

  void _showCategoryPicker(String data) {
    final categories = [
      'Machinery',
      'Vehicles',
      'Furniture',
      'Computer Hardware',
      'Computer Software',
      'Fixed Assets',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).canvasColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Asset Category',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...categories.map(
                (cat) => ListTile(
                  title: Text(cat),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close picker
                    Navigator.of(context).pushNamed(
                      AppRoutes.addAsset,
                      arguments: {'category': cat, 'barcode': data},
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCorners() {
    const size = 36.0;
    const thickness = 3.0;
    const radius = 12.0;

    Widget corner({required Alignment alignment}) {
      final isLeft = alignment.x < 0;
      final isTop = alignment.y < 0;
      return Align(
        alignment: alignment,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RoundedCornerPainter(
              isLeft: isLeft,
              isTop: isTop,
              thickness: thickness,
              radius: radius,
            ),
          ),
        ),
      );
    }

    return [
      corner(alignment: Alignment.topLeft),
      corner(alignment: Alignment.topRight),
      corner(alignment: Alignment.bottomLeft),
      corner(alignment: Alignment.bottomRight),
    ];
  }
}

class _RoundedCornerPainter extends CustomPainter {
  const _RoundedCornerPainter({
    required this.isLeft,
    required this.isTop,
    required this.thickness,
    required this.radius,
  });

  final bool isLeft;
  final bool isTop;
  final double thickness;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path();

    if (isLeft && isTop) {
      path.moveTo(0, h);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
      path.lineTo(w, 0);
    } else if (!isLeft && isTop) {
      path.moveTo(0, 0);
      path.lineTo(w - radius, 0);
      path.quadraticBezierTo(w, 0, w, radius);
      path.lineTo(w, h);
    } else if (isLeft && !isTop) {
      path.moveTo(0, 0);
      path.lineTo(0, h - radius);
      path.quadraticBezierTo(0, h, radius, h);
      path.lineTo(w, h);
    } else {
      path.moveTo(0, h);
      path.lineTo(w - radius, h);
      path.quadraticBezierTo(w, h, w, h - radius);
      path.lineTo(w, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoundedCornerPainter old) => false;
}
