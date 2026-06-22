enum UserRole {
  adminFaculty,
  ormawaAccount,
  memberAccount,
}

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.adminFaculty:
        return 'Admin';
      case UserRole.ormawaAccount:
        return 'Ormawa';
      case UserRole.memberAccount:
        return 'Student';
    }
  }
}
