@isTest
public with sharing class CaseCustomerReplyActionFunctionTest {
  @IsTest
  private static void onUpdate_deriveCustomerFirstResponse() {
    Id caseId = fflib_IDGenerator.generate(Case.SObjectType);
    Id academyId = CaseMetadata.AcademyRecordType;
    Case oldCase = new Case(
      Id = caseId,
      Subject = 'Test',
      RecordTypeId = academyId,
      Status = 'New',
      No_of_Emails_Received__c = 0
    );
    Case updatedCase = new Case(
      Id = caseId,
      Subject = 'Test',
      RecordTypeId = academyId,
      Status = 'New',
      No_of_Emails_Received__c = 1
    );
    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Case>{ updatedCase },
      new Map<Id, SObject>{ oldCase.Id => oldCase }
    );

    fflib_SObjectDomain.triggerHandler(Cases.class);
    System.assertEquals(true, updatedCase.CheckCustomerFirstResponse__c, 'Customer First Response is set');
    System.assertEquals('In Process', updatedCase.Status, 'Status is changed to In Process');
    System.assertEquals(0, updatedCase.NoOfReceived_Prior_value__c, 'Prior Value should be zero');
  }
}
