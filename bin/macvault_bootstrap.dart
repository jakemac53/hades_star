import 'dart:async';
import 'dart:isolate';

main() async {
  while (true) {
    var isolate =
        await Isolate.spawnUri(new Uri.file('macvault.dart'), [], null);
    var receivePort = new ReceivePort();
    isolate.addErrorListener(receivePort.sendPort);
    await receivePort.first;
    isolate.kill(priority: Isolate.immediate);
    await new Future.delayed(new Duration(seconds: 1));
  }
}
