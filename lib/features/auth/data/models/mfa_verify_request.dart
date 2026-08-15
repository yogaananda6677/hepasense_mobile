class MfaVerifyRequest {
  const MfaVerifyRequest({required this.challenge, required this.otpCode});

  final String challenge;
  final String otpCode;

  Map<String, dynamic> toJson() => {
    'challenge': challenge,
    'otp_code': otpCode,
  };
}
