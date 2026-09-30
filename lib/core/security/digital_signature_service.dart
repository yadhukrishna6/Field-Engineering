import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'rbac_manager.dart';
import 'audit_logger.dart';

class DigitalSignature {
  final String id;
  final String signerName;
  final String signerTitle;
  final String signerCompany;
  final UserRole signerRole;
  final String purpose; // INSPECTION, APPROVAL, REPORT, AS_BUILT_VERIFICATION
  final String targetEntityId;
  final List<List<Offset>> strokePaths;
  final String signatureHash;
  final DateTime signedAt;

  const DigitalSignature({
    required this.id,
    required this.signerName,
    required this.signerTitle,
    required this.signerCompany,
    required this.signerRole,
    required this.purpose,
    required this.targetEntityId,
    required this.strokePaths,
    required this.signatureHash,
    required this.signedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'signer_name': signerName,
      'signer_title': signerTitle,
      'signer_company': signerCompany,
      'signer_role': signerRole.name,
      'purpose': purpose,
      'target_entity_id': targetEntityId,
      'signature_hash': signatureHash,
      'signed_at': signedAt.toIso8601String(),
    };
  }
}

class DigitalSignatureService {
  static final DigitalSignatureService _instance = DigitalSignatureService._internal();
  factory DigitalSignatureService() => _instance;
  DigitalSignatureService._internal();

  DigitalSignature createSignature({
    required String signerName,
    required String signerTitle,
    required String signerCompany,
    required UserRole signerRole,
    required String purpose,
    required String targetEntityId,
    required List<List<Offset>> strokePaths,
  }) {
    final now = DateTime.now();
    final rawData = '$signerName:$signerRole:$purpose:$targetEntityId:${now.millisecondsSinceEpoch}';
    final hash = 'SIG-${base64UrlEncode(utf8.encode(rawData)).substring(0, 16).toUpperCase()}';

    final sig = DigitalSignature(
      id: const Uuid().v4(),
      signerName: signerName,
      signerTitle: signerTitle,
      signerCompany: signerCompany,
      signerRole: signerRole,
      purpose: purpose,
      targetEntityId: targetEntityId,
      strokePaths: strokePaths,
      signatureHash: hash,
      signedAt: now,
    );

    AuditLogger().log(
      action: 'DIGITAL_SIGNATURE',
      entityType: purpose,
      entityId: targetEntityId,
      details: 'Signed by $signerName ($signerTitle, ${signerRole.displayName}) [Hash: $hash]',
    );

    return sig;
  }
}
