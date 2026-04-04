import 'package:apidash/models/grpc_request_model.dart';

class GRPCCCodeGen {
  String getCode(GrpcRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'localhost:50051' : model.url;
    final host = url.replaceFirst(RegExp(r'^https?://'), '');

    buf.writeln('#include <grpc/grpc.h>');
    buf.writeln('#include <grpc/support/log.h>');
    buf.writeln('#include <stdio.h>');
    buf.writeln();
    buf.writeln('int main() {');
    buf.writeln('    grpc_init();');
    if (model.useTls) {
      buf.writeln(
        '    grpc_channel_credentials *creds = grpc_ssl_credentials_create(NULL, NULL, NULL, NULL);',
      );
      buf.writeln('    grpc_channel *channel = grpc_channel_create(');
      buf.writeln('        "$host", creds, NULL);');
    } else {
      buf.writeln('    grpc_channel *channel = grpc_insecure_channel_create(');
      buf.writeln('        "$host", NULL, NULL);');
    }
    buf.writeln('    // Use generated stub from your .proto file');
    buf.writeln(
      '    // e.g., MyService__Stub *stub = my_service__stub_new(channel);',
    );
    buf.writeln('    grpc_channel_destroy(channel);');
    buf.writeln('    grpc_shutdown();');
    buf.writeln('    return 0;');
    buf.writeln('}');
    return buf.toString();
  }
}

class GRPCCSharpCodeGen {
  String getCode(GrpcRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'localhost:50051' : model.url;
    final host = url.replaceFirst(RegExp(r'^https?://'), '');
    final prefix = model.useTls ? 'https://' : 'http://';
    final service = model.serviceName.isEmpty ? 'MyService' : model.serviceName;
    final method = model.methodName.isEmpty ? 'MyMethod' : model.methodName;

    buf.writeln('using Grpc.Net.Client;');
    buf.writeln('using Grpc.Core;');
    buf.writeln('// using YourNamespace; // generated from .proto');
    buf.writeln();
    buf.writeln('using var channel = GrpcChannel.ForAddress("$prefix$host");');
    buf.writeln('var client = new $service.${service}Client(channel);');
    buf.writeln();

    final metadata = model.metadata
        .asMap()
        .entries
        .where(
          (e) =>
              model.isMetadataEnabledList.length > e.key &&
              model.isMetadataEnabledList[e.key],
        )
        .map((e) => e.value)
        .where((m) => m.name.isNotEmpty)
        .toList();
    if (metadata.isNotEmpty) {
      buf.writeln('var headers = new Metadata();');
      for (final m in metadata) {
        buf.writeln('headers.Add("${m.name}", "${m.value}");');
      }
      buf.writeln(
        'var reply = await client.${method}Async(new Empty(), headers);',
      );
    } else {
      buf.writeln('var reply = await client.${method}Async(new Empty());');
    }
    buf.writeln('Console.WriteLine("Response: " + reply);');
    return buf.toString();
  }
}

class GRPCGoCodeGen {
  String getCode(GrpcRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'localhost:50051' : model.url;
    final host = url.replaceFirst(RegExp(r'^https?://'), '');
    final service = model.serviceName.isEmpty ? 'MyService' : model.serviceName;
    final method = model.methodName.isEmpty ? 'MyMethod' : model.methodName;

    final metadata = model.metadata
        .asMap()
        .entries
        .where(
          (e) =>
              model.isMetadataEnabledList.length > e.key &&
              model.isMetadataEnabledList[e.key],
        )
        .map((e) => e.value)
        .where((m) => m.name.isNotEmpty)
        .toList();

    buf.writeln('package main');
    buf.writeln();
    buf.writeln('import (');
    buf.writeln('\t"context"');
    buf.writeln('\t"fmt"');
    buf.writeln('\t"log"');
    buf.writeln('\t"google.golang.org/grpc"');
    if (model.useTls) {
      buf.writeln('\t"google.golang.org/grpc/credentials"');
    } else {
      buf.writeln('\t"google.golang.org/grpc/credentials/insecure"');
    }
    if (metadata.isNotEmpty) {
      buf.writeln('\t"google.golang.org/grpc/metadata"');
    }
    buf.writeln('\t// pb "your_package/generated" // from .proto');
    buf.writeln(')');
    buf.writeln();
    buf.writeln('func main() {');
    if (model.useTls) {
      buf.writeln('\tcreds := credentials.NewClientTLSFromCert(nil, "")');
      buf.writeln(
        '\tconn, err := grpc.Dial("$host", grpc.WithTransportCredentials(creds))',
      );
    } else {
      buf.writeln(
        '\tconn, err := grpc.Dial("$host", grpc.WithTransportCredentials(insecure.NewCredentials()))',
      );
    }
    buf.writeln('\tif err != nil { log.Fatalf("Failed to connect: %v", err) }');
    buf.writeln('\tdefer conn.Close()');
    buf.writeln();
    buf.writeln('\t// c := pb.New${service}Client(conn)');

    if (metadata.isNotEmpty) {
      buf.writeln('\tctx := context.Background()');
      for (final m in metadata) {
        buf.writeln(
          '\tctx = metadata.AppendToOutgoingContext(ctx, "${m.name}", "${m.value}")',
        );
      }
      buf.writeln('\t// r, err := c.$method(ctx, &pb.Request{})');
    } else {
      buf.writeln(
        '\t// r, err := c.$method(context.Background(), &pb.Request{})',
      );
    }
    buf.writeln('\tfmt.Println("Connected to $host")');
    buf.writeln('}');
    return buf.toString();
  }
}

class GRPCJavaCodeGen {
  String getCode(GrpcRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'localhost:50051' : model.url;
    final String host = url.replaceFirst(RegExp(r'^https?://'), '');
    final String hostName = host.split(':')[0];
    final String portStr = host.contains(':')
        ? host.split(':')[1]
        : (model.useTls ? '443' : '50051');
    final service = model.serviceName.isEmpty ? 'MyService' : model.serviceName;
    final method = model.methodName.isEmpty ? 'myMethod' : model.methodName;

    buf.writeln('import io.grpc.ManagedChannel;');
    buf.writeln('import io.grpc.ManagedChannelBuilder;');
    buf.writeln('// import your.package.${service}Grpc; // generated');
    buf.writeln();
    buf.writeln('public class GrpcClient {');
    buf.writeln(
      '    public static void main(String[] args) throws InterruptedException {',
    );
    buf.writeln(
      '        ManagedChannelBuilder<?> builder = ManagedChannelBuilder.forAddress("$hostName", $portStr);',
    );
    if (!model.useTls) {
      buf.writeln('        builder.usePlaintext();');
    }
    buf.writeln('        ManagedChannel channel = builder.build();');
    buf.writeln();
    buf.writeln('        // ${service}Grpc.${service}BlockingStub stub =');
    buf.writeln('        //     ${service}Grpc.newBlockingStub(channel);');
    buf.writeln(
      '        // var response = stub.$method(Request.newBuilder().build());',
    );
    buf.writeln('        // System.out.println(response);');
    buf.writeln();
    buf.writeln('        channel.shutdown();');
    buf.writeln('    }');
    buf.writeln('}');
    return buf.toString();
  }
}

class GRPCKotlinCodeGen {
  String getCode(GrpcRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'localhost:50051' : model.url;
    final host = url.replaceFirst(RegExp(r'^https?://'), '');
    final String hostName = host.split(':')[0];
    final String portStr = host.contains(':')
        ? host.split(':')[1]
        : (model.useTls ? '443' : '50051');
    final service = model.serviceName.isEmpty ? 'MyService' : model.serviceName;
    final method = model.methodName.isEmpty ? 'myMethod' : model.methodName;

    buf.writeln('import io.grpc.ManagedChannelBuilder');
    buf.writeln('// import your.package.${service}GrpcKt // generated');
    buf.writeln();
    buf.writeln('fun main() {');
    buf.writeln(
      '    val builder = ManagedChannelBuilder.forAddress("$hostName", $portStr)',
    );
    if (!model.useTls) {
      buf.writeln('    builder.usePlaintext()');
    }
    buf.writeln('    val channel = builder.build()');
    buf.writeln();
    buf.writeln(
      '    // val stub = ${service}GrpcKt.${service}CoroutineStub(channel)',
    );
    buf.writeln('    // val response = stub.$method(request { })');
    buf.writeln('    // println(response)');
    buf.writeln();
    buf.writeln('    channel.shutdown()');
    buf.writeln('}');
    return buf.toString();
  }
}

class GRPCPHPCodeGen {
  String getCode(GrpcRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'localhost:50051' : model.url;
    final host = url.replaceFirst(RegExp(r'^https?://'), '');
    final service = model.serviceName.isEmpty ? 'MyService' : model.serviceName;
    final method = model.methodName.isEmpty ? 'myMethod' : model.methodName;

    buf.writeln('<?php');
    buf.writeln('require "vendor/autoload.php";');
    buf.writeln();
    buf.writeln('// Generated from .proto file');
    buf.writeln('// use Helloworld\\GreeterClient;');
    buf.writeln();
    buf.writeln('\$client = new ${service}Client("$host", [');
    if (model.useTls) {
      buf.writeln(
        '    "credentials" => Grpc\\ChannelCredentials::createSsl(),',
      );
    } else {
      buf.writeln(
        '    "credentials" => Grpc\\ChannelCredentials::createInsecure(),',
      );
    }
    buf.writeln(']);');
    buf.writeln();
    buf.writeln('\$request = new MyRequest();');
    buf.writeln(
      'list(\$response, \$status) = \$client->$method(\$request)->wait();',
    );
    buf.writeln();
    buf.writeln('if (\$status->code !== Grpc\\STATUS_OK) {');
    buf.writeln('    echo "ERROR: " . \$status->details . "\\n";');
    buf.writeln('} else {');
    buf.writeln(
      '    echo "Response: " . \$response->serializeToJsonString() . "\\n";',
    );
    buf.writeln('}');
    return buf.toString();
  }
}

class GRPCRubyCodeGen {
  String getCode(GrpcRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'localhost:50051' : model.url;
    final host = url.replaceFirst(RegExp(r'^https?://'), '');
    final service = model.serviceName.isEmpty ? 'MyService' : model.serviceName;
    final method = model.methodName.isEmpty ? 'my_method' : model.methodName;

    buf.writeln('require "grpc"');
    buf.writeln(
      '# require_relative "my_service_services_pb" # generated from .proto',
    );
    buf.writeln();
    if (model.useTls) {
      buf.writeln(
        'stub = $service::Stub.new("$host", grpc::Core::ChannelCredentials.new)',
      );
    } else {
      buf.writeln(
        'stub = $service::Stub.new("$host", :this_channel_is_insecure)',
      );
    }
    buf.writeln();
    buf.writeln('request = MyRequest.new');
    buf.writeln('response = stub.$method(request)');
    buf.writeln('puts "Response: #{response.inspect}"');
    return buf.toString();
  }
}

class GRPCRustCodeGen {
  String getCode(GrpcRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'localhost:50051' : model.url;
    final host = url.replaceFirst(RegExp(r'^https?://'), '');
    final prefix = model.useTls ? 'https://' : 'http://';
    final service = model.serviceName.isEmpty ? 'MyService' : model.serviceName;
    final method = model.methodName.isEmpty ? 'my_method' : model.methodName;

    buf.writeln('// Add to Cargo.toml:');
    buf.writeln('// tonic = "0.11"');
    buf.writeln('// prost = "0.12"');
    buf.writeln();
    buf.writeln('// tonic::include_proto!("your_package"); // from build.rs');
    buf.writeln();
    buf.writeln('use tonic::transport::Channel;');
    buf.writeln();
    buf.writeln('#[tokio::main]');
    buf.writeln('async fn main() -> Result<(), Box<dyn std::error::Error>> {');
    buf.writeln('    let channel = Channel::from_static("$prefix$host")');
    buf.writeln('        .connect()');
    buf.writeln('        .await?;');
    buf.writeln();
    buf.writeln('    // let mut client = ${service}Client::new(channel);');
    buf.writeln('    // let request = tonic::Request::new(MyRequest {});');
    buf.writeln('    // let response = client.$method(request).await?;');
    buf.writeln('    // println!("Response: {:?}", response.into_inner());');
    buf.writeln();
    buf.writeln('    Ok(())');
    buf.writeln('}');
    return buf.toString();
  }
}

class GRPCSwiftCodeGen {
  String getCode(GrpcRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'localhost:50051' : model.url;
    final host = url.replaceFirst(RegExp(r'^https?://'), '');
    final String hostName = host.split(':')[0];
    final String portStr = host.contains(':')
        ? host.split(':')[1]
        : (model.useTls ? '443' : '50051');
    final service = model.serviceName.isEmpty ? 'MyService' : model.serviceName;
    final method = model.methodName.isEmpty ? 'myMethod' : model.methodName;

    buf.writeln('import GRPC');
    buf.writeln('import NIO');
    buf.writeln('// import Generated // from .proto via protoc-gen-grpc-swift');
    buf.writeln();
    buf.writeln('let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)');
    buf.writeln('defer { try! group.syncShutdownGracefully() }');
    buf.writeln();
    buf.writeln('let channel = try GRPCChannelPool.with(');
    buf.writeln('    target: .host("$hostName", port: $portStr),');
    if (model.useTls) {
      buf.writeln('    transportSecurity: .tls,');
    } else {
      buf.writeln('    transportSecurity: .plaintext,');
    }
    buf.writeln('    eventLoopGroup: group');
    buf.writeln(')');
    buf.writeln('defer { try! channel.close().wait() }');
    buf.writeln();
    buf.writeln('// let client = ${service}NIOClient(channel: channel)');
    buf.writeln('// let request = MyRequest()');
    buf.writeln(
      '// let response = try client.$method(request).response.wait()',
    );
    buf.writeln('// print("Response: \\(response)")');
    return buf.toString();
  }
}

class GrpcCurlCodeGen {
  String getCode(GrpcRequestModel model) {
    final url = model.url.isEmpty ? 'localhost:50051' : model.url;
    return 'grpcurl -plaintext $url ${model.serviceName}/${model.methodName}';
  }
}

class GrpcHarCodeGen {
  String getCode(GrpcRequestModel model) {
    return '{\n  "log": {\n    "version": "1.2",\n    "creator": {\n      "name": "APIDash",\n      "version": "1.0.0"\n    },\n    "entries": []\n  }\n}';
  }
}

class GrpcJuliaCodeGen {
  String getCode(GrpcRequestModel model) {
    final url = model.url.isEmpty ? 'localhost:50051' : model.url;
    return 'using gRPCClient\n\nprintln("Connect to $url using gRPCClient.jl")';
  }
}
