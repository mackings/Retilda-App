import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Notifications/api/notification_settings_service.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  final NotificationSettingsService _service = NotificationSettingsService();

  bool _loading = true;
  bool _orderUpdates = true;
  bool _promos = false;
  bool _email = true;

  Future<void> _load() async {
    final settings = await _service.loadSettings();
    setState(() {
      _orderUpdates = settings['orderUpdates'] ?? true;
      _promos = settings['promos'] ?? false;
      _email = settings['email'] ?? true;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _service.saveSettings(
      orderUpdates: _orderUpdates,
      promos: _promos,
      email: _email,
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            title: CustomText(
              'Notifications',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: deepBlue,
            ),
          ),
          body: _loading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: LinearProgressIndicator(color: accent),
                  ),
                )
              : ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _orderUpdates,
                            title: const Text('Order updates'),
                            subtitle:
                                const Text('Processing, ready, and delivered'),
                            activeColor: accent,
                            onChanged: (value) {
                              setState(() => _orderUpdates = value);
                              _save();
                            },
                          ),
                          SwitchListTile(
                            value: _email,
                            title: const Text('Email notifications'),
                            subtitle: const Text('Receive updates via email'),
                            activeColor: accent,
                            onChanged: (value) {
                              setState(() => _email = value);
                              _save();
                            },
                          ),
                          SwitchListTile(
                            value: _promos,
                            title: const Text('Promotions'),
                            subtitle:
                                const Text('Special offers and discounts'),
                            activeColor: accent,
                            onChanged: (value) {
                              setState(() => _promos = value);
                              _save();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomText(
                      'Push notifications are delivered via email in this release.',
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
        );
      },
    );
  }
}
