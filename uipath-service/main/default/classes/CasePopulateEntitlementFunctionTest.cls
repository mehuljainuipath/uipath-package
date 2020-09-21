@IsTest
public class CasePopulateEntitlementFunctionTest {
  @TestSetup
  static void makeData() {
    Account account = new Account(Name = 'John');
    account.BillingStreet = 'Test Street';
    account.BillingCity = 'Test City';
    account.BillingPostalCode = 'SW1 3DWW';
    account.BillingCountry = 'United Kingdom';
    account.Phone = '1234567890';
    account.Industry = 'Others';
    insert account;

    List<Entitlement> entitlements = new List<Entitlement>();
    for (String entitlementName : CaseMetadata.ENTITLEMENT_NAMES) {
      entitlements.add(new Entitlement(Name = entitlementName, AccountId = account.Id));
    }
    insert entitlements;
  }

  @IsTest
  static void casePopulateEntitlementFunction_onInsert() {
    Id incidentRecordTypeID = CaseMetadata.IncidentRecordType;
    Case newCase = new Case(Subject = 'Test', RecordTypeId = incidentRecordTypeID, Status = 'New');
    fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ newCase });
    fflib_SObjectDomain.triggerHandler(Cases.class);
    System.assertNotEquals(null, newCase.EntitlementId, 'Entitlement is not populated on insert');
  }

  @IsTest
  static void casePopulateEntitlementFunction_onUpdate() {
    Id incidentRecordTypeID = CaseMetadata.IncidentRecordType;
    Case oldCase = new Case(Subject = 'Test', RecordTypeId = incidentRecordTypeID, Status = 'New');
    Case updatedCase = new Case(
      Subject = 'Test',
      RecordTypeId = incidentRecordTypeID,
      Status = 'New',
      Ischanged_Support_Type__c = true
    );
    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Case>{ updatedCase },
      new Map<Id, SObject>{ oldCase.Id => oldCase }
    );

    fflib_SObjectDomain.triggerHandler(Cases.class);
    System.assertNotEquals(null, updatedCase.EntitlementId, 'Entitlement is not populated on insert');
    System.assertEquals(false, updatedCase.Ischanged_Support_Type__c, 'Is changed support type is not updated');
  }
}
