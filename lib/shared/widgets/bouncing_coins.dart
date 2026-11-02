import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/constants/app_colors.dart';

/// Koin jatuh dengan gravitasi, berputar, memantul, lalu rebah dan memudar.
/// Ketuk area untuk memunculkan koin tambahan.
class BouncingCoins extends StatefulWidget {
  const BouncingCoins({
    super.key,
    this.count = 9,
    this.floorInset = 0,
    this.minRadius = 12,
    this.maxRadius = 22,
    this.interactive = true,
    this.faceLight = const Color(0xFFFFFBE8),
    this.faceDark = const Color(0xFFFFD15C),
    this.rim = AppColors.outlineStrong,
  }) : assert(count >= 0),
       assert(minRadius > 0),
       assert(maxRadius >= minRadius);

  final int count;
  final double floorInset;
  final double minRadius;
  final double maxRadius;
  final bool interactive;
  final Color faceLight;
  final Color faceDark;
  final Color rim;

  @override
  State<BouncingCoins> createState() => _BouncingCoinsState();
}

class _Coin {
  _Coin(this.r);

  double r;

  double x = 0;
  double y = -100;
  double vx = 0;
  double vy = 0;

  // Sudut rotasi permukaan dan kemiringan visual.
  double flip = 0;
  double flipSpeed = 0;
  double tilt = 0;

  double swayAmp = 0;
  double swayFreq = 0;
  double phase = 0;
  double age = 0;

  double delay = 0;
  double rest = 0;
  double lie = 0;

  double bounceFactor = 0.2;
  double stopThreshold = 130;
  double spinDamping = 0.55;

  bool landed = false;
  bool temp = false;

  double get alpha {
    if (rest <= 1.5) return 1;
    return (1 - (rest - 1.5) / 0.65).clamp(0.0, 1.0).toDouble();
  }
}

class _BouncingCoinsState extends State<BouncingCoins>
    with SingleTickerProviderStateMixin {
  static const double _gravity = 1100;
  static const double _airDrag = 0.35;
  static const double _horizontalDrag = 0.65;
  static const double _dtFixed = 1 / 120;
  static const int _maxTapCoins = 8;

  final math.Random _rng = math.Random();
  final List<_Coin> _coins = <_Coin>[];
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  late final Ticker _ticker = createTicker(_onTick);

  Size _size = Size.zero;
  Duration _last = Duration.zero;
  double _accumulator = 0;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _reduceMotion = reduceMotion;

    if (reduceMotion) {
      _ticker.stop();
      _placeStatic();
    } else if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(covariant BouncingCoins oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.count != widget.count) {
      _syncCoinCount();
    }

    if (oldWidget.minRadius != widget.minRadius ||
        oldWidget.maxRadius != widget.maxRadius) {
      for (final coin in _coins) {
        coin.r = _radius();
        coin.x = coin.x
            .clamp(coin.r, math.max(coin.r, _size.width - coin.r))
            .toDouble();
      }
    }

    if (_reduceMotion) _placeStatic();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  double _radius() {
    final range = widget.maxRadius - widget.minRadius;
    return widget.minRadius + _rng.nextDouble() * range;
  }

  void _layout(Size size) {
    if (size == _size) return;
    _size = size;
    if (size.isEmpty) return;

    if (_coins.isEmpty) {
      _syncCoinCount(initial: true);
    } else {
      for (final coin in _coins) {
        coin.x = coin.x
            .clamp(coin.r, math.max(coin.r, size.width - coin.r))
            .toDouble();
      }
    }

    if (_reduceMotion) _placeStatic();
  }

  void _syncCoinCount({bool initial = false}) {
    final permanent = _coins.where((coin) => !coin.temp).toList();

    while (permanent.length > widget.count) {
      final coin = permanent.removeLast();
      _coins.remove(coin);
    }

    while (permanent.length < widget.count) {
      final coin = _Coin(_radius());
      _respawn(coin, first: initial);
      _coins.add(coin);
      permanent.add(coin);
    }

    if (_reduceMotion) _placeStatic();
  }

  void _respawn(_Coin coin, {bool first = false}) {
    coin.r = _radius();
    final maxX = math.max(0.0, _size.width - 2 * coin.r).toDouble();
    coin.x = coin.r + _rng.nextDouble() * maxX;
    coin.y = -coin.r * (1.5 + _rng.nextDouble() * 2.5);

    coin.vx = (_rng.nextDouble() - 0.5) * 100;
    coin.vy = 20 + _rng.nextDouble() * 90;

    coin.flip = _rng.nextDouble() * math.pi * 2;
    coin.flipSpeed = (3 + _rng.nextDouble() * 5) * (_rng.nextBool() ? 1 : -1);

    coin.swayAmp = 0.08 + _rng.nextDouble() * 0.2;
    coin.swayFreq = 1.4 + _rng.nextDouble() * 2.0;
    coin.phase = _rng.nextDouble() * math.pi * 2;

    // Pantulan sedikit & cepat berhenti.
    coin.bounceFactor = 0.16 + _rng.nextDouble() * 0.10;
    coin.stopThreshold = 110 + _rng.nextDouble() * 60;
    coin.spinDamping = 0.5 + _rng.nextDouble() * 0.15;

    coin.age = 0;
    coin.tilt = 0;
    coin.rest = 0;
    coin.lie = 0;
    coin.landed = false;
    coin.delay = first ? _rng.nextDouble() * 2.2 : _rng.nextDouble() * 0.75;
  }

  void _placeStatic() {
    if (_size.isEmpty) return;

    final floorY = _size.height - widget.floorInset;
    for (final coin in _coins) {
      coin.x =
          coin.r +
          _rng.nextDouble() *
              math.max(0.0, _size.width - 2 * coin.r).toDouble();
      coin.y = floorY - coin.r;
      coin.vx = 0;
      coin.vy = 0;
      coin.flipSpeed = 0;
      coin.tilt = 0;
      coin.rest = 0;
      coin.delay = 0;
      coin.lie = 1;
      coin.landed = true;
    }
    _frame.value++;
  }

  void _onTick(Duration elapsed) {
    if (_size.isEmpty || _reduceMotion) return;

    final dt = ((elapsed - _last).inMicroseconds / 1e6)
        .clamp(0.0, 0.05)
        .toDouble();
    _last = elapsed;
    _accumulator += dt;

    while (_accumulator >= _dtFixed) {
      _step(_dtFixed);
      _accumulator -= _dtFixed;
    }

    _frame.value++;
  }

  void _step(double dt) {
    final width = _size.width;
    final floorY = _size.height - widget.floorInset;

    for (var i = _coins.length - 1; i >= 0; i--) {
      final coin = _coins[i];

      if (coin.delay > 0) {
        coin.delay = math.max(0.0, coin.delay - dt).toDouble();
        continue;
      }

      // Koin sudah benar-benar berhenti di lantai.
      if (coin.landed && coin.vy == 0) {
        coin.rest += dt;
        coin.lie += (1 - coin.lie) * math.min(1.0, dt * 16);

        final targetFlip = (coin.flip / (math.pi * 2)).round() * math.pi * 2;
        coin.flip += (targetFlip - coin.flip) * math.min(1.0, dt * 12);
        coin.flipSpeed *= math.exp(-16 * dt);
        coin.tilt *= math.exp(-14 * dt);

        if (coin.rest > 2.15) {
          if (coin.temp) {
            _coins.removeAt(i);
          } else {
            _respawn(coin);
          }
        }
        continue;
      }

      coin.age += dt;

      // Integrasi gravitasi dan hambatan udara yang stabil.
      coin.vy += _gravity * dt;
      coin.vy *= math.exp(-_airDrag * dt);
      coin.vx *= math.exp(-_horizontalDrag * dt);

      coin.x += coin.vx * dt;
      coin.y += coin.vy * dt;
      coin.flip += coin.flipSpeed * dt;

      if (coin.landed) {
        coin.flipSpeed *= math.exp(-10 * dt);
        coin.lie += (1 - coin.lie) * math.min(1.0, dt * 12);
        coin.tilt *= math.exp(-10 * dt);
      } else {
        coin.flipSpeed *= math.exp(-0.12 * dt);
        coin.tilt =
            math.sin(coin.age * coin.swayFreq + coin.phase) * coin.swayAmp;
      }

      // Pantulan horizontal dari tepi area.
      if (coin.x < coin.r) {
        coin.x = coin.r;
        coin.vx = coin.vx.abs() * 0.72;
      } else if (coin.x > width - coin.r) {
        coin.x = width - coin.r;
        coin.vx = -coin.vx.abs() * 0.72;
      }

      // Kontak lantai dan kehilangan energi saat memantul.
      if (coin.y >= floorY - coin.r) {
        coin.y = floorY - coin.r;

        if (coin.vy > coin.stopThreshold) {
          coin.vy = -coin.vy * coin.bounceFactor;
          coin.vx *= 0.72;
          coin.flipSpeed *= coin.spinDamping;
          coin.landed = true;
          coin.lie = math.max(coin.lie, 0.55);
        } else {
          coin.vy = 0;
          coin.vx *= 0.25;
          if (coin.vx.abs() < 8) coin.vx = 0;
          coin.landed = coin.vx == 0;
        }
      }
    }
  }

  void _spawnAt(Offset position) {
    if (_reduceMotion || _size.width < 80) return;
    if (_coins.where((coin) => coin.temp).length >= _maxTapCoins) return;

    final floorY = _size.height - widget.floorInset;
    final coin = _Coin(_radius())..temp = true;
    _respawn(coin);

    coin.x = position.dx.clamp(coin.r, _size.width - coin.r).toDouble();
    coin.y = position.dy.clamp(-coin.r, floorY - coin.r - 1).toDouble();
    coin.vy = -480 - _rng.nextDouble() * 100;
    coin.vx = (_rng.nextDouble() - 0.5) * 260;
    coin.flipSpeed = (4 + _rng.nextDouble() * 6) * (_rng.nextBool() ? 1 : -1);
    coin.delay = 0;

    _coins.add(coin);
    _frame.value++;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        _layout(size);

        Widget canvas = RepaintBoundary(
          child: SizedBox.expand(
            child: CustomPaint(
              painter: _CoinsPainter(
                coins: _coins,
                floorY: size.height - widget.floorInset,
                faceLight: widget.faceLight,
                faceDark: widget.faceDark,
                rim: widget.rim,
                repaint: _frame,
              ),
            ),
          ),
        );

        if (widget.interactive) {
          canvas = Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) => _spawnAt(event.localPosition),
            child: canvas,
          );
        }

        return canvas;
      },
    );
  }
}

class _CoinsPainter extends CustomPainter {
  _CoinsPainter({
    required this.coins,
    required this.floorY,
    required this.faceLight,
    required this.faceDark,
    required this.rim,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final List<_Coin> coins;
  final double floorY;
  final Color faceLight;
  final Color faceDark;
  final Color rim;

  final Map<int, TextPainter> _labels = <int, TextPainter>{};

  @override
  void paint(Canvas canvas, Size size) {
    for (final coin in coins) {
      if (coin.delay > 0) continue;

      final alpha = coin.alpha;
      if (alpha <= 0) continue;

      _drawShadow(canvas, coin, alpha);
      _drawCoin(canvas, coin, alpha);
    }
  }

  void _drawShadow(Canvas canvas, _Coin coin, double alpha) {
    final height = (floorY - coin.r - coin.y).clamp(0.0, 280.0).toDouble();
    final proximity = 1 - height / 280;
    if (proximity <= 0) return;

    final grounded = 0.45 + 0.55 * proximity;
    final widthScale = 0.55 + 0.45 * proximity;
    final shadowRect = Rect.fromCenter(
      center: Offset(coin.x, floorY - coin.r * 0.08),
      width: coin.r * 2.2 * widthScale,
      height: coin.r * 0.38 * grounded,
    );

    canvas.drawOval(
      shadowRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18 * proximity * alpha)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          2 + (1 - proximity) * 5,
        ),
    );
  }

  void _drawCoin(Canvas canvas, _Coin coin, double alpha) {
    final r = coin.r;
    final perspective = math.max(math.cos(coin.flip).abs(), 0.12);
    final heightScale = 1 - 0.48 * coin.lie;
    final sideWidth = r * 0.18 * (1 - perspective);

    canvas.save();
    canvas.translate(coin.x, coin.y + r * (1 - heightScale));
    canvas.rotate(coin.tilt);

    // Sisi koin terlihat ketika permukaannya berputar menjauhi kamera.
    if (sideWidth > 0.5) {
      canvas.save();
      canvas.scale(perspective, heightScale);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, r * 0.08),
          width: r * 2 + sideWidth * 2,
          height: r * 1.95,
        ),
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  rim.withValues(alpha: alpha),
                  faceDark.withValues(alpha: alpha),
                  rim.withValues(alpha: alpha),
                ],
              ).createShader(
                Rect.fromCenter(
                  center: Offset.zero,
                  width: r * 2.2,
                  height: r * 2,
                ),
              ),
      );
      canvas.restore();
    }

    canvas.scale(perspective, heightScale);

    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);

    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.48),
          radius: 0.95,
          colors: [
            faceLight.withValues(alpha: alpha),
            Color.lerp(faceLight, faceDark, 0.45)!.withValues(alpha: alpha),
            faceDark.withValues(alpha: alpha),
          ],
          stops: const [0, 0.56, 1],
        ).createShader(bounds),
    );

    canvas.drawCircle(
      Offset.zero,
      r * 0.91,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..color = rim.withValues(alpha: alpha),
    );

    canvas.drawCircle(
      Offset.zero,
      r * 0.72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.055
        ..color = rim.withValues(alpha: 0.58 * alpha),
    );

    // Highlight kecil membuat permukaan tampak mengilap.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.28, -r * 0.42),
        width: r * 0.42,
        height: r * 0.18,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.36 * alpha),
    );

    if (perspective > 0.42) {
      final fontSize = r * 0.68;
      final key = (fontSize * 10).round();
      final painter = _labels.putIfAbsent(
        key,
        () => TextPainter(
          text: TextSpan(
            text: 'Rp',
            style: TextStyle(
              color: rim,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      );

      // TextPainter di-cache berdasarkan ukuran font, bukan radius bulat.
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CoinsPainter oldDelegate) {
    return oldDelegate.coins != coins ||
        oldDelegate.floorY != floorY ||
        oldDelegate.rim != rim ||
        oldDelegate.faceLight != faceLight ||
        oldDelegate.faceDark != faceDark;
  }
}
