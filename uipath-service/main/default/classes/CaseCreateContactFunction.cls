public with sharing class CaseCreateContactFunction implements SObjectToSObjectFunction {
  private static Map<String, Contact> emailToContactMap;
  public CaseCreateContactFunction() {
  }
  public SObject apply(Case caseRecord) {
    Contact newContact = emailToContactMap.get(caseRecord.SuppliedEmail);
    caseRecord.ContactId = newContact.Id;
    return caseRecord;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public void createContactUpdateCase(List<Case> newCases) {
    Id contactRecordtypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contact').getRecordTypeId();
    Id dummyAccountId = Label.Dummy_Account;
    Id academyAccountId = Label.Academy_Unassigned_Acc;

    List<String> emailAddresses = new List<String>();
    for (Case newCaseRecord : newCases) {
      emailAddresses.add(newCaseRecord.SuppliedEmail);
    }

    Set<String> existingEmails = new Set<String>();
    for (Contact existingContact : [SELECT Id, Email FROM Contact WHERE Email IN :emailAddresses]) {
      existingEmails.add(existingContact.Email);
    }

    Set<Id> accountIds = new Set<Id>();
    for (Case newCaseRecord : newCases) {
      if (newCaseRecord.RecordTypeId == CaseMetadata.IncidentRecordType && newCaseRecord.AccountId != null) {
        accountIds.add(newCaseRecord.accountId);
      }
    }

    Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, OwnerId FROM Account WHERE Id IN :accountIds]);
    emailToContactMap = new Map<String, Contact>();
    List<Case> casesToUpdate = new List<Case>();

    for (Case newCaseRecord : newCases) {
      if (newCaseRecord.SuppliedName.contains('@')) {
        return;
      }
      if (existingEmails.contains(newCaseRecord.SuppliedEmail)) {
        return;
      }

      String[] nameParts = newCaseRecord.SuppliedName.split(' ', 2);
      Integer numberOfNames = nameParts.size();
      if (numberOfNames < 1) {
        return;
      }
      String firstNameFromWeb = (numberOfNames > 1) ? nameParts[0] : '';
      String lastNameFromWeb = nameParts[numberOfNames - 1];

      Contact newContact = new Contact(
        FirstName = firstNameFromWeb,
        LastName = lastNameFromWeb,
        Email = newCaseRecord.SuppliedEmail,
        Autocreated__c = true,
        Title = 'Title',
        RecordTypeId = contactRecordtypeId,
        Phone = newCaseRecord.SuppliedPhone,
        OwnerId = accountMap.containsKey(newCaseRecord.AccountId)
          ? accountMap.get(newCaseRecord.AccountId).OwnerId
          : UserInfo.getUserId(),
        AccountId = (newCaseRecord.RecordTypeId == CaseMetadata.AcademyRecordType)
          ? academyAccountId
          : (accountMap.containsKey(newCaseRecord.AccountId)
              ? accountMap.get(newCaseRecord.AccountId).Id
              : dummyAccountId)
      );
      emailToContactMap.put(newCaseRecord.SuppliedEmail, newContact);
    }

    insert emailToContactMap.values();
  }

  public static void deriveContact(List<SObject> cases) {
    List<Case> eligibleCases = (List<Case>) Collection.of(cases)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(new Set<String>{ CaseMetadata.AcademyRecordType, CaseMetadata.IncidentRecordType })
          .also(Case.ContactId)
          .equals(null)
          .also(Case.SuppliedEmail)
          .hasValue()
          .also(Case.SuppliedName)
          .hasValue()
      )
      .asList();
    if (!eligibleCases.isEmpty()) {
      new CaseCreateContactFunction().createContactUpdateCase(eligibleCases);
    }
  }
}
