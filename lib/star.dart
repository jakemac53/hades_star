import 'dart:html';
import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'common.dart';
import 'jump_gate.dart';
import 'planet.dart';
import 'sector.dart';

class Star extends GameObject {
  @override
  double x = 0.0;

  @override
  double y = 0.0;

  @override
  final double height;

  @override
  final double width;

  final List<Planet> planets;

  final List<Sector> sectors;

  final List<JumpGate> jumpGates;

  Star._(
      {@required this.planets,
      @required this.height,
      @required this.width,
      @required int numLayers})
      : sectors = <Sector>[],
        jumpGates = <JumpGate>[] {
    for (var q = -numLayers + 1; q < numLayers; q++) {
      for (var r = -numLayers + 1; r < numLayers; r++) {
        if (q + r < -(numLayers - 1)) continue;
        if (q + r > (numLayers - 1)) continue;

        var x = Sector.SIZE * 3 / 2 * q;
        var y = Sector.SIZE * math.sqrt(3) * (r + q / 2);
        var col = q + (numLayers / 2).floor() + 1;
        var row = col < numLayers ? r + col + 1 : r + numLayers;
        var sector = new Sector(
            x: x + centerX, y: y + centerY, name: '${letters[col]}$row');
        sectors.add(sector);
      }
    }
  }

  final letters = const ['a', 'b', 'c', 'd', 'e', 'f', 'g'];

  // Create a star with [numLayers] layers of hexes making up the overall hex.
  factory Star(int numLayers) {
    var totalHeight = (Sector.HEIGHT * ((numLayers - 1) * 2 + 1));
    var totalWidth = (Sector.WIDTH * ((((numLayers - 1) ~/ 2) * 2) + 1) +
        Sector.WIDTH * 0.5 * (numLayers ~/ 2) * 2);
    if (totalWidth.floor() % 2 == 0) {
      totalWidth += (2 * Sector.WIDTH * .25).floor();
    }

    return new Star._(
        planets: [],
        numLayers: numLayers,
        height: totalHeight,
        width: totalWidth);
  }

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    for (var sector in sectors) {
      sector.draw(renderCtx, gameCtx);
    }
    for (var planet in planets) {
      planet.draw(renderCtx, gameCtx);
    }
    for (var jumpGate in jumpGates) {
      jumpGate.draw(renderCtx, gameCtx);
    }
    renderCtx.setStrokeColorRgb(0, 255, 0);
    renderCtx.font = '40px sans-serif';
    renderCtx.setFillColorRgb(255, 255, 255);
    var objects = new List<GameObject>.from(planets)..addAll(jumpGates);
    for (var planet in planets) {
      objects.remove(planet);
      _drawDistances(planet, objects, renderCtx);
    }
  }

  void _drawDistances(Planet planet, List<GameObject> objects,
      CanvasRenderingContext2D renderCtx) {
    for (var object in objects) {
      _drawDistance(planet, object, renderCtx);
    }
  }

  void _drawDistance(
      GameObject from, GameObject to, CanvasRenderingContext2D renderCtx) {
    var oldWidth = renderCtx.lineWidth;
    renderCtx.lineWidth = 4;
    renderCtx.setLineDash([8, 16]);
    renderCtx.moveTo(from.centerX, from.centerY);
    renderCtx.lineTo(to.centerX, to.centerY);
    renderCtx.stroke();
    renderCtx.setLineDash([]);
    renderCtx.lineWidth = oldWidth;

    var xDiff = from.x - to.x;
    var yDiff = from.y - to.y;
    var distance =
        math.sqrt(math.pow(xDiff.abs(), 2) + math.pow(yDiff.abs(), 2)).round();
    renderCtx.fillText(
        '${distance}au', from.centerX - xDiff / 2, from.centerY - yDiff / 2);
  }
}
