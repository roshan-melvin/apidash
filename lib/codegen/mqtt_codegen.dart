import 'package:apidash/models/mqtt_request_model.dart';

class MQTTCMosquittoCodeGen {
  String getCode(MQTTRequestModel model) {
    final buf = StringBuffer();
    final host = model.brokerUrl.isEmpty
        ? 'broker.mosquitto.org'
        : model.brokerUrl;
    final port = model.port;
    final clientId = model.clientId.isEmpty ? 'apidash_client' : model.clientId;

    buf.writeln('#include <stdio.h>');
    buf.writeln('#include <mosquitto.h>');
    buf.writeln('#include <string.h>');
    buf.writeln();
    buf.writeln('void on_connect(struct mosquitto *mosq, void *obj, int rc) {');
    buf.writeln('    printf("Connected: %d\\n", rc);');
    if (model.topics.isNotEmpty) {
      for (final t in model.topics) {
        if (t.topic.isNotEmpty) {
          buf.writeln(
            '    mosquitto_subscribe(mosq, NULL, "${t.topic}", ${t.qos});',
          );
        }
      }
    }
    buf.writeln('}');
    buf.writeln();
    buf.writeln('void on_message(struct mosquitto *mosq, void *obj,');
    buf.writeln('                const struct mosquitto_message *msg) {');
    buf.writeln('    printf("[%s] %s\\n", msg->topic, (char *)msg->payload);');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('int main() {');
    buf.writeln('    mosquitto_lib_init();');
    buf.writeln(
      '    struct mosquitto *mosq = mosquitto_new("$clientId", true, NULL);',
    );
    buf.writeln('    mosquitto_connect_callback_set(mosq, on_connect);');
    buf.writeln('    mosquitto_message_callback_set(mosq, on_message);');
    buf.writeln('    mosquitto_connect(mosq, "$host", $port, 60);');
    if (model.publishTopic.isNotEmpty) {
      final msg = model.publishPayload.isEmpty
          ? 'Hello from APIDash'
          : model.publishPayload;
      buf.writeln(
        '    mosquitto_publish(mosq, NULL, "${model.publishTopic}", ${msg.length}, "$msg", 0, false);',
      );
    }
    buf.writeln('    mosquitto_loop_forever(mosq, -1, 1);');
    buf.writeln('    mosquitto_destroy(mosq);');
    buf.writeln('    mosquitto_lib_cleanup();');
    buf.writeln('    return 0;');
    buf.writeln('}');
    return buf.toString();
  }
}

class MQTTCSharpMQTTnetCodeGen {
  String getCode(MQTTRequestModel model) {
    final buf = StringBuffer();
    final host = model.brokerUrl.isEmpty
        ? 'broker.mosquitto.org'
        : model.brokerUrl;
    final port = model.port;
    final clientId = model.clientId.isEmpty ? 'apidash_client' : model.clientId;

    buf.writeln('using MQTTnet;');
    buf.writeln('using MQTTnet.Client;');
    buf.writeln('using System.Text;');
    buf.writeln();
    buf.writeln('var factory = new MqttFactory();');
    buf.writeln('var mqttClient = factory.CreateMqttClient();');
    buf.writeln();
    buf.writeln('var options = new MqttClientOptionsBuilder()');
    buf.writeln('    .WithClientId("$clientId")');
    buf.writeln('    .WithTcpServer("$host", $port)');
    buf.writeln('    .Build();');
    buf.writeln();
    buf.writeln('mqttClient.ApplicationMessageReceivedAsync += e => {');
    buf.writeln('    Console.WriteLine(\$"[{e.ApplicationMessage.Topic}] " +');
    buf.writeln(
      '        Encoding.UTF8.GetString(e.ApplicationMessage.PayloadSegment));',
    );
    buf.writeln('    return Task.CompletedTask;');
    buf.writeln('};');
    buf.writeln();
    buf.writeln('await mqttClient.ConnectAsync(options);');
    buf.writeln('Console.WriteLine("Connected!");');
    buf.writeln();
    if (model.topics.isNotEmpty) {
      buf.writeln('// Subscribe to topics');
      for (final t in model.topics) {
        if (t.topic.isNotEmpty) {
          buf.writeln(
            'await mqttClient.SubscribeAsync(new MqttTopicFilterBuilder()',
          );
          buf.writeln('    .WithTopic("${t.topic}")');
          buf.writeln(
            '    .WithQualityOfServiceLevel((MQTTnet.Protocol.MqttQualityOfServiceLevel)${t.qos})',
          );
          buf.writeln('    .Build());');
        }
      }
      buf.writeln();
    }
    if (model.publishTopic.isNotEmpty) {
      final msg = model.publishPayload.isEmpty
          ? 'Hello from APIDash'
          : model.publishPayload;
      buf.writeln('// Publish a message');
      buf.writeln('var message = new MqttApplicationMessageBuilder()');
      buf.writeln('    .WithTopic("${model.publishTopic}")');
      buf.writeln('    .WithPayload("$msg")');
      buf.writeln('    .Build();');
      buf.writeln('await mqttClient.PublishAsync(message);');
    }
    return buf.toString();
  }
}

class MQTTGoCodeGen {
  String getCode(MQTTRequestModel model) {
    final buf = StringBuffer();
    final host = model.brokerUrl.isEmpty
        ? 'broker.mosquitto.org'
        : model.brokerUrl;
    final port = model.port;
    final clientId = model.clientId.isEmpty ? 'apidash_client' : model.clientId;

    buf.writeln('package main');
    buf.writeln();
    buf.writeln('import (');
    buf.writeln('\t"fmt"');
    buf.writeln('\t"time"');
    buf.writeln('\tmqtt "github.com/eclipse/paho.mqtt.golang"');
    buf.writeln(')');
    buf.writeln();
    buf.writeln(
      'var messagePubHandler mqtt.MessageHandler = func(client mqtt.Client, msg mqtt.Message) {',
    );
    buf.writeln('\tfmt.Printf("[%s] %s\\n", msg.Topic(), msg.Payload())');
    buf.writeln('}');
    buf.writeln();
    buf.writeln(
      'var connectHandler mqtt.OnConnectHandler = func(client mqtt.Client) {',
    );
    buf.writeln('\tfmt.Println("Connected")');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('func main() {');
    buf.writeln('\topts := mqtt.NewClientOptions()');
    buf.writeln('\topts.AddBroker(fmt.Sprintf("tcp://$host:$port"))');
    buf.writeln('\topts.SetClientID("$clientId")');
    buf.writeln('\topts.SetDefaultPublishHandler(messagePubHandler)');
    buf.writeln('\topts.OnConnect = connectHandler');
    buf.writeln();
    buf.writeln('\tclient := mqtt.NewClient(opts)');
    buf.writeln(
      '\tif token := client.Connect(); token.Wait() && token.Error() != nil {',
    );
    buf.writeln('\t\tpanic(token.Error())');
    buf.writeln('\t}');
    buf.writeln();
    if (model.topics.isNotEmpty) {
      for (final t in model.topics) {
        if (t.topic.isNotEmpty) {
          buf.writeln('\tclient.Subscribe("${t.topic}", ${t.qos}, nil)');
        }
      }
      buf.writeln();
    }
    if (model.publishTopic.isNotEmpty) {
      final msg = model.publishPayload.isEmpty
          ? 'Hello from APIDash'
          : model.publishPayload;
      buf.writeln(
        '\ttoken := client.Publish("${model.publishTopic}", 0, false, "$msg")',
      );
      buf.writeln('\ttoken.Wait()');
      buf.writeln();
    }
    buf.writeln('\ttime.Sleep(time.Second)');
    buf.writeln('\tclient.Disconnect(250)');
    buf.writeln('}');
    return buf.toString();
  }
}

class MQTTJavaCodeGen {
  String getCode(MQTTRequestModel model) {
    final buf = StringBuffer();
    final host = model.brokerUrl.isEmpty
        ? 'broker.mosquitto.org'
        : model.brokerUrl;
    final port = model.port;
    final clientId = model.clientId.isEmpty ? 'apidash_client' : model.clientId;

    buf.writeln('import org.eclipse.paho.client.mqttv3.*;');
    buf.writeln(
      'import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;',
    );
    buf.writeln();
    buf.writeln('public class MQTTClient {');
    buf.writeln(
      '    public static void main(String[] args) throws MqttException {',
    );
    buf.writeln('        String broker = "tcp://$host:$port";');
    buf.writeln('        String clientId = "$clientId";');
    buf.writeln();
    buf.writeln(
      '        MqttClient client = new MqttClient(broker, clientId, new MemoryPersistence());',
    );
    buf.writeln(
      '        MqttConnectOptions options = new MqttConnectOptions();',
    );
    buf.writeln('        options.setCleanSession(true);');
    buf.writeln();
    buf.writeln('        client.setCallback(new MqttCallback() {');
    buf.writeln('            public void connectionLost(Throwable cause) {}');
    buf.writeln(
      '            public void messageArrived(String topic, MqttMessage message) {',
    );
    buf.writeln(
      '                System.out.println("[" + topic + "] " + new String(message.getPayload()));',
    );
    buf.writeln('            }');
    buf.writeln(
      '            public void deliveryComplete(IMqttDeliveryToken token) {}',
    );
    buf.writeln('        });');
    buf.writeln();
    buf.writeln('        client.connect(options);');
    buf.writeln(
      '        System.out.println("Connected to broker: " + broker);',
    );
    buf.writeln();
    if (model.topics.isNotEmpty) {
      for (final t in model.topics) {
        if (t.topic.isNotEmpty) {
          buf.writeln('        client.subscribe("${t.topic}", ${t.qos});');
        }
      }
      buf.writeln();
    }
    if (model.publishTopic.isNotEmpty) {
      final msg = model.publishPayload.isEmpty
          ? 'Hello from APIDash'
          : model.publishPayload;
      buf.writeln(
        '        MqttMessage message = new MqttMessage("$msg".getBytes());',
      );
      buf.writeln('        message.setQos(0);');
      buf.writeln('        client.publish("${model.publishTopic}", message);');
    }
    buf.writeln('    }');
    buf.writeln('}');
    return buf.toString();
  }
}

class MQTTKotlinCodeGen {
  String getCode(MQTTRequestModel model) {
    final buf = StringBuffer();
    final host = model.brokerUrl.isEmpty
        ? 'broker.mosquitto.org'
        : model.brokerUrl;
    final port = model.port;
    final clientId = model.clientId.isEmpty ? 'apidash_client' : model.clientId;

    buf.writeln('import org.eclipse.paho.client.mqttv3.*');
    buf.writeln(
      'import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence',
    );
    buf.writeln();
    buf.writeln('fun main() {');
    buf.writeln('    val broker = "tcp://$host:$port"');
    buf.writeln('    val clientId = "$clientId"');
    buf.writeln();
    buf.writeln(
      '    val client = MqttClient(broker, clientId, MemoryPersistence())',
    );
    buf.writeln(
      '    val options = MqttConnectOptions().apply { isCleanSession = true }',
    );
    buf.writeln();
    buf.writeln('    client.setCallback(object : MqttCallback {');
    buf.writeln('        override fun connectionLost(cause: Throwable?) {}');
    buf.writeln(
      '        override fun messageArrived(topic: String, message: MqttMessage) {',
    );
    buf.writeln('            println("[\$topic] \${String(message.payload)}")');
    buf.writeln('        }');
    buf.writeln(
      '        override fun deliveryComplete(token: IMqttDeliveryToken?) {}',
    );
    buf.writeln('    })');
    buf.writeln();
    buf.writeln('    client.connect(options)');
    buf.writeln('    println("Connected!")');
    buf.writeln();
    if (model.topics.isNotEmpty) {
      for (final t in model.topics) {
        if (t.topic.isNotEmpty) {
          buf.writeln('    client.subscribe("${t.topic}", ${t.qos})');
        }
      }
      buf.writeln();
    }
    if (model.publishTopic.isNotEmpty) {
      final msg = model.publishPayload.isEmpty
          ? 'Hello from APIDash'
          : model.publishPayload;
      buf.writeln('    val message = MqttMessage("$msg".toByteArray())');
      buf.writeln('    client.publish("${model.publishTopic}", message)');
    }
    buf.writeln('}');
    return buf.toString();
  }
}

class MQTTSwiftCodeGen {
  String getCode(MQTTRequestModel model) {
    final buf = StringBuffer();
    final host = model.brokerUrl.isEmpty
        ? 'broker.mosquitto.org'
        : model.brokerUrl;
    final port = model.port;
    final clientId = model.clientId.isEmpty ? 'apidash_client' : model.clientId;

    buf.writeln('import CocoaMQTT');
    buf.writeln();
    buf.writeln(
      'let mqtt = CocoaMQTT(clientID: "$clientId", host: "$host", port: UInt16($port))',
    );
    buf.writeln();
    buf.writeln('mqtt.didConnectAck = { mqtt, ack in');
    buf.writeln('    print("Connected: \\(ack)")');
    if (model.topics.isNotEmpty) {
      buf.writeln('    // Subscribe after connect');
      for (final t in model.topics) {
        if (t.topic.isNotEmpty) {
          buf.writeln(
            '    mqtt.subscribe("${t.topic}", qos: CocoaMQTTQoS(rawValue: UInt8(${t.qos}))!)',
          );
        }
      }
    }
    buf.writeln('}');
    buf.writeln();
    buf.writeln('mqtt.didReceiveMessage = { mqtt, message, id in');
    buf.writeln('    print("[\\(message.topic)] \\(message.string ?? "")")');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('mqtt.connect()');
    buf.writeln();
    if (model.publishTopic.isNotEmpty) {
      final msg = model.publishPayload.isEmpty
          ? 'Hello from APIDash'
          : model.publishPayload;
      buf.writeln('// Publish after a short delay to ensure connection');
      buf.writeln('DispatchQueue.main.asyncAfter(deadline: .now() + 1) {');
      buf.writeln(
        '    mqtt.publish("${model.publishTopic}", withString: "$msg")',
      );
      buf.writeln('}');
    }
    return buf.toString();
  }
}

class MQTTPhpCodeGen {
  String getCode(MQTTRequestModel model) {
    final buf = StringBuffer();
    final host = model.brokerUrl.isEmpty
        ? 'broker.mosquitto.org'
        : model.brokerUrl;
    final port = model.port;
    final clientId = model.clientId.isEmpty ? 'apidash_client' : model.clientId;

    buf.writeln('<?php');
    buf.writeln('require("vendor/autoload.php");');
    buf.writeln();
    buf.writeln('use \\PhpMqtt\\Client\\MqttClient;');
    buf.writeln('use \\PhpMqtt\\Client\\ConnectionSettings;');
    buf.writeln();
    buf.writeln('\$server   = "$host";');
    buf.writeln('\$port     = $port;');
    buf.writeln('\$clientId = "$clientId";');
    buf.writeln();
    buf.writeln('\$mqtt = new MqttClient(\$server, \$port, \$clientId);');
    buf.writeln();
    buf.writeln('\$settings = (new ConnectionSettings)');
    buf.writeln('  ->setKeepAliveInterval(${model.keepAlive})');
    if (model.topics.isNotEmpty) {
      buf.writeln('  ->setUseTls(${model.useTls ? 'true' : 'false'});');
    }
    buf.writeln();
    buf.writeln(
      '\$mqtt->connect(\$settings, ${model.cleanSession ? 'true' : 'false'});',
    );
    buf.writeln('printf("Connected!\n");');
    buf.writeln();
    if (model.topics.isNotEmpty) {
      for (final t in model.topics) {
        if (t.topic.isNotEmpty) {
          buf.writeln(
            '\$mqtt->subscribe("${t.topic}", function (\$topic, \$message) {',
          );
          buf.writeln('    printf("[%s] %s\n", \$topic, \$message);');
          buf.writeln('}, ${t.qos});');
        }
      }
      buf.writeln();
    }
    if (model.publishTopic.isNotEmpty) {
      final msg = model.publishPayload.isEmpty
          ? 'Hello from APIDash'
          : model.publishPayload;
      buf.writeln(
        '\$mqtt->publish("${model.publishTopic}", "$msg", ${model.publishQos});',
      );
    }
    buf.writeln();
    buf.writeln('\$mqtt->loop(true);');
    buf.writeln('\$mqtt->disconnect();');
    return buf.toString();
  }
}

class MQTTRubyCodeGen {
  String getCode(MQTTRequestModel model) {
    final buf = StringBuffer();
    final host = model.brokerUrl.isEmpty
        ? 'broker.mosquitto.org'
        : model.brokerUrl;
    final port = model.port;
    final clientId = model.clientId.isEmpty ? 'apidash_client' : model.clientId;

    buf.writeln('require "rubygems"');
    buf.writeln('require "mqtt"');
    buf.writeln();
    buf.writeln('client = MQTT::Client.connect(');
    buf.writeln('  host: "$host",');
    buf.writeln('  port: $port,');
    buf.writeln('  client_id: "$clientId"');
    buf.writeln(')');
    buf.writeln();
    buf.writeln('puts "Connected!"');
    buf.writeln();
    if (model.publishTopic.isNotEmpty) {
      final msg = model.publishPayload.isEmpty
          ? 'Hello from APIDash'
          : model.publishPayload;
      buf.writeln('client.publish("${model.publishTopic}", "$msg")');
    }
    if (model.topics.isNotEmpty) {
      for (final t in model.topics) {
        if (t.topic.isNotEmpty) {
          buf.writeln('client.subscribe("${t.topic}")');
        }
      }
      buf.writeln();
      buf.writeln('client.get do |topic, message|');
      buf.writeln('  puts "[#{topic}] #{message}"');
      buf.writeln('end');
    }
    return buf.toString();
  }
}

class MQTTRustCodeGen {
  String getCode(MQTTRequestModel model) {
    final buf = StringBuffer();
    final host = model.brokerUrl.isEmpty
        ? 'broker.mosquitto.org'
        : model.brokerUrl;
    final port = model.port;
    final clientId = model.clientId.isEmpty ? 'apidash_client' : model.clientId;

    buf.writeln('use rumqttc::{MqttOptions, Client, QoS};');
    buf.writeln('use std::time::Duration;');
    buf.writeln('use std::thread;');
    buf.writeln();
    buf.writeln('fn main() {');
    buf.writeln(
      '    let mut mqttoptions = MqttOptions::new("$clientId", "$host", $port);',
    );
    buf.writeln(
      '    mqttoptions.set_keep_alive(Duration::from_secs(${model.keepAlive}));',
    );
    buf.writeln();
    buf.writeln(
      '    let (mut client, mut connection) = Client::new(mqttoptions, 10);',
    );
    buf.writeln();
    if (model.topics.isNotEmpty) {
      for (final t in model.topics) {
        if (t.topic.isNotEmpty) {
          buf.writeln(
            '    client.subscribe("${t.topic}", QoS::AtMostOnce).unwrap();',
          );
        }
      }
    }
    buf.writeln();
    if (model.publishTopic.isNotEmpty) {
      final msg = model.publishPayload.isEmpty
          ? 'Hello from APIDash'
          : model.publishPayload;
      buf.writeln('    thread::spawn(move || {');
      buf.writeln('        thread::sleep(Duration::from_secs(1));');
      buf.writeln(
        '        client.publish("${model.publishTopic}", QoS::AtMostOnce, false, "$msg").unwrap();',
      );
      buf.writeln('    });');
      buf.writeln();
    }
    buf.writeln(
      '    // Iterate to poll the event loop for connection progress',
    );
    buf.writeln('    for (_, notification) in connection.iter().enumerate() {');
    buf.writeln('        println!("Notification = {:?}", notification);');
    buf.writeln('    }');
    buf.writeln('}');
    return buf.toString();
  }
}

class MQTTCurlCodeGen {
  String getCode(MQTTRequestModel model) {
    final broker = model.brokerUrl.isEmpty
        ? 'broker.mosquitto.org'
        : model.brokerUrl;
    final topic = model.publishTopic.isEmpty
        ? 'test/topic'
        : model.publishTopic;
    return 'mosquitto_pub -h $broker -p ${model.port} -t "$topic" -m "${model.publishPayload}"';
  }
}

class MQTTHarCodeGen {
  String getCode(MQTTRequestModel model) {
    return '{\n  "log": {\n    "version": "1.2",\n    "creator": {\n      "name": "APIDash",\n      "version": "1.0.0"\n    },\n    "entries": []\n  }\n}';
  }
}

class MQTTJuliaCodeGen {
  String getCode(MQTTRequestModel model) {
    final broker = model.brokerUrl.isEmpty
        ? 'broker.mosquitto.org'
        : model.brokerUrl;
    return 'using MQTT\n\nclient = MQTT.Client("$broker")\nMQTT.connect(client)\nMQTT.publish(client, "test/topic", "Hello from Julia")\nMQTT.disconnect(client)';
  }
}
