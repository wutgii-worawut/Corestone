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
}
