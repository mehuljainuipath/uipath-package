public class CaseContactChangeFunctionTest {
  @TestSetup
  static void makeData() {
    Account firstAccount = new Account();
    firstAccount.Name = 'First Account';
    firstAccount.BillingCountry = 'United Kingdom';
    firstAccount.Industry = 'Others';
    firstAccount.Country__c = 'United Kingdom';

    Account secondAccount = new Account();
    secondAccount.Name = 'Second Account';
    secondAccount.BillingCountry = 'United Kingdom';
    secondAccount.Industry = 'Others';
    secondAccount.Country__c = 'United Kingdom';

    List<Account> accountsToInsert = new List<Account>();
    accountsToInsert.add(firstAccount);
    accountsToInsert.add(secondAccount);
    insert accountsToInsert;

    Contact firstContact = new Contact();
    firstContact.AccountId = accountsToInsert.get(0).Id;
    firstContact.FirstName = 'John';
    firstContact.LastName = 'Doe';
    firstContact.Email = 'john@doe.com';

    Contact secondContact = new Contact();
    secondContact.AccountId = accountsToInsert.get(1).Id;
    secondContact.FirstName = 'Mark';
    secondContact.LastName = 'Doe';
    secondContact.Email = 'mark@doe.com';

    List<Contact> contactsToInsert = new List<Contact>();
    contactsToInsert.add(firstContact);
    contactsToInsert.add(secondContact);
    insert contactsToInsert;

    Case caseToInsert = new Case();
    caseToInsert.Subject = 'New Case';
    caseToInsert.RecordTypeId = CaseMetadata.IncidentRecordType;
    caseToInsert.ContactId = contactsToInsert.get(0).Id;
    caseToInsert.AccountId = accountsToInsert.get(0).Id;
    insert caseToInsert;
  }

  @IsTest
  static void deriveAccountBasedOnContact_onUpdateCase() {
    Case savedCase = [SELECT Id, AccountId, ContactId FROM Case];
    Contact otherContact = [SELECT Id, AccountId FROM Contact WHERE Id != :savedCase.ContactId];
    Test.startTest();
    savedCase.ContactId = otherContact.Id;
    update savedCase;
    Test.stopTest();
    savedCase = [SELECT Id, AccountId, ContactId FROM Case];
    System.assertEquals(
      otherContact.AccountId,
      savedCase.AccountId,
      'Account Id is updated on the case when contact is changed.'
    );
  }
}
