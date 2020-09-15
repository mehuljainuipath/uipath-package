@IsTest
public class CaseUpdateContactQueueableTest {
  @TestSetup
  static void makeData() {
    Account account = new Account(Name = 'unassigned');
    account.BillingStreet = 'Test Street';
    account.BillingCity = 'Test City';
    account.BillingPostalCode = 'SW1 3DWW';
    account.BillingCountry = 'United Kingdom';
    account.Phone = '1234567890';
    account.Industry = 'Others';
    insert account;

    Contact contact = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john@doe.com', AccountId = account.Id);
    insert contact;
  }

  @IsTest
  static void updateContactOnCase_onCaseInsert() {
    Account account = new Account(Name = 'Named Account');
    account.BillingStreet = 'Main Street';
    account.BillingCity = 'London';
    account.BillingPostalCode = 'SW1 3DWW';
    account.BillingCountry = 'United Kingdom';
    account.Phone = '2321123211';
    account.Industry = 'IT';
    insert account;
    Case incidentCase = new Case();
    incidentCase.AccountId = account.Id;
    incidentCase.RecordTypeId = CaseMetadata.IncidentRecordType;
    incidentCase.Subject = 'Incident  Case';
    incidentCase.Status = 'New';
    incidentCase.SuppliedEmail = 'john@doe.com';
    incidentCase.Problem__c = 'Some Problem';
    incidentCase.Cause__c = 'Some Cause';
    incidentCase.Origin = 'Web';
    fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ incidentCase });

    fflib_SObjectDomain.triggerHandler(Cases.class);
    Contact contact = [SELECT Id, AccountId FROM Contact];
    System.assertEquals(contact.Id, incidentCase.ContactId, 'Contact is not populated');
    new CaseUpdateContactQueueable().updateUnassignedContacts(new Map<Id, Id>{ contact.Id => incidentCase.AccountId });
    contact = [SELECT Id, AccountId FROM Contact];
    System.assertEquals(incidentCase.AccountId, contact.AccountId, 'Account Id on contact is not updated');
  }
}
