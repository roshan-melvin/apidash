import 'package:args/command_runner.dart';
import 'commands/list_command.dart';
import 'commands/run_command.dart';
import 'commands/request_command.dart';
import 'commands/graphql_command.dart';
import 'commands/ai_command.dart';
import 'commands/save_command.dart';
import 'commands/env_command.dart';
import 'commands/set_command.dart';
import 'commands/codegen_command.dart';

class CliRunner extends CommandRunner<void> {
  CliRunner() : super('apidash-cli', 'APIDash Headless CLI') {
    addCommand(ListCommand());
    addCommand(RunCommand());
    addCommand(RequestCommand());
    addCommand(GraphqlCommand());
    addCommand(AiCommand());
    addCommand(SaveCommand());
    addCommand(EnvCommand());
    addCommand(SetCommand());
    addCommand(CodegenCommand());
  }
}
