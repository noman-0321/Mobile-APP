import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:health_monitoring_system/splash_screen.dart';
import 'package:health_monitoring_system/types.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Monitoring System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D73),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FFFE),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D73), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D73),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// In-App Notification Model
class InAppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;

  InAppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  InAppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return InAppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

enum NotificationType { info, warning, critical, success }

// In-App Notification Service
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<InAppNotification> _notifications = [];
  final List<InAppNotification> _activeNotifications = [];

  List<InAppNotification> get notifications =>
      List.unmodifiable(_notifications);
  List<InAppNotification> get activeNotifications =>
      List.unmodifiable(_activeNotifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
  }) {
    final notification = InAppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );

    _notifications.insert(0, notification);
    _activeNotifications.insert(0, notification);

    // Auto-remove active notification after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _activeNotifications.removeWhere((n) => n.id == notification.id);
      notifyListeners();
    });

    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void removeActiveNotification(String id) {
    _activeNotifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _activeNotifications.clear();
    notifyListeners();
  }
}

// In-App Notification Widget
class InAppNotificationWidget extends StatelessWidget {
  final InAppNotification notification;
  final VoidCallback? onDismiss;

  const InAppNotificationWidget({
    super.key,
    required this.notification,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            NotificationService().markAsRead(notification.id);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(_getIcon(), color: _getIconColor(), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _getTextColor(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getTextColor().withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: _getTextColor().withValues(alpha: 0.6),
                    ),
                    onPressed: onDismiss,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (notification.type) {
      case NotificationType.success:
        return const Color(0xFFF0FDF4);
      case NotificationType.warning:
        return const Color(0xFFFFFBEB);
      case NotificationType.critical:
        return const Color(0xFFFEF2F2);
      case NotificationType.info:
        return const Color(0xFFF0F9FF);
    }
  }

  Color _getBorderColor() {
    switch (notification.type) {
      case NotificationType.success:
        return const Color(0xFF16A34A);
      case NotificationType.warning:
        return const Color(0xFFD97706);
      case NotificationType.critical:
        return const Color(0xFFDC2626);
      case NotificationType.info:
        return const Color(0xFF0284C7);
    }
  }

  Color _getIconColor() {
    return _getBorderColor();
  }

  Color _getTextColor() {
    switch (notification.type) {
      case NotificationType.success:
        return const Color(0xFF166534);
      case NotificationType.warning:
        return const Color(0xFF92400E);
      case NotificationType.critical:
        return const Color(0xFF991B1B);
      case NotificationType.info:
        return const Color(0xFF1E40AF);
    }
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.warning:
        return Icons.warning_amber;
      case NotificationType.critical:
        return Icons.error;
      case NotificationType.info:
        return Icons.info;
    }
  }
}

// Notification Overlay
class NotificationOverlay extends StatefulWidget {
  final Widget child;

  const NotificationOverlay({super.key, required this.child});

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: ListenableBuilder(
              listenable: NotificationService(),
              builder: (context, child) {
                final activeNotifications =
                    NotificationService().activeNotifications;
                return Column(
                  children:
                      activeNotifications.map((notification) {
                        return InAppNotificationWidget(
                          notification: notification,
                          onDismiss: () {
                            NotificationService().removeActiveNotification(
                              notification.id,
                            );
                          },
                        );
                      }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String name;
  const HomeScreen({super.key, required this.name});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bpController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cholController = TextEditingController();
  Val _selectedSex = Gender.Male;
  Val _selectedChestPain = ChestPain.NoPain;
  Val _selectedRestecg = RestingECG.Normal;
  Val _selectedExng = ExerciseInducedAngina.No;
  Val _fbs = FastingBloodSugar.Normal;

  @override
  void dispose() {
    _ageController.dispose();
    _bpController.dispose();
    _cholController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationOverlay(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Tell us about\nyourself',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'We need this information to identify your\ncondition',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF757575),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 48),

                  _buildFormField(
                    label: 'Gender',
                    value: _selectedSex,
                    options: Gender.values,
                    onChanged:
                        (value) => setState(() {
                          _selectedSex = Gender.values.firstWhere(
                            (gndr) => gndr.name == value,
                          );
                        }),
                  ),
                  const SizedBox(height: 24),
                  _buildTextFormField(
                    label: 'Age',
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  _buildTextFormField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  _buildTextFormField(
                    label: 'Blood Pressure (mmHg)',
                    controller: _bpController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  _buildTextFormField(
                    label: 'Cholesterol (mg/dL)',
                    controller: _cholController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  _buildFormField(
                    label: 'Fasting Blood Sugar',
                    value: _fbs,
                    options: FastingBloodSugar.values,
                    onChanged:
                        (value) => setState(() {
                          _fbs = FastingBloodSugar.values.firstWhere(
                            (fbs) => fbs.name == value,
                          );
                        }),
                  ),
                  const SizedBox(height: 24),
                  _buildFormField(
                    label: 'Resting ECG',
                    value: _selectedRestecg,
                    options: RestingECG.values,
                    onChanged:
                        (value) => setState(() {
                          _selectedRestecg = RestingECG.values.firstWhere(
                            (recg) => recg.name == value,
                          );
                        }),
                  ),
                  const SizedBox(height: 24),
                  _buildFormField(
                    label: 'Exercise-Induced Angina',
                    value: _selectedExng,
                    options: ExerciseInducedAngina.values,
                    onChanged:
                        (value) => setState(() {
                          _selectedExng = ExerciseInducedAngina.values
                              .firstWhere((eid) => eid.name == value);
                        }),
                  ),
                  const SizedBox(height: 24),
                  _buildFormField(
                    label: 'Chest Pain',
                    value: _selectedChestPain,
                    options: ChestPain.values,
                    onChanged:
                        (value) => setState(() {
                          _selectedChestPain = ChestPain.values.firstWhere(
                            (cp) => cp.name == value,
                          );
                        }),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // Input validation
                          if (_ageController.text.isEmpty ||
                              _bpController.text.isEmpty ||
                              _cholController.text.isEmpty) {
                            NotificationService().addNotification(
                              title: 'Missing Information',
                              message: 'Please fill in all required fields',
                              type: NotificationType.warning,
                            );
                            return;
                          }

                          final age = int.tryParse(_ageController.text);
                          final bp = int.tryParse(_bpController.text);
                          final chol = int.tryParse(_cholController.text);

                          if (age == null || age < 1 || age > 120) {
                            NotificationService().addNotification(
                              title: 'Invalid Age',
                              message:
                                  'Please enter a valid age between 1 and 120',
                              type: NotificationType.warning,
                            );
                            return;
                          }

                          if (bp == null || bp < 50 || bp > 300) {
                            NotificationService().addNotification(
                              title: 'Invalid Blood Pressure',
                              message:
                                  'Please enter a valid blood pressure between 50 and 300',
                              type: NotificationType.warning,
                            );
                            return;
                          }

                          if (chol == null || chol < 100 || chol > 500) {
                            NotificationService().addNotification(
                              title: 'Invalid Cholesterol',
                              message:
                                  'Please enter a valid cholesterol level between 100 and 500',
                              type: NotificationType.warning,
                            );
                            return;
                          }

                          // NotificationService().addNotification(
                          //   title: 'Profile Created',
                          //   message: 'Successfully created your health profile',
                          //   type: NotificationType.success,
                          // );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MonitoringPage(
                                    patientData: {
                                      'age': age,
                                      'sex': _selectedSex.value,
                                      'chest_pain': _selectedChestPain.value,
                                      'fbs': _fbs.value,
                                      'restecg': _selectedRestecg.value,
                                      'exng': _selectedExng.value,
                                      'email': _emailController.text.trim(),
                                      'name': widget.name,
                                    },
                                  ),
                            ),
                          );
                        },
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required Val value,
    required List<Val> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 0.1,
            blurRadius: 6,
          ),
        ],
        color: Colors.white,
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 10),
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
            ),
          ),
          DropdownButton<String>(
            value: value.name,
            hint: Text(
              'Select $label',
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            icon: const CircleAvatar(
              radius: 9,
              backgroundColor: Color(0xFF6366F1),
              child: Icon(Icons.arrow_drop_down, color: Colors.white, size: 14),
            ),
            items:
                options.map((Val option) {
                  return DropdownMenuItem<String>(
                    value: option.name,
                    child: Text(
                      option.name,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  );
                }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 0.1,
            blurRadius: 6,
          ),
        ],
        color: Colors.white,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: 'Enter $label',
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
          border: const OutlineInputBorder(borderSide: BorderSide.none),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF6366F1)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class MonitoringPage extends StatefulWidget {
  final Map<String, dynamic> patientData;

  const MonitoringPage({super.key, required this.patientData});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  WebSocketChannel? _webSocketChannel;
  Map<String, dynamic>? _currentData;
  String? _predictionStatus;
  double? _predictionScore;
  bool _isLoading = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeMonitoring();
  }

  void _connectWebSocket() {
    try {
      _webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://health-monitoring-model.onrender.com/ws/predict'),
      );

      setState(() {
        _isConnected = true;
      });

      // NotificationService().addNotification(
      //   title: 'Connection Established',
      //   message: 'Successfully connected to health monitoring server',
      //   type: NotificationType.success,
      // );

      _webSocketChannel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data.containsKey('error')) {
              setState(() {
                _predictionStatus = 'Error: ${data['error']}';
                _predictionScore = null;
              });

              // NotificationService().addNotification(
              //   title: 'Prediction Error',
              //   message: 'Error processing health data: ${data['error']}',
              //   type: NotificationType.warning,
              // );
            } else {
              final prediction = (data['prediction'] as num).toDouble();
              setState(() {
                _predictionScore = prediction;
                _predictionStatus = _getRiskStatus(prediction);
              });

              if (prediction >= 0.8) {
                NotificationService().addNotification(
                  title: 'Critical Health Alert',
                  message:
                      'Severe health risk detected! Seek immediate medical attention.',
                  type: NotificationType.critical,
                );
              } else if (prediction >= 0.6) {
                NotificationService().addNotification(
                  title: 'High Risk Warning',
                  message:
                      'High health risk detected. Consider consulting a doctor.',
                  type: NotificationType.warning,
                );
              }
            }
          } catch (e) {
            setState(() {
              _predictionStatus = 'Data Processing Error';
              _predictionScore = null;
            });
          }
        },
        onError: (error) {
          setState(() {
            _predictionStatus = 'Connection Failed: Check Server';
            _predictionScore = null;
            _isConnected = false;
          });

          // Attempt to reconnect after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) _connectWebSocket();
          });
        },
        onDone: () {
          setState(() {
            _predictionStatus = 'Connection Lost';
            _predictionScore = null;
            _isConnected = false;
          });

          // NotificationService().addNotification(
          //   title: 'Connection Closed',
          //   message: 'Server connection closed. Attempting to reconnect...',
          //   type: NotificationType.info,
          // );

          // Attempt to reconnect after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) _connectWebSocket();
          });
        },
      );
    } catch (e) {
      setState(() {
        _predictionStatus = 'Connection Error: $e';
        _predictionScore = null;
        _isConnected = false;
      });

      // Attempt to reconnect after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) _connectWebSocket();
      });
    }
  }

  void _initializeMonitoring() {
    setState(() {
      _isLoading = true;
    });

    // NotificationService().addNotification(
    //   title: 'Monitoring Started',
    //   message: 'Health monitoring system is initializing...',
    //   type: NotificationType.info,
    // );

    _connectWebSocket();

    _database
        .child('ESP32_APP')
        .onValue
        .listen(
          (event) {
            if (event.snapshot.value != null && mounted) {
              try {
                final data = Map<String, dynamic>.from(
                  event.snapshot.value as Map,
                );
                setState(() {
                  _currentData = {
                    'heartRate': (data['HEART_RATE'] ?? 0.0).toDouble(),
                    'temperature': (data['TEMPERATURE_C'] ?? 0.0).toDouble(),
                    'spo2': (data['spo2'] ?? 0.0).toDouble(),
                    'bp': (data['BP'] ?? 120.0).toDouble(),
                    'chol': (data['CHOL'] ?? 160.0).toDouble(),
                    'fbs': (data['FBS'] ?? 85.0).toDouble(),
                    'restecg': (data['RESTECG'] ?? 0.0).toDouble(),
                    'exng': (data['EXNG'] ?? 0.0).toDouble(),
                    'timestamp': DateTime.now(),
                  };
                  _isLoading = false;
                });
                _sendToWebSocket();
              } catch (e) {
                setState(() {
                  _currentData = null;
                  _isLoading = false;
                  _predictionStatus = 'Data Parse Error';
                  _predictionScore = null;
                });

                NotificationService().addNotification(
                  title: 'Data Error',
                  message: 'Failed to parse sensor data from Firebase',
                  type: NotificationType.warning,
                );
              }
            } else {
              setState(() {
                _currentData = null;
                _isLoading = false;
                _predictionStatus = 'No Data Available';
                _predictionScore = null;
              });
            }
          },
          onError: (error) {
            setState(() {
              _currentData = null;
              _isLoading = false;
              _predictionStatus = 'Database Connection Failed';
              _predictionScore = null;
            });

            NotificationService().addNotification(
              title: 'Database Error',
              message: 'Failed to connect to Firebase database',
              type: NotificationType.warning,
            );
          },
        );
  }

  void _sendToWebSocket() {
    if (_currentData != null && _webSocketChannel != null && _isConnected) {
      final dataToSend = {
        'age': widget.patientData['age'],
        'sex': widget.patientData['sex'],
        'chest_pain': widget.patientData['chest_pain'],
        'bp': _currentData!['bp'],
        'chol': _currentData!['chol'],
        'fbs': _currentData!['fbs'],
        'restecg': _currentData!['restecg'],
        'exng': _currentData!['exng'],
        'temperature': _currentData!['temperature'],
        'email': widget.patientData['email'],
        'o2': _currentData!['spo2'],
        'hr': _currentData!['heartRate'],
      };

      try {
        _webSocketChannel!.sink.add(jsonEncode(dataToSend));
      } catch (e) {
        setState(() {
          _predictionStatus = 'Send Error: $e';
          _predictionScore = null;
          _isConnected = false;
        });

        NotificationService().addNotification(
          title: 'Transmission Failed',
          message: 'Failed to send data to prediction server',
          type: NotificationType.warning,
        );

        // Attempt to reconnect after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) _connectWebSocket();
        });
      }
    }
  }

  String _getRiskStatus(double prediction) {
    if (prediction < 0.2) {
      return 'Low Risk - Your health parameters appear normal';
    } else if (prediction < 0.4) {
      return 'Mild Risk - Monitor your health regularly';
    } else if (prediction < 0.6) {
      return 'Moderate Risk - Consider medical consultation';
    } else if (prediction < 0.8) {
      return 'High Risk - Recommend immediate medical attention';
    } else {
      return 'Severe Risk - Seek emergency medical care';
    }
  }

  Color _getRiskColor(double? prediction) {
    if (prediction == null) return const Color(0xFFFEF2F2);
    if (prediction < 0.2) return const Color(0xFFF0FDF4);
    if (prediction < 0.4) return const Color(0xFFE0F7FA);
    if (prediction < 0.6) return const Color(0xFFFFFBEB);
    if (prediction < 0.8) return const Color(0xFFFFF3E0);
    return const Color(0xFFFEF2F2);
  }

  Color _getRiskIconColor(double? prediction) {
    if (prediction == null) return const Color(0xFFDC2626);
    if (prediction < 0.2) return const Color(0xFF16A34A);
    if (prediction < 0.4) return const Color(0xFF0288D1);
    if (prediction < 0.6) return const Color(0xFFD97706);
    if (prediction < 0.8) return const Color(0xFFF4511E);
    return const Color(0xFFDC2626);
  }

  IconData _getRiskIcon(double? prediction) {
    if (prediction == null) return Icons.error;
    if (prediction < 0.2) return Icons.check_circle;
    if (prediction < 0.4) return Icons.info;
    if (prediction < 0.6) return Icons.warning_amber;
    if (prediction < 0.8) return Icons.warning;
    return Icons.error;
  }

  @override
  void dispose() {
    _webSocketChannel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationOverlay(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FFFE),
        appBar: AppBar(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          title: const Text(
            'Health Monitor',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          elevation: 0,
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    _showNotificationHistory(context);
                  },
                ),
                ListenableBuilder(
                  listenable: NotificationService(),
                  builder: (context, child) {
                    final unreadCount = NotificationService().unreadCount;
                    if (unreadCount == 0) return const SizedBox.shrink();
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // const SizedBox(height: 20),
                  // Container(
                  //   width: double.infinity,
                  //   padding: const EdgeInsets.all(32),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(16),
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: Colors.grey.withValues(alpha: 0.1),
                  //         spreadRadius: 1,
                  //         blurRadius: 8,
                  //       ),
                  //     ],
                  //   ),
                  //   child: Column(
                  //     children: [
                  //       const Text(
                  //         'Hello',
                  //         style: TextStyle(
                  //           fontSize: 48,
                  //           fontWeight: FontWeight.w700,
                  //           color: Color(0xFF2E7D73),
                  //         ),
                  //       ),
                  //       const SizedBox(height: 8),
                  //       Text(
                  //         'Welcome to your health monitoring dashboard',
                  //         style: TextStyle(
                  //           fontSize: 16,
                  //           color: Colors.grey.shade600,
                  //         ),
                  //         textAlign: TextAlign.center,
                  //       ),
                  //       const SizedBox(height: 16),
                  //       Row(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           Container(
                  //             width: 8,
                  //             height: 8,
                  //             decoration: BoxDecoration(
                  //               color: _isConnected ? Colors.green : Colors.red,
                  //               shape: BoxShape.circle,
                  //             ),
                  //           ),
                  //           const SizedBox(width: 8),
                  //           Text(
                  //             _isConnected ? 'Connected' : 'Disconnected',
                  //             style: TextStyle(
                  //               fontSize: 12,
                  //               color: _isConnected ? Colors.green : Colors.red,
                  //               fontWeight: FontWeight.w500,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getRiskColor(_predictionScore),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getRiskIconColor(_predictionScore),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getRiskIcon(_predictionScore),
                              color: _getRiskIconColor(_predictionScore),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _predictionStatus ?? 'Awaiting Prediction',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _getRiskIconColor(_predictionScore),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_predictionScore != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Risk Score: ${(_predictionScore! * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _getRiskIconColor(_predictionScore),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D73),
                      ),
                    )
                  else if (_currentData != null)
                    _buildDataCards()
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.sensors_off,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Data Available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please ensure your device is connected',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D73),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        NotificationService().clearAll();
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: NotificationService(),
                  builder: (context, child) {
                    final notifications = NotificationService().notifications;
                    if (notifications.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InAppNotificationWidget(
                            notification: notification,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataCards() {
    final vitals = [
      {
        'title': 'Heart Rate',
        'value':
            '${(_currentData!['heartRate'] ?? 0.0).toStringAsFixed(0)} bpm',
        'icon': Icons.favorite,
        'color': Colors.red,
      },
      {
        'title': 'Temperature',
        'value':
            '${(_currentData!['temperature'] ?? 0.0).toStringAsFixed(1)} °C',
        'icon': Icons.thermostat,
        'color': Colors.blue,
      },
      {
        'title': 'SpO2',
        'value': '${(_currentData!['spo2'] ?? 0.0).toStringAsFixed(0)}%',
        'icon': Icons.air,
        'color': Colors.green,
      },
      // {
      //   'title': 'Blood Pressure',
      //   'value': '${(_currentData!['bp'] ?? 0.0).toStringAsFixed(0)} mmHg',
      //   'icon': Icons.monitor_heart,
      //   'color': Colors.purple,
      // },
      // {
      //   'title': 'Cholesterol',
      //   'value': '${(_currentData!['chol'] ?? 0.0).toStringAsFixed(0)} mg/dL',
      //   'icon': Icons.water_drop,
      //   'color': Colors.orange,
      // },
      // {
      //   'title': 'Blood Sugar',
      //   'value': '${(_currentData!['fbs'] ?? 0.0).toStringAsFixed(0)} mg/dL',
      //   'icon': Icons.local_hospital,
      //   'color': Colors.teal,
      // },
    ];

    return Column(
      children: [
        Text(
          "${widget.patientData['name'] ?? "Guest"}'s Health Data",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Last updated: ${_currentData!['timestamp'].toString().substring(11, 19)}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16, // Horizontal spacing
          runSpacing: 16, // Vertical spacing
          children: List.generate(vitals.length, (index) {
            final vital = vitals[index];
            return Container(
              constraints: BoxConstraints(minWidth: 130),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (vital['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      vital['icon'] as IconData,
                      color: vital['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    vital['title'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vital['value'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
