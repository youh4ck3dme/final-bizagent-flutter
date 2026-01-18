class UserSettingsModel {
  final String companyName;
  final String companyAddress;
  final String companyIco;
  final String companyDic;
  final String companyIcDph; // Added
  final String bankAccount; // IBAN
  final String swift; // Added
  final String registerInfo; // Added e.g. "Zapísaná v OR OS..."
  final bool showQrCode;
  final bool isVatPayer;
  final String? iban;
  final bool showQrOnInvoice;

  UserSettingsModel({
    required this.companyName,
    required this.companyAddress,
    required this.companyIco,
    required this.companyDic,
    required this.companyIcDph,
    required this.bankAccount,
    required this.swift,
    required this.registerInfo,
    this.showQrCode = true,
    this.isVatPayer = false,
    this.iban,
    this.showQrOnInvoice = false,
  });

  factory UserSettingsModel.fromMap(Map<String, dynamic> map) {
    return UserSettingsModel(
      companyName: map['companyName'] ?? '',
      companyAddress: map['companyAddress'] ?? '',
      companyIco: map['companyIco'] ?? '',
      companyDic: map['companyDic'] ?? '',
      companyIcDph: map['companyIcDph'] ?? '',
      bankAccount: map['bankAccount'] ?? '',
      swift: map['swift'] ?? '',
      registerInfo: map['registerInfo'] ?? '',
      showQrCode: map['showQrCode'] ?? true,
      isVatPayer: map['isVatPayer'] ?? false,
      iban: map['iban'],
      showQrOnInvoice: map['showQrOnInvoice'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyIco': companyIco,
      'companyDic': companyDic,
      'companyIcDph': companyIcDph,
      'bankAccount': bankAccount,
      'swift': swift,
      'registerInfo': registerInfo,
      'showQrCode': showQrCode,
      'isVatPayer': isVatPayer,
      'iban': iban,
      'showQrOnInvoice': showQrOnInvoice,
    };
  }

  UserSettingsModel copyWith({
    String? companyName,
    String? companyAddress,
    String? companyIco,
    String? companyDic,
    String? companyIcDph,
    String? bankAccount,
    String? swift,
    String? registerInfo,
    bool? showQrCode,
    bool? isVatPayer,
    String? iban,
    bool? showQrOnInvoice,
  }) {
    return UserSettingsModel(
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyIco: companyIco ?? this.companyIco,
      companyDic: companyDic ?? this.companyDic,
      companyIcDph: companyIcDph ?? this.companyIcDph,
      bankAccount: bankAccount ?? this.bankAccount,
      swift: swift ?? this.swift,
      registerInfo: registerInfo ?? this.registerInfo,
      showQrCode: showQrCode ?? this.showQrCode,
      isVatPayer: isVatPayer ?? this.isVatPayer,
      iban: iban ?? this.iban,
      showQrOnInvoice: showQrOnInvoice ?? this.showQrOnInvoice,
    );
  }

  static UserSettingsModel empty() => UserSettingsModel(
        companyName: '',
        companyAddress: '',
        companyIco: '',
        companyDic: '',
        companyIcDph: '',
        bankAccount: '',
        swift: '',
        registerInfo: '',
        showQrCode: true,
        isVatPayer: false,
        iban: null,
        showQrOnInvoice: false,
      );
}
