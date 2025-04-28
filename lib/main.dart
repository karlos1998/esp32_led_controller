
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

final ble = FlutterReactiveBle();
final serviceUuid = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
final characteristicUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 LED Controller',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DiscoveredDevice? device;
  QualifiedCharacteristic? characteristic;
  bool isConnected = false;
  Color currentColor = Colors.white;
  bool ledOn = true;
  double brightness = 1.0; // New brightness control
  String connectionState = 'disconnected'; // Using string instead of enum
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  bool isScanning = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0; // Track reconnection attempts

  @override
  void initState() {
    super.initState();
    _loadState();
    // Check if BLE is available and permissions are granted before scanning
    _checkBleStatus();
  }

  void _checkBleStatus() {
    // Listen to BLE status changes
    ble.statusStream.listen((status) {
      if (status == BleStatus.ready) {
        // BLE is ready, check for known devices first
        _checkForKnownDevices();
      } else {
        // BLE is not ready (powered off, unauthorized, etc.)
        setState(() {
          connectionState = 'error';
          isConnected = false;
        });
      }
    });

    // Start checking after a short delay to allow UI to initialize
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkForKnownDevices();
    });
  }

  void _checkForKnownDevices() {
    // Simplified implementation - just start scanning directly
    print('Checking for known devices...');

    // Don't start scanning if we're already connected or scanning
    if (isConnected || isScanning) return;

    // Start scanning with a longer timeout
    _startScan();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _reconnectTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColor = prefs.getInt('color');
    if (savedColor != null) {
      currentColor = Color(savedColor);
    }
    ledOn = prefs.getBool('ledOn') ?? true;
    brightness = prefs.getDouble('brightness') ?? 1.0;
    setState(() {});
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('color', currentColor.value);
    await prefs.setBool('ledOn', ledOn);
    await prefs.setDouble('brightness', brightness);
  }

  void _startScan() {
    if (isConnected || isScanning) return;

    setState(() {
      connectionState = 'scanning';
      isScanning = true;
    });

    _scanSubscription?.cancel();

    _scanSubscription = ble.scanForDevices(withServices: []).listen(
          (d) {
        if (d.name == 'ESP32-LED-Controller') {
          _scanSubscription?.cancel();
          setState(() {
            device = d;
            isScanning = false;
            connectionState = 'connecting';
          });
          _connect();
        }
      },
      onError: (e) {
        print('Scan error: $e');
        setState(() {
          connectionState = 'error';
          isScanning = false;
        });
        _scheduleReconnect();
      },
    );

    Timer(const Duration(seconds: 10), () {
      if (isScanning) {
        _scanSubscription?.cancel();
        setState(() {
          isScanning = false;
          if (!isConnected) connectionState = 'disconnected';
        });
        _scheduleReconnect();
      }
    });
  }


  void _connect() async {
    if (device == null) return;

    _connectionSubscription?.cancel();

    setState(() {
      connectionState = 'connecting';
    });

    try {
      _connectionSubscription = ble.connectToDevice(
        id: device!.id,
        connectionTimeout: const Duration(seconds: 20),
      ).listen((state) async {
        if (state.connectionState == DeviceConnectionState.connected) {
          characteristic = QualifiedCharacteristic(
            serviceId: serviceUuid,
            characteristicId: characteristicUuid,
            deviceId: device!.id,
          );

          setState(() {
            isConnected = true;
            connectionState = 'connected';
          });

          if (ledOn) {
            await _sendColor(currentColor);
          } else {
            await _sendColor(Colors.black);
          }
        } else if (state.connectionState == DeviceConnectionState.disconnected) {
          setState(() {
            isConnected = false;
            connectionState = 'disconnected';
          });
          _scheduleReconnect();
        }
      });
    } catch (e) {
      print('Connect error: $e');
      setState(() {
        isConnected = false;
        connectionState = 'error';
      });
      _scheduleReconnect();
    }
  }


  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    // Use a shorter delay for the first few reconnect attempts, then increase the delay
    // to avoid excessive reconnection attempts

    // Calculate delay based on number of attempts (exponential backoff)
    int delay = _reconnectAttempts < 3 ? 2 : (_reconnectAttempts < 5 ? 5 : 10);

    print('Scheduling reconnect in $delay seconds (attempt ${_reconnectAttempts + 1})');

    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (!isConnected && !isScanning) {
        _reconnectAttempts++;

        // Reset the device if we've tried too many times
        if (_reconnectAttempts > 10) {
          print('Too many reconnect attempts, resetting device reference');
          device = null;
          _reconnectAttempts = 0;
        }

        _startScan();
      } else {
        // Reset counter if we're connected or already scanning
        _reconnectAttempts = 0;
      }
    });
  }

  Future<void> _sendColor(Color color) async {
    if (characteristic == null) return;

    // Apply brightness to the color
    final adjustedColor = Color.fromARGB(
      color.alpha,
      (color.red * brightness).round().clamp(0, 255),
      (color.green * brightness).round().clamp(0, 255),
      (color.blue * brightness).round().clamp(0, 255),
    );

    final hex = adjustedColor.red.toRadixString(16).padLeft(2, '0') +
        adjustedColor.green.toRadixString(16).padLeft(2, '0') +
        adjustedColor.blue.toRadixString(16).padLeft(2, '0');

    try {
      await ble.writeCharacteristicWithoutResponse(
        characteristic!,
        value: hex.codeUnits,
      );
    } catch (e) {
      // Handle error (could show a snackbar or other notification)
      setState(() {
        connectionState = 'error';
      });
    }
  }

  void _pickColor() async {
    Color tempColor = currentColor;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Wybierz kolor'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) => tempColor = color,
              enableAlpha: false,
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  currentColor = tempColor;
                  ledOn = true;
                  _sendColor(currentColor);
                  _saveState();
                });
              },
            )
          ],
        );
      },
    );
  }

  void _toggleLed() async {
    setState(() {
      ledOn = !ledOn;
    });
    if (ledOn) {
      await _sendColor(currentColor);
    } else {
      await _sendColor(Colors.black);
    }
    await _saveState();
  }

  // Helper method to get connection status icon and color
  Widget _getConnectionStatusWidget() {
    IconData icon;
    Color color;
    String statusText;

    switch (connectionState) {
      case 'connected':
        icon = Icons.bluetooth_connected;
        color = Colors.green;
        statusText = 'Połączono';
        break;
      case 'connecting':
        icon = Icons.bluetooth_searching;
        color = Colors.orange;
        statusText = 'Łączenie...';
        break;
      case 'scanning':
        icon = Icons.search;
        color = Colors.blue;
        statusText = isScanning ? 'Szukanie urządzenia...' : 'Sprawdzanie połączenia...';
        break;
      case 'error':
        icon = Icons.error_outline;
        color = Colors.red;
        statusText = 'Błąd połączenia';
        break;
      case 'disconnected':
      default:
        icon = Icons.bluetooth_disabled;
        color = Colors.grey;
        statusText = 'Rozłączono';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(statusText, style: TextStyle(color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 LED Controller'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _getConnectionStatusWidget(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Color preview
            Expanded(
              flex: 3,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: ledOn ? currentColor : Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Brightness control
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jasność',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.brightness_low),
                        Expanded(
                          child: Slider(
                            value: brightness,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            onChanged: isConnected
                                ? (value) {
                                    setState(() {
                                      brightness = value;
                                    });
                                    if (ledOn) {
                                      _sendColor(currentColor);
                                    }
                                    _saveState();
                                  }
                                : null,
                          ),
                        ),
                        const Icon(Icons.brightness_high),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Control buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? _pickColor : null,
                    icon: const Icon(Icons.color_lens),
                    label: const Text('Wybierz kolor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? _toggleLed : null,
                    icon: Icon(ledOn ? Icons.lightbulb : Icons.lightbulb_outline),
                    label: Text(ledOn ? 'Wyłącz LED' : 'Włącz LED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ledOn
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Reconnect button
            if (connectionState != 'connected' && connectionState != 'connecting' && connectionState != 'scanning')
              ElevatedButton.icon(
                onPressed: _startScan,
                icon: const Icon(Icons.refresh),
                label: const Text('Połącz ponownie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
