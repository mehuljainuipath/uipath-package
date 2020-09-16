@IsTest
public class CasesTest {
  @IsTest
  private static void testCreateChildCases() {
    Id caseId = fflib_IDGenerator.generate(Case.SObjectType);
    Id incidentRecordTypeID = CaseMetadata.IncidentRecordType;
    Case oldCase = new Case(
      Id = caseId,
      Subject = 'Test',
      RecordTypeId = incidentRecordTypeID,
      Status = 'New',
      CSAT__c = 1.00
    );
    Case updatedCase = new Case(
      Id = caseId,
      Subject = 'Test',
      RecordTypeId = incidentRecordTypeID,
      Status = 'Closed',
      CSAT__c = 4.00
    );
    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Case>{ updatedCase },
      new Map<Id, SObject>{ oldCase.Id => oldCase }
    );

    fflib_SObjectDomain.triggerHandler(Cases.class);
    System.assertEquals('Closed', updatedCase.Status);
  }

  @IsTest
  private static void testDeriveParentEROnInsert() {
    Id parentId = fflib_IDGenerator.generate(Case.SObjectType);
    Id childId = fflib_IDGenerator.generate(Case.SObjectType);
    Id engagementRecordTypeID = CaseMetadata.EngagementRequestRecordType;

    Case parent = new Case(
      Id = parentId,
      Subject = 'Parent',
      RecordTypeId = engagementRecordTypeID,
      Status = 'New',
      Has_ER__c = false
    );
    Case child = new Case(
      Id = childId,
      ParentId = parentId,
      Subject = 'Child',
      RecordTypeId = engagementRecordTypeID,
      Status = 'New'
    );
    fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ child });

    fflib_SObjectDomain.triggerHandler(Cases.class);
    System.assertEquals(false, parent.Has_ER__c);
  }

  @IsTest
  private static void testClosedCheckBoxOnUpdate() {
    Id caseId = fflib_IDGenerator.generate(Case.SObjectType);
    Id incidentRecordTypeID = CaseMetadata.IncidentRecordType;
    Case oldCase = new Case(
      Id = caseId,
      Subject = 'Test',
      RecordTypeId = incidentRecordTypeID,
      Status = 'New',
      No_of_Emails_Received__c = 0,
      IsClosed_NotifyOnMail__c = false
    );
    Case updatedCase = new Case(
      Id = caseId,
      Subject = 'Test',
      RecordTypeId = incidentRecordTypeID,
      Status = 'Closed',
      No_of_Emails_Received__c = 2,
      IsClosed_NotifyOnMail__c = false
    );
    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Case>{ updatedCase },
      new Map<Id, SObject>{ oldCase.Id => oldCase }
    );

    fflib_SObjectDomain.triggerHandler(Cases.class);
    System.assertEquals(true, updatedCase.IsClosed_NotifyOnMail__c);
  }

  @IsTest
  private static void testDeriveMilestoneCompletedOnInsert() {
    Id caseId = fflib_IDGenerator.generate(Case.SObjectType);
    Id incidentRecordTypeID = CaseMetadata.IncidentRecordType;

    Case cs = new Case(
      Id = caseId,
      Subject = 'Test',
      RecordTypeId = incidentRecordTypeID,
      Status = 'New',
      Milestone_Completed__c = false
    );

    fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ cs });

    fflib_SObjectDomain.triggerHandler(Cases.class);
    System.assertEquals(true, cs.Milestone_Completed__c);
  }

  /* TODO: to be modified along with the refactor of the function class */
  @IsTest
  private static void testDeriveBusinessHoursOnInsert() {
    Id caseId = fflib_IDGenerator.generate(Case.SObjectType);
    Id incidentRecordTypeID = CaseMetadata.IncidentRecordType;

    Case Case1 = new Case(
      Status = 'New',
      Origin = 'Web',
      Priority = 'Urgent',
      Country__c = 'United States',
      Related_To__c = 'Orchestrator',
      Time_Zone__c = 'GMT-05:00  Eastern Standard Time',
      Milestone_Completed__c = true,
      RecordTypeId = incidentRecordTypeID
    );

    Case Case2 = new Case(
      Status = 'New',
      Origin = 'Web',
      Priority = 'Medium',
      Country__c = 'United States',
      Related_To__c = 'Orchestrator',
      Time_Zone__c = 'GMT-06:00  Central Standard Time',
      Milestone_Completed__c = true,
      RecordTypeId = incidentRecordTypeID
    );

    Case Case3 = new Case(
      Status = 'New',
      Steps_Performed__c = 'Step performed',
      Resolution_Summary__c = 'Step performed',
      Solution__c = 'Res',
      Related_To__c = 'Studio',
      Sub_Component__c = 'Studio_Designer',
      Priority = 'Medium',
      Country__c = 'United States',
      Time_Zone__c = 'GMT-08:00  Pacific Standard Time',
      Milestone_Completed__c = true,
      RecordTypeId = incidentRecordTypeID
    );

    Case Case4 = new Case(
      Status = 'New',
      suppliedEmail = 'test@test.com',
      suppliedName = 'Testing name',
      Priority = 'Medium',
      Country__c = 'United States',
      Time_Zone__c = 'GMT-04:00  Atlantic Standard Time',
      Milestone_Completed__c = true,
      RecordTypeId = incidentRecordTypeID
    );
    Case Case5 = new Case(
      Status = 'New',
      suppliedEmail = 'test@test.com',
      suppliedName = 'Testing name',
      Priority = 'Medium',
      Country__c = 'United States',
      Milestone_Completed__c = true,
      RecordTypeId = incidentRecordTypeID
    );

    Case Case6 = new Case(
      Status = 'New',
      suppliedEmail = 'test@test.com',
      suppliedName = 'Testing name',
      Priority = 'Medium',
      Country__c = 'United States',
      Milestone_Completed__c = true,
      RecordTypeId = incidentRecordTypeID
    );

    Case Case7 = new Case(
      Status = 'New',
      SuppliedPhone = '123123123',
      SuppliedEmail = 'test1231234asd@asdawe.com',
      SuppliedName = 'John Doe',
      Subject = 'Feedback - Something',
      Priority = 'Medium',
      Country__c = 'United States',
      Milestone_Completed__c = true,
      RecordTypeId = incidentRecordTypeID,
      Time_Zone__c = null
    );

    Case Case8 = new Case(
      Status = 'New',
      SuppliedPhone = '123123123',
      SuppliedEmail = 'test1231234asd@asdawe.com',
      SuppliedName = 'John Doe',
      Subject = 'Feedback - Something',
      Priority = 'Medium',
      Country__c = 'Ecuador',
      Milestone_Completed__c = true,
      RecordTypeId = incidentRecordTypeID,
      Time_Zone__c = null
    );

    Case Case9 = new Case(
      Status = 'New',
      SuppliedPhone = '123123123',
      SuppliedEmail = 'test1231234asd@asdawe.com',
      SuppliedName = 'John Doe',
      Subject = 'Feedback - Something',
      Priority = 'Medium',
      Country__c = 'Ecuador',
      Milestone_Completed__c = true,
      RecordTypeId = incidentRecordTypeID,
      Origin = 'Community',
      Start_Date__c = System.today().adddays(30)
    );

    fflib_SObjectDomain.Test.Database.onInsert(
      new List<Case>{ Case1, Case2, Case3, Case4, Case5, Case6, Case7, Case8, Case9 }
    );

    fflib_SObjectDomain.triggerHandler(Cases.class);
  }

  @IsTest
  private static void testSetAutocloseStepsFunction() {
    Id caseId = fflib_IDGenerator.generate(Case.SObjectType);
    Id incidentRecordTypeID = CaseMetadata.IncidentRecordType;

    Case cs = new Case(
      Id = caseId,
      Subject = 'Test',
      RecordTypeId = incidentRecordTypeID,
      Status = 'New',
      Origin = 'Email'
    );

    fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ cs });

    fflib_SObjectDomain.triggerHandler(Cases.class);
    System.assertEquals(true, cs.Continue_with_Unassigned_Account__c);
    System.assertEquals('Autoclose Case Origin Email case', cs.Solution__c);
    System.assertEquals('Autoclose Case Origin Email case', cs.Steps_Performed__c);
    System.assertEquals('Autoclose Case Origin Email case', cs.Resolution_Summary__c);
  }

  @IsTest
  private static void testDeriveMilestoneCompletedOnUpdate() {
    Id caseId = fflib_IDGenerator.generate(Case.SObjectType);
    Id incidentRecordTypeID = CaseMetadata.IncidentRecordType;
    Case oldCase = new Case(Id = caseId, Subject = 'Test', RecordTypeId = incidentRecordTypeID, Status = 'New');
    Case updatedCase = new Case(
      Id = caseId,
      Subject = 'Test',
      RecordTypeId = incidentRecordTypeID,
      Status = 'In Process'
    );
    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Case>{ updatedCase },
      new Map<Id, SObject>{ oldCase.Id => oldCase }
    );

    fflib_SObjectDomain.triggerHandler(Cases.class);
    System.assertEquals(true, updatedCase.Milestone_Completed__c);
  }
}
