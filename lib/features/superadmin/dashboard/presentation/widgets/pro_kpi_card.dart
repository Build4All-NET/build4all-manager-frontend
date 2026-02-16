import 'package:flutter/material.dart';

class ProKpiCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final int value;
  final Gradient gradient;
  final int delayMs;
  final VoidCallback? onTap;

  const ProKpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    this.delayMs = 0,
    this.onTap,
  });

  @override
  State<ProKpiCard> createState() => _ProKpiCardState();
}

class _ProKpiCardState extends State<ProKpiCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  late final Animation<double> _scale =
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack);

  bool _hover = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tappable = widget.onTap != null;

    return ScaleTransition(
      scale: _scale,
      child: MouseRegion(
        cursor: tappable ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => tappable ? setState(() => _hover = true) : null,
        onExit: (_) => tappable ? setState(() => _hover = false) : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(18),

              // ✅ Softer, more “dashboard tile”
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_hover ? .12 : .08),
                  blurRadius: _hover ? 18 : 14,
                  offset: const Offset(0, 8),
                ),
              ],

              // ✅ Soft border to feel like a tile not a button
              border: Border.all(
                color: Colors.white.withOpacity(_hover ? .20 : .12),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  // ✅ very subtle hover overlay (no “pressed” feedback)
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: _hover ? 1 : 0,
                      child: Container(
                        color: Colors.white.withOpacity(.06),
                      ),
                    ),
                  ),

                  // your inner “glass” layer
                  Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: cs.surface.withOpacity(.06),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.16),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Icon(widget.icon, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DefaultTextStyle(
                            style: const TextStyle(color: Colors.white),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: .2,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${widget.value}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ❌ No chevron. Chevron = button/navigation energy.
                        // If you want a tiny hint only when tappable, use a dot:
                        // if (tappable)
                        //   Padding(
                        //     padding: const EdgeInsets.only(left: 8),
                        //     child: Icon(Icons.circle, size: 7, color: Colors.white60),
                        //   ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
