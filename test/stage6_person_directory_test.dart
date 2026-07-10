import 'package:flutter_test/flutter_test.dart';
import 'package:lawyer_office/presentation/screens/persons/person_models.dart';

void main() {
  test('PersonsDirectoryNotifier filters persons and links agencies to cases', () {
    final notifier = PersonsDirectoryNotifier();

    notifier.setSearchQuery('أحمد');
    expect(notifier.state.filteredPersons, isNotEmpty);

    notifier.setRoleFilter(PersonDirectoryRole.client);
    expect(
      notifier.state.filteredPersons.every((person) => person.roles.contains(PersonDirectoryRole.client)),
      isTrue,
    );

    final agencyBefore = notifier.agencyById('agency_1');
    expect(agencyBefore, isNotNull);
    expect(agencyBefore!.linkedCaseIds.contains('999'), isFalse);

    notifier.linkAgencyToCase('agency_1', '999');
    final agencyAfter = notifier.agencyById('agency_1');
    expect(agencyAfter!.linkedCaseIds.contains('999'), isTrue);
  });
}
