import 'package:args/command_runner.dart';
class RunCommand extends Command<void> {
  @override final name = 'run';
  @override final description = 'Run commands';
  @override void run() {}
}
