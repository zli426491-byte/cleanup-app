import 'package:flutter/foundation.dart';

// flutter_contacts disabled due to crash on iPadOS 26
// TODO: Replace with alternative contacts plugin

class ContactModel {
  final String id;
  final String displayName;
  final List<String> phoneNumbers;
  final List<String> emails;
  final bool hasPhoto;
  final bool isIncomplete;

  const ContactModel({
    required this.id,
    required this.displayName,
    required this.phoneNumbers,
    required this.emails,
    required this.hasPhoto,
    required this.isIncomplete,
  });
}

class DuplicateContactGroup {
  final String matchKey;
  final List<ContactModel> contacts;

  const DuplicateContactGroup({
    required this.matchKey,
    required this.contacts,
  });
}

class ContactsCleanupService extends ChangeNotifier {
  bool _isScanning = false;
  List<DuplicateContactGroup> _duplicateGroups = [];
  List<ContactModel> _incompleteContacts = [];
  List<ContactModel> _allContacts = [];

  bool get isScanning => _isScanning;
  List<DuplicateContactGroup> get duplicateGroups => _duplicateGroups;
  List<ContactModel> get incompleteContacts => _incompleteContacts;
  List<ContactModel> get allContacts => _allContacts;

  Future<void> scanContacts() async {
    _isScanning = true;
    notifyListeners();

    // Contacts feature temporarily disabled
    await Future.delayed(const Duration(seconds: 1));

    _isScanning = false;
    notifyListeners();
  }

  Future<void> mergeContacts(DuplicateContactGroup group) async {
    debugPrint('Contacts merge temporarily disabled');
  }

  Future<void> deleteContact(ContactModel contact) async {
    debugPrint('Contacts delete temporarily disabled');
  }
}
