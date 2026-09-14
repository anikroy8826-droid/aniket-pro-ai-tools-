import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

const Color kGold = Color(0xFFF5E6C8);

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayWidget(),
  ));
}

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});
  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  int pending = 0;
  int cHtf = 0;
  int cEntry = 0;
  int cCorr = 0;
  bool captureOn = true;
  bool menuOpen = false;
  String toast = '';

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) {
      final s = event.toString();
      if (s.startsWith('STATE:')) {
        final p = s.substring(6).split('|');
        if (p.length >= 5) {
          setState(() {
            pending = int.tryParse(p[0]) ?? 0;
            cHtf = int.tryParse(p[1]) ?? 0;
            cEntry = int.tryParse(p[2]) ?? 0;
            cCorr = int.tryParse(p[3]) ?? 0;
            captureOn = p[4] == '1';
          });
        }
      } else if (s.startsWith('TOAST:')) {
        setState(() => toast = s.substring(6));
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => toast = '');
        });
      }
    });
    FlutterOverlayWindow.shareData('REQ_STATE');
  }

  Future<void> _openMenu() async {
    setState(() => menuOpen = true);
    await FlutterOverlayWindow.updateOverlay(width: 280, height: 340);
  }

  Future<void> _closeMenu() async {
    setState(() => menuOpen = false);
    await FlutterOverlayWindow.updateOverlay(width: 160, height: 80);
  }

  Widget _menuRow(String label, int count, int max, String box) {
    final full = count >= max;
    return GestureDetector(
      onTap: full
          ? null
          : () {
              FlutterOverlayWindow.shareData('DELIVER:$box');
              _closeMenu();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kGold,
            opacity: full ? 0.35 : 1.0,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 6),
              Shadow(color: Colors.black, blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: menuOpen
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ꫝ $pending টি SS জমা আছে',
                  style: const TextStyle(
                      fontSize: 14,
                      color: kGold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 6)]),
                ),
                const SizedBox(height: 8),
                _menuRow('HTF', cHtf, 6, 'htf'),
                _menuRow('ENTRY', cEntry, 4, 'entry'),
                _menuRow('CORRELATION', cCorr, 1, 'corr'),
                GestureDetector(
                  onTap: _closeMenu,
                  child: const Text('✕ বন্ধ করুন',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          shadows: [Shadow(color: Colors.black, blurRadius: 6)])),
                ),
                if (toast.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(toast,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.redAccent,
                            shadows: [Shadow(color: Colors.black, blurRadius: 6)])),
                  ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RawGestureDetector(
                  gestures: {
                    LongPressGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                            LongPressGestureRecognizer>(
                      () => LongPressGestureRecognizer(
                          duration: const Duration(seconds: 1)),
                      (instance) => instance.onLongPress = _openMenu,
                    ),
                  },
                  child: GestureDetector(
                    onTap: () =>
                        FlutterOverlayWindow.shareData('CAPTURE_TOGGLE'),
                    child: Opacity(
                      opacity: captureOn ? 1.0 : 0.35,
                      child: Text(
                        'ꫝ $pending',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: kGold,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 8),
                            Shadow(color: Colors.black, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (toast.isNotEmpty)
                  Text(toast,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.redAccent,
                          shadows: [Shadow(color: Colors.black, blurRadius: 6)])),
              ],
            ),
    );
  }
}
