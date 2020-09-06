@IsTest
public class CaseStatusChangeOnERQueueableTest {
  @TestSetup
  private static void makeData() {
    Id engagementRecordTypeId = CaseMetadata.EngagementRequestRecordType;
    Case parentCase = new Case(
      Subject = 'Parent',
      RecordTypeId = engagementRecordTypeId,
      Status = 'New',
      Description = 'Parent Case'
    );
    insert parentCase;
    Case childCase = new Case(
      ParentId = parentCase.Id,
      Subject = 'Child',
      RecordTypeId = engagementRecordTypeId,
      Status = 'New',
      Description = 'Child Case'
    );
    insert childCase;
  }

  @isTest
  private static void updateChildNotification_onERStatusChange() {
    Id engagementRecordTypeId = CaseMetadata.EngagementRequestRecordType;
    Id caseId = fflib_IDGenerator.generate(Case.SObjectType);
    Case childCase = [
      SELECT Id, CaseNumber, Subject, RecordTypeId, Description, Status, ParentId
      FROM Case
      WHERE ParentId != null
      LIMIT 1
    ];

    Case updatedCase = new Case(
      Id = childCase.Id,
      ParentId = parentCase.Id,
      Subject = 'Test',
      RecordTypeId = engagementRecordTypeId,
      Status = 'In Process'
    );

    new CaseStatusChangeOnERQueueable(new List<Case>{ updatedCase }).execute(null);
    Case parentCase = [SELECT Id, Status, Child_case_Updates_Notification__c FROM Case WHERE ParentId = null LIMIT 1];
    System.assertEquals('In Process', parentCase.Status, 'Parent case is updated to In Progress');
  }
}
