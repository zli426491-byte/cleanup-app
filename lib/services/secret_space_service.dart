import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Inline models
// ---------------------------------------------------------------------------

class SecretItem {
  final String id;
  final String fileName;
  final DateTime addedAt;
  final int originalSize;

  const SecretItem({
    required this.id,
    required this.fileName,
    required this.addedAt,
    required this.originalSize,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'addedAt': addedAt.toIso8601String(),
        'originalSize': originalSize,
      };

  factory SecretItem.fromJson(Map<String, dynamic> json) => SecretItem(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        addedAt: DateTime.parse(json['addedAt'] as String),
        originalSize: json['originalSize'] as int,
      );
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class SecretSpaceService extends ChangeNotifier {
  static const _pinKey = 'secret_space_pin';
  static const _aesKey = 'secret_space_aes_key';
  static const _aesIvKey = 'secret_space_aes_iv';
  static const _itemsKey = 'secret_space_items';
  static const _vaultDir = 'secret_vault';

  // IMPORTANT: Using SharedPreferences as fallback storage because
  // flutter_secure_storage crashes on Windows (requires ATL dependency).
  // On iOS/Android production builds, switch back to FlutterSecureStorage
  // for proper Keychain/Keystore-backed security.
  //
  // NOTE: SharedPreferences stores data in PLAIN TEXT on disk.
  // This is convenience-level storage, NOT military-grade security.
  // The AES encryption of vault files still applies, but the encryption
  // key itself is stored in SharedPreferences (unprotected) on this platform.
  SharedPreferences? _prefs;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final Uuid _uuid = const Uuid();

  bool _isUnlocked = false;
  List<SecretItem> _items = [];

  bool get isUnlocked => _isUnlocked;
  List<SecretItem> get items => List.unmodifiable(_items);

  // -----------------------------------------------------------------------
  // PIN management
  // -----------------------------------------------------------------------

  /// Set up a new PIN for the secret space. Also generates the AES key if
  /// one doesn't already exist.
  Future<void> setupPIN(String pin) async {
    await _writeSecure(key: _pinKey, value: pin);
    await _ensureEncryptionKey();
  }

  /// Returns true if the provided PIN matches the stored one.
  Future<bool> verifyPIN(String pin) async {
    final stored = await _readSecure(key: _pinKey);
    if (stored == null) return false;

    final valid = stored == pin;
    if (valid) {
      _isUnlocked = true;
      await _loadItems();
      notifyListeners();
    }
    return valid;
  }

  /// Returns true if a PIN has been configured.
  Future<bool> hasPIN() async {
    final pin = await _readSecure(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  // -----------------------------------------------------------------------
  // Biometric authentication
  // -----------------------------------------------------------------------

  /// Attempt biometric authentication. Returns true on success and unlocks
  /// the vault.
  Future<bool> authenticateWithBiometrics() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics;
      if (!canAuth) return false;

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your Secret Space',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _isUnlocked = true;
        await _loadItems();
        notifyListeners();
      }

      return authenticated;
    } catch (e) {
      debugPrint('SecretSpaceService.authenticateWithBiometrics error: $e');
      return false;
    }
  }

  // -----------------------------------------------------------------------
  // Vault operations
  // -----------------------------------------------------------------------

  /// Encrypt and store a photo (or any binary data) in the vault.
  Future<SecretItem> addPhoto(Uint8List data, {String? fileName}) async {
    _assertUnlocked();

    final id = _uuid.v4();
    final name = fileName ?? 'photo_$id.enc';

    final encrypted = await _encryptData(data);

    final dir = await _getVaultDirectory();
    final file = File('${dir.path}/$id.enc');
    await file.writeAsBytes(encrypted);

    final item = SecretItem(
      id: id,
      fileName: name,
      addedAt: DateTime.now(),
      originalSize: data.length,
    );

    _items.add(item);
    await _saveItems();
    notifyListeners();

    return item;
  }

  /// Decrypt and return the raw bytes for a vault item.
  Future<Uint8List> decryptPhoto(SecretItem item) async {
    _assertUnlocked();

    final dir = await _getVaultDirectory();
    final file = File('${dir.path}/${item.id}.enc');

    if (!await file.exists()) {
      throw Exception('Encrypted file not found for item: ${item.id}');
    }

    final encryptedBytes = await file.readAsBytes();
    return _decryptData(encryptedBytes);
  }

  /// Delete an item from the vault.
  Future<void> deleteItem(SecretItem item) async {
    _assertUnlocked();

    final dir = await _getVaultDirectory();
    final file = File('${dir.path}/${item.id}.enc');
    if (await file.exists()) {
      await file.delete();
    }

    _items.removeWhere((i) => i.id == item.id);
    await _saveItems();
    notifyListeners();
  }

  /// Lock the vault. Clears the in-memory items list.
  void lock() {
    _isUnlocked = false;
    _items = [];
    notifyListeners();
  }

  // -----------------------------------------------------------------------
  // Encryption helpers
  // -----------------------------------------------------------------------

  Future<void> _ensureEncryptionKey() async {
    final existing = await _readSecure(key: _aesKey);
    if (existing != null) return;

    final key = encrypt.Key.fromSecureRandom(32); // AES-256
    final iv = encrypt.IV.fromSecureRandom(16);

    await _writeSecure(key: _aesKey, value: base64.encode(key.bytes));
    await _writeSecure(key: _aesIvKey, value: base64.encode(iv.bytes));
  }

  Future<encrypt.Encrypter> _getEncrypter() async {
    final keyB64 = await _readSecure(key: _aesKey);
    if (keyB64 == null) {
      throw Exception('Encryption key not found. Call setupPIN first.');
    }
    final key = encrypt.Key(Uint8List.fromList(base64.decode(keyB64)));
    return encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  }

  Future<encrypt.IV> _getIV() async {
    final ivB64 = await _readSecure(key: _aesIvKey);
    if (ivB64 == null) {
      throw Exception('IV not found. Call setupPIN first.');
    }
    return encrypt.IV(Uint8List.fromList(base64.decode(ivB64)));
  }

  Future<Uint8List> _encryptData(Uint8List data) async {
    final encrypter = await _getEncrypter();
    final iv = await _getIV();
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    return encrypted.bytes;
  }

  Future<Uint8List> _decryptData(Uint8List data) async {
    final encrypter = await _getEncrypter();
    final iv = await _getIV();
    final encrypted = encrypt.Encrypted(data);
    final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
    return Uint8List.fromList(decrypted);
  }

  // -----------------------------------------------------------------------
  // Persistence helpers
  // -----------------------------------------------------------------------

  Future<Directory> _getVaultDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vault = Directory('${appDir.path}/$_vaultDir');
    if (!await vault.exists()) {
      await vault.create(recursive: true);
    }
    return vault;
  }

  Future<void> _loadItems() async {
    final json = await _readSecure(key: _itemsKey);
    if (json == null || json.isEmpty) {
      _items = [];
      return;
    }

    try {
      final list = jsonDecode(json) as List<dynamic>;
      _items = list
          .map((e) => SecretItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SecretSpaceService._loadItems error: $e');
      _items = [];
    }
  }

  Future<void> _saveItems() async {
    final json = jsonEncode(_items.map((i) => i.toJson()).toList());
    await _writeSecure(key: _itemsKey, value: json);
  }

  // -----------------------------------------------------------------------
  // Guards
  // -----------------------------------------------------------------------

  void _assertUnlocked() {
    if (!_isUnlocked) {
      throw StateError('Secret space is locked. Authenticate first.');
    }
  }

  // -----------------------------------------------------------------------
  // SharedPreferences wrapper (replace with FlutterSecureStorage on mobile)
  // -----------------------------------------------------------------------

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> _writeSecure({required String key, required String value}) async {
    final prefs = await _getPrefs();
    await prefs.setString(key, value);
  }

  Future<String?> _readSecure({required String key}) async {
    final prefs = await _getPrefs();
    return prefs.getString(key);
  }
}
