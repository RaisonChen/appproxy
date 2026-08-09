import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SingleSwitchPage extends StatefulWidget {
  const SingleSwitchPage({super.key});

  @override
  State<SingleSwitchPage> createState() => _SingleSwitchPageState();
}

class _SingleSwitchPageState extends State<SingleSwitchPage> {
  static const platform = MethodChannel('cn.ys1231/appproxy/vpn');

  bool _running = false;
  bool _busy = false;
  bool _caInstalled = false;

  final String _proxyName = '农场取code';
  final String _proxyType = 'http';
  final String _proxyHost = '574530266.iok.la';
  final String _proxyPort = '8451';
  final String _proxyUser = '';
  final String _proxyPass = '';
  final List<String> _apps = ['com.tencent.mobileqq'];

  @override
  void initState() {
    super.initState();
    _loadCaFlag();
  }

  Future<void> _loadCaFlag() async {
    final sp = await SharedPreferences.getInstance();
    setState(() => _caInstalled = sp.getBool('ca_installed') ?? false);
  }

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (value) {
        await platform.invokeMethod('startVpn', {
          'proxyName': _proxyName,
          'proxyType': _proxyType,
          'proxyHost': _proxyHost,
          'proxyPort': _proxyPort,
          'proxyUser': _proxyUser,
          'proxyPass': _proxyPass,
          'appProxyPackageList': jsonEncode(_apps),
        });
        setState(() => _running = true);
      } else {
        await platform.invokeMethod('stopVpn');
        setState(() => _running = false);
      }
    } catch (e) {
      setState(() => _running = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _installCa() async {
    try {
      final ByteData data = await rootBundle.load('assets/ca.cer');
      final Uint8List bytes = data.buffer.asUint8List();
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw '无法获取外部存储目录';
      final file = File('${dir.path}/ca.cer');
      await file.writeAsBytes(bytes);

      final sp = await SharedPreferences.getInstance();
      await sp.setBool('ca_installed', true);
      setState(() => _caInstalled = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('证书已保存到:\n${file.path}\n请到系统设置→安全→安装证书 选择该文件'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存证书失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('农场取code'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '农场取code',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '代理开关',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '启用代理',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      Switch(
                        value: _running,
                        onChanged: _busy ? null : _toggle,
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _running ? '运行中' : '已停止',
                      style: TextStyle(
                        fontSize: 13,
                        color: _running ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                  const Divider(height: 28),
                  if (!_caInstalled)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _installCa,
                        icon: const Icon(Icons.lock_outline, size: 18),
                        label: const Text('安装 CA 证书 (首次需手动)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    '仅代理: ${_apps.join(', ')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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
}
