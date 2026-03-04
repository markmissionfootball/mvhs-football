/// Local-only model representing the user's E2E key pair.
/// Private key is stored in flutter_secure_storage.
/// Public key is stored in Firestore on the user document.
class UserKeyPair {
  final String publicKey;
  final String privateKey;

  const UserKeyPair({
    required this.publicKey,
    required this.privateKey,
  });
}
