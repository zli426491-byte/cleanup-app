import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/secret_space_service.dart';
import '../../utils/app_theme.dart';

class SecretSpaceView extends StatefulWidget {
  const SecretSpaceView({super.key});

  @override
  State<SecretSpaceView> createState() => _SecretSpaceViewState();
}

class _SecretSpaceViewState extends State<SecretSpaceView> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _error;
  bool? _hasPIN;

  @override
  void initState() {
    super.initState();
    _checkPIN();
  }

  Future<void> _checkPIN() async {
    final service = context.read<SecretSpaceService>();
    final result = await service.hasPIN();
    if (mounted) setState(() => _hasPIN = result);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SecretSpaceService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('私密空間'),
        actions: [
          if (service.isUnlocked)
            IconButton(
              icon: const Icon(Icons.lock),
              onPressed: () => service.lock(),
            ),
        ],
      ),
      body: service.isUnlocked
          ? _buildUnlockedView(service)
          : _hasPIN == null
              ? const Center(child: CircularProgressIndicator())
              : _hasPIN!
                  ? _buildPinEntryView(service)
                  : _buildSetupView(service),
    );
  }

  Widget _buildPinEntryView(SecretSpaceService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 60, color: AppTheme.primary),
            const SizedBox(height: 24),
            const Text('輸入密碼',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '****',
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.danger)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final valid = await service.verifyPIN(_pinController.text);
                if (!mounted) return;
                if (valid) {
                  setState(() => _error = null);
                } else {
                  setState(() {
                    _error = '密碼錯誤';
                    _pinController.clear();
                  });
                }
              },
              child: const Text('解鎖'),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () async {
                final ok = await service.authenticateWithBiometrics();
                if (!ok && mounted) {
                  setState(() => _error = '生物辨識驗證失敗');
                }
              },
              icon: const Icon(Icons.fingerprint),
              label: const Text('使用生物辨識'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupView(SecretSpaceService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 60, color: AppTheme.primary),
            const SizedBox(height: 24),
            const Text('設定私密空間',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('建立 4 位數以上的密碼',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: '設定密碼'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: '確認密碼'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.danger)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_pinController.text.length < 4) {
                  setState(() => _error = '密碼至少需要 4 位數');
                } else if (_pinController.text != _confirmPinController.text) {
                  setState(() => _error = '密碼不一致');
                } else {
                  await service.setupPIN(_pinController.text);
                  if (!mounted) return;
                  setState(() {
                    _error = null;
                    _hasPIN = true;
                  });
                }
              },
              child: const Text('建立私密空間'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedView(SecretSpaceService service) {
    if (service.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('尚無項目',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('新增照片和影片來保護你的隱私'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showComingSoon(),
              icon: const Icon(Icons.add),
              label: const Text('新增項目'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
      itemCount: service.items.length + 1,
      itemBuilder: (ctx, i) {
        if (i == service.items.length) {
          return GestureDetector(
            onTap: () => _showComingSoon(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Icon(Icons.add, size: 32, color: Colors.grey),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: const Icon(Icons.lock, color: Colors.grey),
        );
      },
    );
  }

  void _showComingSoon() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('即將推出'),
        content: const Text('照片匯入功能即將推出，敬請期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}
