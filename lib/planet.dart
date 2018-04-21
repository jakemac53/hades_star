import 'package:meta/meta.dart';

import 'common.dart';

class Planet extends GameObject {
  @override
  final double x;
  @override
  final double y;
  @override
  final double width;
  @override
  final double height;

  Planet(
      {@required this.x,
      @required this.y,
      @required this.width,
      @required this.height});
}
