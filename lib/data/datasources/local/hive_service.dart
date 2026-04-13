import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user_model.dart';
import '../../models/faculty_model.dart';
import '../../models/academic_model.dart';

class HiveService {
  static const String usersBox = 'users';
  static const String facultyBox = 'faculty';
  static const String consultationBox = 'consultations';
  static const String activityBox = 'activities';
  static const String settingsBox = 'settings';
  static const String subjectBox = 'subjects';
  static const String marksBox = 'marks';
  static const String timetableBox    = 'timetable';
  static const String communityBox    = 'community';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(FacultyModelAdapter());
    Hive.registerAdapter(SubjectModelAdapter());
    Hive.registerAdapter(StudentMarkModelAdapter());
    Hive.registerAdapter(TimetableModelAdapter());
    await Hive.openBox<UserModel>(usersBox);
    await Hive.openBox<FacultyModel>(facultyBox);
    await Hive.openBox<SubjectModel>(subjectBox);
    await Hive.openBox<StudentMarkModel>(marksBox);
    await Hive.openBox<TimetableModel>(timetableBox);
    await Hive.openBox(consultationBox);
    await Hive.openBox(activityBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox(communityBox);
  }

  /// Lightweight init — only opens the settings box needed for local prefs.
  /// Used when Firebase handles all data storage.
  static Future<void> initSettingsOnly() async {
    await Hive.initFlutter();
    await Hive.openBox(settingsBox);
  }

  static Box<UserModel> get users => Hive.box<UserModel>(usersBox);
  static Box<FacultyModel> get faculty => Hive.box<FacultyModel>(facultyBox);
  static Box<SubjectModel> get subjects => Hive.box<SubjectModel>(subjectBox);
  static Box<StudentMarkModel> get marks => Hive.box<StudentMarkModel>(marksBox);
  static Box<TimetableModel> get timetable => Hive.box<TimetableModel>(timetableBox);
  static Box get consultations => Hive.box(consultationBox);
  static Box get activities    => Hive.box(activityBox);
  static Box get settings      => Hive.box(settingsBox);
  static Box get community     => Hive.box(communityBox);

  static Future<void> clearAll() async {
    await users.clear();
    await faculty.clear();
    await consultations.clear();
    await activities.clear();
  }
}
