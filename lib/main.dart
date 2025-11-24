import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

void main() {
  runApp(const ProviderScope(child: SmartHomeApp()));
}

// ----------------------------- RIVERPOD: Providers & Models -----------------------------
final mainLightProvider = StateProvider<bool>((ref) => false);

final devicesProvider =
    StateNotifierProvider<DevicesNotifier, List<Device>>((ref) {
  return DevicesNotifier();
});

class DevicesNotifier extends StateNotifier<List<Device>> {
  DevicesNotifier()
      : super([
          Device(name: "Living Room Lamp", icon: Icons.lightbulb, isActive: false),
          Device(name: "Bedroom AC", icon: Icons.ac_unit, isActive: false),
          Device(name: "Security Cam", icon: Icons.videocam, isActive: false),
          Device(name: "Smart TV", icon: Icons.tv, isActive: false),
          Device(name: "Wi-Fi Router", icon: Icons.wifi, isActive: false),
          Device(name: "Front Door", icon: Icons.door_front_door, isActive: false),
        ]);

  void toggle(int index) {
    final current = state[index];
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) current.copyWith(isActive: !current.isActive) else state[i]
    ];
  }
}

class Device {
  final String name;
  final IconData icon;
  final bool isActive;

  Device({
    required this.name,
    required this.icon,
    required this.isActive,
  });

  Device copyWith({String? name, IconData? icon, bool? isActive}) {
    return Device(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
    );
  }
}

// ----------------------------- APP -----------------------------
class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const SmartHomePage(),
    );
  }
}

// ----------------------------- MAIN PAGE -----------------------------
class SmartHomePage extends ConsumerWidget {
  const SmartHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    final mainLight = ref.watch(mainLightProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Toggle theme (system-driven). Keep for quick access: toggles brightness override
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              // quick feedback: show snackbar (no persistent theme override in this sample)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Use system theme — toggle supported via OS/settings.')),
              );
            },
          )
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final bool isTablet = maxWidth >= 800;

        // responsive grid columns:
        final crossAxisCount = isTablet ? 4 : 2;
        final heroHeight = isTablet ? 240.0 : 160.0;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hero section with glass + animated gradient + Lottie
            GlassCard(
              height: heroHeight,
              borderRadius: 24,
              child: Row(
                children: [
                  // Left: Lottie animation (device illustration)
                  SizedBox(
                    width: isTablet ? 260 : 120,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Lottie.network(
                        // public Lottie animation (device / light bulb). Network usage — make sure app has internet.
                        'https://assets2.lottiefiles.com/packages/lf20_touohxv0.json',
                        fit: BoxFit.contain,
                        repeat: true,
                        animate: true,
                      ),
                    ),
                  ),

                  // Right: Info & main light button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Main Light',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mainLight ? 'Status: ON' : 'Status: OFF',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          // Animated control button
                          AnimatedLightButton(
                            isOn: mainLight,
                            onTap: () {
                              ref.read(mainLightProvider.notifier).state = !ref.read(mainLightProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Devices', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text('${devices.length} items', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // Responsive Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devices.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: isTablet ? 200 : 160,
              ),
              itemBuilder: (context, index) {
                final device = devices[index];
                return DeviceCardCustom(
                  device: device,
                  onToggle: () => ref.read(devicesProvider.notifier).toggle(index),
                );
              },
            ),
          ],
        );
      }),
    );
  }
}

// ----------------------------- CUSTOM: GlassCard (glassmorphism) -----------------------------
class GlassCard extends StatelessWidget {
  final double height;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    required this.child,
    this.height = 160,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Colors adapt to brightness
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color overlay = dark ? Colors.black.withOpacity(0.35) : Colors.white.withOpacity(0.25);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          height: height,
          padding: padding ?? const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                overlay,
                overlay.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.5 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ----------------------------- CUSTOM: AnimatedLightButton -----------------------------
class AnimatedLightButton extends StatefulWidget {
  final bool isOn;
  final VoidCallback onTap;

  const AnimatedLightButton({super.key, required this.isOn, required this.onTap});

  @override
  State<AnimatedLightButton> createState() => _AnimatedLightButtonState();
}

class _AnimatedLightButtonState extends State<AnimatedLightButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    if (widget.isOn) {
      _ctrl.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedLightButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOn != widget.isOn) {
      if (widget.isOn) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onColor = Colors.orangeAccent.shade200;
    final offColor = Theme.of(context).colorScheme.surfaceVariant;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_ctrl.value);
          final color = Color.lerp(offColor, onColor, t)!;
          final scale = 1.0 + 0.08 * t;
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: onColor.withOpacity(0.25 * t),
                    blurRadius: 18 * t,
                    offset: Offset(0, 6 * t),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isOn ? Icons.light_mode : Icons.lightbulb_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.isOn ? 'Turn Off' : 'Turn On',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------- CUSTOM: DeviceCardCustom -----------------------------
class DeviceCardCustom extends StatelessWidget {
  final Device device;
  final VoidCallback onToggle;

  const DeviceCardCustom({
    super.key,
    required this.device,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onToggle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: device.isActive
                  ? Colors.blueAccent.withOpacity(0.95)
                  : (dark ? Colors.black.withOpacity(0.35) : Colors.white.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: device.isActive
                    ? Colors.blueAccent.withOpacity(0.9)
                    : Theme.of(context).colorScheme.onBackground.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: device.isActive
                      ? Colors.blueAccent.withOpacity(0.25)
                      : Colors.black.withOpacity(dark ? 0.5 : 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(device.icon, size: 42, color: device.isActive ? Colors.white : Theme.of(context).colorScheme.onBackground),
                const SizedBox(height: 12),
                Text(
                  device.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: device.isActive ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                  child: Text(
                    device.isActive ? 'ON' : 'OFF',
                    key: ValueKey<bool>(device.isActive),
                    style: TextStyle(
                      color: device.isActive ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
