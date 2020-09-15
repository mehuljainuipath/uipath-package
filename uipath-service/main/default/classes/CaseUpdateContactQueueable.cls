public with sharing class CaseUpdateContactQueueable extends AbstractQueueable {
  private Map<Id, Id> accountContactMap;
  public CaseUpdateContactQueueable() {
    super('CaseUpdateContactQueueable');
  }

  public override void work() {
    if (this.accountContactMap != null) {
      this.updateUnassignedContacts(this.accountContactMap);
    }
  }

  public void checkContactWithCaseEmail(List<Case> newCases) {
    Set<String> suppliedEmailsFromCases = new Set<String>();
    for (Case newCase : newCases) {
      suppliedEmailsFromCases.add(newCase.SuppliedEmail);
    }

    Map<String, Contact> emailToContactMap = new Map<String, Contact>();
    for (Contact contact : [
      SELECT Id, Name, AccountId, Email
      FROM Contact
      WHERE Email IN :suppliedEmailsFromCases AND Account.Name = 'unassigned'
    ]) {
      emailToContactMap.put(contact.Email.toLowerCase(), contact);
    }
    if (emailToContactMap.isEmpty()) {
      return;
    }
    Map<Id, Id> contactAccountMap = new Map<Id, Id>();
    for (Case newCase : newCases) {
      if (emailToContactMap.containskey(newCase.SuppliedEmail.toLowerCase())) {
        Contact contact = emailToContactMap.get(newCase.SuppliedEmail.toLowerCase());
        newCase.ContactId = contact.Id;
        if (contact.AccountId != newCase.AccountId) {
          contactAccountMap.put(newCase.ContactId, newCase.AccountId);
        }
      }
    }
  }

  public void updateUnassignedContacts(Map<Id, Id> accountToContactMap) {
    List<Contact> contactsTobeUpdated = new List<Contact>();
    for (Contact contact : [SELECT Id, AccountId FROM Contact WHERE Id IN :accountToContactMap.keyset()]) {
      contact.AccountId = accountToContactMap.get(contact.Id);
      contactsTobeUpdated.add(contact);
    }
    if (contactsTobeUpdated.isEmpty()) {
      return;
    }
    Database.update(contactsTobeUpdated, false);
  }

  public static void updateRelatedContact(List<SObject> cases) {
    List<Case> eligibleCases = (List<Case>) Collection.of(cases)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(new Set<String>{ CaseMetadata.IncidentRecordType })
          .also(Case.Origin)
          .hasValue()
          .also(Case.Origin)
          .equals('Web')
          .also(Case.SuppliedEmail)
          .hasValue()
      )
      .asList();
    if (!eligibleCases.isEmpty()) {
      CaseUpdateContactQueueable queueable = new CaseUpdateContactQueueable();
      queueable.checkContactWithCaseEmail(eligibleCases);
      AbstractQueueable.enqueue(queueable);
    }
  }
}
