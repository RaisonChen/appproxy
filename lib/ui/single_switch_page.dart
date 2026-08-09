import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 单开关页面：开/关代理，配置写死为 574530266.iok.la:8451 http
/// 仅代理 QQ (com.tencent.mobileqq)
/// 效果与原版一致，但只用一个开关控制
class SingleSwitchPage extends StatefulWidget {
  const SingleSwitchPage({Key? key}) : super(key: key);

  @override
  State<SingleSwitchPage> createState() => _SingleSwitchPageState();
}

class _SingleSwitchPageState extends State<SingleSwitchPage>
    with SingleTickerProviderStateMixin {
  bool _isOn = false;
  bool _caInstalled = false;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  static const platform = MethodChannel('cn.ys1231/appproxy/vpn');
  static const _prefsKey = 'ca_installed';

  // 写死的代理配置 —— 与原版字段完全一致
  static const String _proxyName = '农场取码';
  static const String _proxyType = 'http';
  static const String _proxyHost = '574530266.iok.la';
  static const int _proxyPort = 8451;
  static const List<String> _apps = ['com.tencent.mobileqq'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _loadPrefs();
    // 监听 native 端通知停止
    platform.setMethodCallHandler((call) async {
      if (call.method == 'stopVpn') {
        _setOff();
      }
      return null;
    });
  }

  Future<void> _loadPrefs() async {
    // 简单用 channel 调原版 Utils 存过的偏好（如不存在就忽略）
    try {
      final sp = await MethodChannel('cn.ys1231/appproxy')
          .invokeMethod('getPrefsBool', {'key': _prefsKey});
      if (sp is bool && sp) {
        setState(() => _caInstalled = true);
      }
    } catch (_) {}
  }

  void _setOff() {
    if (!mounted) return;
    setState(() => _isOn = false);
    _animCtrl.reverse();
  }

  Future<void> _toggle(bool v) async {
    if (v) {
      try {
        await platform.invokeMethod('startVpn', {
          'proxyName': _proxyName,
          'proxyType': _proxyType,
          'proxyHost': _proxyHost,
          'proxyPort': _proxyPort.toString(),
          'proxyUser': '',
          'proxyPass': '',
          'appProxyPackageList': jsonEncode(_apps),
        });
        setState(() => _isOn = true);
        _animCtrl.forward();
      } catch (e) {
        _setOff();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('启动失败: $e')),
          );
        }
      }
    } else {
      try {
        await platform.invokeMethod('stopVpn');
      } catch (_) {}
      _setOff();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('农场取码代理')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Switch(
                value: _isOn,
                onChanged: _toggle,
                activeColor: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isOn ? '代理已开启' : '代理已关闭',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$_proxyType://$_proxyHost:$_proxyPort',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            const Text(
              '仅代理: com.tencent.mobileqq',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (_caInstalled)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Chip(label: Text('CA 已安装')),
              ),
          ],
        ),
      ),
    );
  }
}
