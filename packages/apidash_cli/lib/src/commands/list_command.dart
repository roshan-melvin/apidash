import 'package:args/command_runner.dart';
class ListCommand extends Command<void> {
  @override final name = 'list';
  @override final description = 'List commands';
  @override void run() {}
}
