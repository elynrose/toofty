/// Gender option for a child profile.
enum ChildGender {
  male,
  female,
  none;

  String get label {
    switch (this) {
      case ChildGender.male:
        return 'Male';
      case ChildGender.female:
        return 'Female';
      case ChildGender.none:
        return 'None';
    }
  }

  static ChildGender fromJson(String? value) {
    switch (value) {
      case 'male':
        return ChildGender.male;
      case 'female':
        return ChildGender.female;
      default:
        return ChildGender.none;
    }
  }

  String toJson() => name;
}
