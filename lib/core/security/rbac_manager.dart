enum UserRole {
  leadEngineer,
  qcInspector,
  fieldTechnician,
  clientRepresentative,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.leadEngineer:
        return 'Lead Engineer (Admin)';
      case UserRole.qcInspector:
        return 'QC Inspector';
      case UserRole.fieldTechnician:
        return 'Field Technician';
      case UserRole.clientRepresentative:
        return 'Client Representative (Read-Only)';
    }
  }

  String get roleKey {
    switch (this) {
      case UserRole.leadEngineer:
        return 'lead_engineer';
      case UserRole.qcInspector:
        return 'qc_inspector';
      case UserRole.fieldTechnician:
        return 'field_technician';
      case UserRole.clientRepresentative:
        return 'client_rep';
    }
  }

  bool get canApproveRevisions => this == UserRole.leadEngineer;
  bool get canUploadRevisions => this == UserRole.leadEngineer || this == UserRole.qcInspector;
  bool get canCreateMarkups => this != UserRole.clientRepresentative;
  bool get canPerformInspections => this == UserRole.leadEngineer || this == UserRole.qcInspector;
  bool get canSignInspection => this == UserRole.leadEngineer || this == UserRole.qcInspector || this == UserRole.clientRepresentative;
  bool get canCloseIssues => this == UserRole.leadEngineer || this == UserRole.qcInspector;
  bool get canExportReports => true;
  bool get canManageSyncSettings => this == UserRole.leadEngineer;
  bool get canViewAuditLogs => this == UserRole.leadEngineer;
}

class SessionUser {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String company;
  final DateTime loggedInAt;

  const SessionUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.company,
    required this.loggedInAt,
  });

  static SessionUser defaultLeadEngineer() {
    return SessionUser(
      id: 'usr-lead-001',
      email: 'lead.engineer@offshore-epc.com',
      fullName: 'Alex Morgan, PE',
      role: UserRole.leadEngineer,
      company: 'Aramco Offshore Engineering',
      loggedInAt: DateTime.now(),
    );
  }
}
