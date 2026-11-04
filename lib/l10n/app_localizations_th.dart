// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get home => 'หน้าหลัก';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get theme => 'ธีม';

  @override
  String get themeSystem => 'ตามระบบ';

  @override
  String get themeLight => 'สว่าง';

  @override
  String get themeDark => 'มืด';

  @override
  String get language => 'ภาษา';

  @override
  String get languageSystem => 'ตามระบบ';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageThai => 'ไทย';

  @override
  String get signIn => 'เข้าสู่ระบบ';

  @override
  String get signOut => 'ออกจากระบบ';

  @override
  String get loginTitle => 'ยินดีต้อนรับกลับมา';

  @override
  String get loginSubtitle => 'เข้าสู่ระบบด้วยอีเมลและรหัสผ่านของคุณ';

  @override
  String get email => 'อีเมล';

  @override
  String get password => 'รหัสผ่าน';

  @override
  String get showPassword => 'แสดงรหัสผ่าน';

  @override
  String get hidePassword => 'ซ่อนรหัสผ่าน';

  @override
  String get fieldRequired => 'กรุณากรอกข้อมูลช่องนี้';

  @override
  String get invalidEmail => 'กรุณากรอกอีเมลให้ถูกต้อง';

  @override
  String get loginWrongCredentials => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';

  @override
  String get errorOffline =>
      'ไม่มีการเชื่อมต่ออินเทอร์เน็ต กรุณาตรวจสอบแล้วลองอีกครั้ง';

  @override
  String get errorServer => 'ระบบขัดข้อง กรุณาลองใหม่ภายหลัง';

  @override
  String get errorGeneric => 'เกิดข้อผิดพลาด กรุณาลองอีกครั้ง';

  @override
  String get signOutConfirmTitle => 'ต้องการออกจากระบบหรือไม่';

  @override
  String get signOutConfirmBody => 'คุณจะต้องเข้าสู่ระบบอีกครั้งเพื่อใช้งานแอป';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get deleteAccount => 'ลบบัญชี';

  @override
  String get deleteAccountTitle => 'ต้องการลบบัญชีของคุณหรือไม่';

  @override
  String get deleteAccountBody =>
      'บัญชีและข้อมูลทั้งหมดของคุณจะถูกลบอย่างถาวร แล้วคุณจะออกจากระบบ การดำเนินการนี้ย้อนกลับไม่ได้';

  @override
  String get deleteAccountConfirm => 'ลบบัญชีของฉัน';

  @override
  String get lockTitle => 'กรอก PIN ของคุณ';

  @override
  String wrongPin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN ไม่ถูกต้อง เหลืออีก $count ครั้งก่อนออกจากระบบ',
    );
    return '$_temp0';
  }

  @override
  String get lockedOut => 'กำลังออกจากระบบ…';

  @override
  String get forgotPin => 'ลืม PIN? ออกจากระบบ';

  @override
  String get pinCreateTitle => 'ตั้ง PIN 6 หลัก';

  @override
  String get pinCreateSubtitle => 'คุณจะใช้ PIN นี้เพื่อเปิดแอป';

  @override
  String get pinConfirmTitle => 'กรอก PIN อีกครั้ง';

  @override
  String get pinMismatch => 'PIN ไม่ตรงกัน กรุณาลองอีกครั้ง';

  @override
  String get pinCurrentTitle => 'กรอก PIN ปัจจุบัน';

  @override
  String get changePin => 'เปลี่ยน PIN';

  @override
  String get pinChanged => 'เปลี่ยน PIN แล้ว';

  @override
  String get pinDelete => 'ลบ';

  @override
  String pinDigitsEntered(int entered, int total) {
    return 'กรอกแล้ว $entered จาก $total หลัก';
  }

  @override
  String get biometricUnlock => 'ปลดล็อกด้วยไบโอเมตริก';

  @override
  String get biometricReason => 'ยืนยันตัวตนเพื่อเปิดแอป';

  @override
  String get biometricUsePin => 'ใช้ PIN';

  @override
  String get retry => 'ลองอีกครั้ง';

  @override
  String get maintenanceTitle => 'ปิดปรับปรุงระบบชั่วคราว';

  @override
  String get maintenanceBody =>
      'ขณะนี้เรากำลังปรับปรุงบริการ โปรดลองอีกครั้งในอีกสักครู่';

  @override
  String get secureConnectionTitle => 'เชื่อมต่ออย่างปลอดภัยไม่ได้';

  @override
  String get secureConnectionBody =>
      'เรายืนยันเซิร์ฟเวอร์ไม่ได้ จึงหยุดการเชื่อมต่อเพื่อปกป้องข้อมูลของคุณ หากใช้ Wi-Fi สาธารณะ ให้เปลี่ยนเครือข่ายแล้วลองอีกครั้ง';

  @override
  String get offlineBanner => 'ไม่มีการเชื่อมต่อเครือข่าย';
}
