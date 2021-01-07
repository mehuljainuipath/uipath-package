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
    List<String> emailAddresses = Collection.of(newCases).pluckStrings(Case.SuppliedEmail);
    Set<String> existingEmails = new Set<String>();
    for (Contact existingContact : [SELECT Id, Email FROM Contact WHERE Email IN :emailAddresses]) {
      existingEmails.add(existingContact.Email);
    }

    List<Id> accountIdsAsList = Collection.of(newCases)
      .filter(Match.field(Case.RecordTypeId).equals(CaseMetadata.IncidentRecordType).also(Case.AccountId).hasValue())
      .pluckIds(Case.AccountId);

    Set<Id> accountIds = new Set<Id>(accountIdsAsList);
    Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, OwnerId FROM Account WHERE Id IN :accountIds]);
    emailToContactMap = new Map<String, Contact>();
    List<Case> casesToUpdate = new List<Case>();
    Id contactRecordtypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contact').getRecordTypeId();
    
    Map<String, Id> nameToAccountMap = new Map<String, Id>();
    for (Account unassignedAccount : [SELECT Id, Name FROM Account WHERE Name IN (:Label.Dummy_Account, :Label.Academy_Unassigned_Acc) LIMIT 2]) {
      nameToAccountMap.put(unassignedAccount.Name, unassignedAccount.Id);
    }
    Id dummyAccountId = nameToAccountMap.get(Label.Dummy_Account);
    Id academyAccountId = nameToAccountMap.get(Label.Academy_Unassigned_Acc);

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
          .also(Case.Subscription_Code__c)
          .notEquals(CaseMetadata.SUBSCRIPTION_TRIAL)
          .also(Case.Is_Free_Mailer__c)
          .equals(false)
      )
      .asList();
    if (!eligibleCases.isEmpty()) {
      new CaseCreateContactFunction().createContactUpdateCase(eligibleCases);
    }
  }
}
