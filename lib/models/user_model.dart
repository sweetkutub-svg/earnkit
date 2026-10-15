class AppUser {
  final String uid;
  final String name;
  final String email;
  final int walletBalance;
  final int lockedBonus;
  final int unlockedBonus;
  final int adPoints;
  final String referralCode;
  final String referralCodeUsed;
  final String signInMethod;
  final bool emailVerified;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.walletBalance,
    required this.lockedBonus,
    required this.unlockedBonus,
    this.adPoints = 0,
    required this.referralCode,
    required this.referralCodeUsed,
    required this.signInMethod,
    required this.emailVerified,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      walletBalance: (map['walletBalance'] ?? 0) as int,
      lockedBonus: (map['lockedBonus'] ?? 0) as int,
      unlockedBonus: (map['unlockedBonus'] ?? 0) as int,
      adPoints: ((map['adPoints'] ?? 0) as num).toInt(),
      referralCode: map['referralCode'] ?? '',
      referralCodeUsed: map['referralCodeUsed'] ?? '',
      signInMethod: map['signInMethod'] ?? 'email',
      emailVerified: map['emailVerified'] ?? false,
    );
  }
}