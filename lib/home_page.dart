import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'BillingPage.dart';
import 'CustomerSearchPage.dart';
import 'ProductManagementPage.dart';
import 'package:wetherapp/services/auth_service.dart';
import 'alert_box.dart';

class HomePage extends StatefulWidget {
  final String userName;
  final String role;
  const HomePage({super.key, required this.userName, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _bubbleAnimationController;
  late List<Bubble> _bubbles;
  late PageController _pageController;
  Timer? _pageViewTimer;
  int _currentPage = 0;

  final Color _goldColor = const Color(0xFFFFD700);
  final List<String> _captions = [
    'Smart Billing at Your Fingertips.',
    'Track Your Sales Instantly.',
    'Grow Your Business with Data.',
  ];

  @override
  void initState() {
    super.initState();
    _bubbleAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _bubbles = List.generate(30, (index) => Bubble());

    _pageController = PageController();
    _pageViewTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < _captions.length) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeIn,
      );
      if (_currentPage == _captions.length) {
        _currentPage = 0;
        _pageController.jumpToPage(0);
      }
    });
  }

  @override
  void dispose() {
    _bubbleAnimationController.dispose();
    _pageController.dispose();
    _pageViewTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bubbleAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: BubblePainter(_bubbles, _bubbleAnimationController.value),
          child: Container(
            color: Colors.black,
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.white.withOpacity(0.1),
          pinned: true,
          expandedHeight: 140.0,
          title: GradientText(
            'AbBill app',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            gradient: LinearGradient(colors: [
              _goldColor,
              _goldColor.withOpacity(0.8),
              Colors.white,
            ]),
          ),
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.only(top: 60.0, left: 16.0, right: 16.0),
                  child: Center(
                    child: SizedBox(
                      height: 50, // Constrain the height of the PageView
                      child: PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final captionIndex = index % _captions.length;
                          return Center(
                            child: Text(
                              _captions[captionIndex],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16.0,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.2,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                final confirmLogout = await AlertBox.showConfirmationDialog(
                  context,
                  'Confirm Logout',
                  'Are you sure you want to log out?',
                );
                if (confirmLogout == true) {
                  await AuthService().signOut();
                }
              },
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${widget.userName}!',
                  style: TextStyle(color: _goldColor, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your business efficiently.',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                ),
                const SizedBox(height: 24),
                _buildSleekBanner(),
                const SizedBox(height: 32),
                _buildGlassActionCard(
                  icon: Icons.note_add_outlined,
                  title: 'Generate New Bill',
                  subtitle: 'Create a new invoice for a customer.',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BillingPage()));
                  },
                ),
                const SizedBox(height: 16),
                _buildGlassActionCard(
                  icon: Icons.people_alt_outlined,
                  title: 'View Customer Details',
                  subtitle: 'Search and manage your customers.',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => CustomerSearchPage(role: widget.role)));
                  },
                ),
                const SizedBox(height: 16),
                if (widget.role == 'admin')
                  _buildGlassActionCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'Manage Products',
                    subtitle: 'Add, update, or remove items.',
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProductManagementPage()));
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSleekBanner() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: _goldColor.withOpacity(0.5), width: 1.5),
        image: const DecorationImage(
          image: AssetImage('assets/images/testing.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildGlassActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 32, color: _goldColor),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Bubble animation classes (copied from login_page.dart)
class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double animationValue;

  BubblePainter(this.bubbles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke;

    for (var bubble in bubbles) {
      final progress = (animationValue + bubble.startTime) % 1.0;
      final position = Offset(
        bubble.x * size.width,
        size.height - (size.height * progress * bubble.speed),
      );

      if (position.dy < 0) {
        bubble.reset();
      }

      final currentRadius = bubble.radius * (1 - progress);
      paint.strokeWidth = bubble.strokeWidth;
      paint.color = bubble.color.withOpacity(1 - progress);

      canvas.drawCircle(position, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Bubble {
  late double x;
  late double radius;
  late double speed;
  late double startTime;
  late Color color;
  late double strokeWidth;
  final Random _random = Random();

  Bubble() {
    reset();
  }

  void reset() {
    x = _random.nextDouble();
    radius = _random.nextDouble() * 20 + 10;
    speed = _random.nextDouble() * 0.5 + 0.2;
    startTime = _random.nextDouble();
    color = const Color(0xFFFFD700);
    strokeWidth = _random.nextDouble() * 1.5 + 0.5;
  }
}

class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}