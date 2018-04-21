import 'dart:html';
import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'common.dart';
import 'sector.dart';

class Star extends GameObject {
  @override
  double get x => 0.0;

  @override
  double get y => 0.0;

  @override
  final double height;

  @override
  final double width;

  final List<Sector> sectors;

  Star._({@required this.sectors, @required this.height, @required this.width});

  // Create a star with [numLayers] layers of hexes making up the overall hex.
  factory Star(int numLayers) {
    var sectors = <Sector>[];
    for (var q = -numLayers + 1; q < numLayers; q++) {
      for (var r = -numLayers + 1; r < numLayers; r++) {
        if (q + r < -(numLayers - 1)) continue;
        if (q + r > (numLayers - 1)) continue;

        var x = Sector.SIZE * 3 / 2 * q;
        var y = Sector.SIZE * math.sqrt(3) * (r + q / 2);
        sectors.add(new Sector(x: x, y: y));
      }
    }
    var totalHeight = (Sector.HEIGHT * ((numLayers - 1) * 2 + 1));
    var totalWidth = (Sector.WIDTH * ((((numLayers - 1) ~/ 2) * 2) + 1) +
        Sector.WIDTH * 0.5 * (numLayers ~/ 2) * 2);
    if (totalWidth.floor() % 2 == 0) {
      totalWidth += (2 * Sector.WIDTH * .25).floor();
    }

    return new Star._(sectors: sectors, height: totalHeight, width: totalWidth);
  }

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    for (var sector in sectors) {
      sector.draw(renderCtx, gameCtx);
    }
  }
}
