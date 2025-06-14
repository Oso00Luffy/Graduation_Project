import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroScreen extends StatefulWidget {
  final Widget nextScreen;

  const IntroScreen({Key? key, required this.nextScreen}) : super(key: key);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<IntroPage> _pages = [
    IntroPage(
      title: "Welcome to the App",
      description: "Discover amazing visual cryptography features",
      image: "assets/intro/intro1.png",
      color: Colors.blue.shade700, // Darker for contrast
    ),
    IntroPage(
      title: "Secure Your Images",
      description: "Apply encryption to protect your visual content",
      image: "assets/intro/intro2.png",
      color: Colors.purple.shade700,
    ),
    IntroPage(
      title: "Decrypt Anywhere",
      description: "Retrieve your original images with ease",
      image: "assets/intro/intro3.png",
      color: Colors.green.shade700,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _animationController.reset();
      _animationController.forward();
    });
  }

  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_completed', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      body: Stack(
        children: [
          // Background color
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            color: _pages[_currentPage].color,
            curve: Curves.easeInOut,
          ),

          // Gradient overlay for better text contrast
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(180, 0, 0, 0), // Top dark
                  Color.fromARGB(120, 0, 0, 0), // Middle
                  Color.fromARGB(200, 0, 0, 0), // Bottom darker
                ],
              ),
            ),
          ),

          // Page content
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildPage(_pages[index], isWide),
                ),
              );
            },
          ),

          // Navigation buttons
          Positioned(
            bottom: isWide ? 80 : 60,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button
                  TextButton(
                    onPressed: _completeIntro,
                    child: const Text(
                      'Skip',
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Progress indicators
                  Row(
                    children: List.generate(_pages.length, (index) => _buildDot(index)),
                  ),

                  // Next/Done button
                  TextButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeIntro();
                      }
                    },
                    child: Text(
                      _currentPage < _pages.length - 1 ? 'Next' : 'Done',
                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Colors.white
            : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPage(IntroPage page, bool isWide) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 120 : 40,
        vertical: isWide ? 60 : 40,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image with "bounce" animation
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.elasticOut,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Image.asset(
              page.image,
              height: isWide
                  ? MediaQuery.of(context).size.height * 0.30
                  : MediaQuery.of(context).size.height * 0.35,
            ),
          ),

          SizedBox(height: isWide ? 60 : 40),

          // Title with staggered animation
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              page.title,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: isWide ? 30 : 20),

          // Description with delayed staggered animation
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              page.description,
              style: textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.95),
                fontWeight: FontWeight.w500,
                fontSize: isWide ? 22 : 18,
                shadows: [
                  Shadow(
                    blurRadius: 6,
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class IntroPage {
  final String title;
  final String description;
  final String image;
  final Color color;

  IntroPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}
