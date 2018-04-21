import 'dart:html';
// import 'dart:math' as math;

import 'package:hades_simulator/common.dart';
// import 'package:hades_simulator/sector.dart';
import 'package:hades_simulator/star.dart';

main() {
  var star = new Star(4);
  var gameCtx = new GameContext(star: star, scale: 0.2);
  var canvas = new CanvasElement();

  var width = star.width.floor();
  var height = star.height.floor();
  canvas.style
    ..width = '${width}px'
    ..height = '${height}px';
  canvas.width = width;
  canvas.height = height;

  var renderCtx = canvas.context2D;
  renderCtx.scale(gameCtx.scale, gameCtx.scale);
  renderCtx.setFillColorRgb(0, 0, 0);
  renderCtx.fillRect(0, 0, canvas.width, canvas.height);
  document.body.append(canvas);
  star.draw(renderCtx, gameCtx);
}
