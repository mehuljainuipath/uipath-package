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

    Case updatedCase = new Case(
      Id = casesToInsert.get(1).Id,
      ParentId = casesToInsert.get(0).Id,
      Subject = 'Test',
      RecordTypeId = engagementRecordTypeId,
      Status = 'In Process'
    );
  }

  @isTest
  private static void updateChildNotification_onERStatusChange() {
    Id engagementRecordTypeId = CaseMetadata.EngagementRequestRecordType;
    Case oldCase = [SELECT Id, Status, ParentId FROM Case WHERE ParentId != null LIMIT 1];
    Case updatedCase = new Case(
      Id = oldCase.Id,
      ParentId = oldCase.ParentId,
      Subject = 'Test',
      RecordTypeId = engagementRecordTypeId,
      Status = 'In Process'
    );

    oldCase.ParentId = casesToInsert.get(0).Id;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Case>{ updatedCase },
      new Map<Id, SObject>{ updatedCase.Id => oldCase }
    );

    fflib_SObjectDomain.triggerHandler(Cases.class);
  }
}
