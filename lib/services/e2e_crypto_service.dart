import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/chat_room.dart';
import '../models/user_key_pair.dart';

/// Handles all E2E encryption operations:
/// - X25519 key pair generation and storage
/// - AES-256-GCM room key generation
/// - Room key encryption/decryption per participant
/// - Message encryption/decryption
class E2eCryptoService {
  static const _storage = FlutterSecureStorage();
  static const _privateKeyStorageKey = 'e2e_private_key';

  final _x25519 = X25519();
  final _aesGcm = AesGcm.with256bits();

  // Cache decrypted room keys in memory: roomId -> SecretKey
  final Map<String, SecretKey> _roomKeyCache = {};

  // ─── Key Pair Management ──────────────────────────────────

  /// Generate a new X25519 key pair. Called once on first login.
  Future<UserKeyPair> generateKeyPair() async {
    final keyPair = await _x25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateBytes = await keyPair.extractPrivateKeyBytes();

    final publicKeyBase64 = base64Encode(publicKey.bytes);
    final privateKeyBase64 = base64Encode(Uint8List.fromList(privateBytes));

    // Persist private key securely
    await _storage.write(
      key: _privateKeyStorageKey,
      value: privateKeyBase64,
    );

    return UserKeyPair(
      publicKey: publicKeyBase64,
      privateKey: privateKeyBase64,
    );
  }

  /// Load existing private key from secure storage.
  Future<String?> loadPrivateKey() async {
    return await _storage.read(key: _privateKeyStorageKey);
  }

  /// Check if user has a key pair stored locally.
  Future<bool> hasKeyPair() async {
    final key = await _storage.read(key: _privateKeyStorageKey);
    return key != null;
  }

  // ─── Room Key Management ──────────────────────────────────

  /// Generate a random 256-bit AES key for a new chat room.
  Future<SecretKey> generateRoomKey() async {
    return await _aesGcm.newSecretKey();
  }

  /// Encrypt the room AES key for a specific recipient using X25519 key agreement.
  Future<EncryptedRoomKey> encryptRoomKeyForRecipient({
    required SecretKey roomKey,
    required String recipientUid,
    required String recipientPublicKeyBase64,
  }) async {
    // Generate ephemeral X25519 key pair for this exchange
    final ephemeralKeyPair = await _x25519.newKeyPair();
    final ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();

    // Derive shared secret using X25519
    final recipientPublicBytes = base64Decode(recipientPublicKeyBase64);
    final recipientPubKey =
        SimplePublicKey(recipientPublicBytes, type: KeyPairType.x25519);

    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: recipientPubKey,
    );

    // Use the shared secret as AES key to encrypt the room key
    final roomKeyBytes = await roomKey.extractBytes();
    final nonce = _aesGcm.newNonce();

    final secretBox = await _aesGcm.encrypt(
      roomKeyBytes,
      secretKey: sharedSecret,
      nonce: nonce,
    );

    // Concatenate ciphertext + MAC for storage
    final encryptedBytes = Uint8List.fromList([
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return EncryptedRoomKey(
      recipientUid: recipientUid,
      encryptedKey: base64Encode(encryptedBytes),
      ephemeralPublicKey: base64Encode(ephemeralPublicKey.bytes),
      nonce: base64Encode(nonce),
    );
  }

  /// Decrypt the room AES key from a user's EncryptedRoomKey entry.
  Future<SecretKey> decryptRoomKey({
    required EncryptedRoomKey encryptedRoomKey,
    required String privateKeyBase64,
  }) async {
    final privateBytes = base64Decode(privateKeyBase64);
    final ephemeralPubBytes = base64Decode(encryptedRoomKey.ephemeralPublicKey);
    final encryptedBytes = base64Decode(encryptedRoomKey.encryptedKey);
    final nonceBytes = base64Decode(encryptedRoomKey.nonce);

    // Reconstruct the key pair for the recipient
    final ephemeralPubKey =
        SimplePublicKey(ephemeralPubBytes, type: KeyPairType.x25519);

    final recipientKeyPair = SimpleKeyPairData(
      privateBytes,
      publicKey: SimplePublicKey([], type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );

    // Derive the same shared secret
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: recipientKeyPair,
      remotePublicKey: ephemeralPubKey,
    );

    // Split encrypted data into ciphertext + MAC (last 16 bytes)
    final cipherText = encryptedBytes.sublist(0, encryptedBytes.length - 16);
    final macBytes = encryptedBytes.sublist(encryptedBytes.length - 16);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonceBytes,
      mac: Mac(macBytes),
    );

    final roomKeyBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: sharedSecret,
    );

    return SecretKey(roomKeyBytes);
  }

  /// Get (or cache) the decrypted room key for a given room.
  Future<SecretKey> getRoomKey({
    required String roomId,
    required List<EncryptedRoomKey> encryptedKeys,
    required String currentUid,
    required String privateKeyBase64,
  }) async {
    if (_roomKeyCache.containsKey(roomId)) {
      return _roomKeyCache[roomId]!;
    }

    final myKey = encryptedKeys.firstWhere(
      (k) => k.recipientUid == currentUid,
    );

    final roomKey = await decryptRoomKey(
      encryptedRoomKey: myKey,
      privateKeyBase64: privateKeyBase64,
    );

    _roomKeyCache[roomId] = roomKey;
    return roomKey;
  }

  // ─── Message Encryption ───────────────────────────────────

  /// Encrypt a plaintext message with the room's AES-256-GCM key.
  Future<({String ciphertext, String nonce})> encryptMessage({
    required String plaintext,
    required SecretKey roomKey,
  }) async {
    final plaintextBytes = utf8.encode(plaintext);
    final nonce = _aesGcm.newNonce();

    final secretBox = await _aesGcm.encrypt(
      plaintextBytes,
      secretKey: roomKey,
      nonce: nonce,
    );

    final encryptedBytes = Uint8List.fromList([
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return (
      ciphertext: base64Encode(encryptedBytes),
      nonce: base64Encode(nonce),
    );
  }

  /// Decrypt a ciphertext message using the room's AES key and nonce.
  Future<String> decryptMessage({
    required String ciphertextBase64,
    required String nonceBase64,
    required SecretKey roomKey,
  }) async {
    final encryptedBytes = base64Decode(ciphertextBase64);
    final nonceBytes = base64Decode(nonceBase64);

    final cipherText = encryptedBytes.sublist(0, encryptedBytes.length - 16);
    final macBytes = encryptedBytes.sublist(encryptedBytes.length - 16);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonceBytes,
      mac: Mac(macBytes),
    );

    final plaintextBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: roomKey,
    );

    return utf8.decode(plaintextBytes);
  }

  /// Clear all cached room keys (call on logout).
  void clearCache() {
    _roomKeyCache.clear();
  }
}
