@IsTest
public class SalesCasesTest {
  @IsTest
  private static void testUpdateBillToOnInsert() {
    Id caseId = fflib_IDGenerator.generate(Case.SObjectType);
    Id legalRequestRecordTypeId = SalesCaseMetadata.LegalRequestRecordType;

    Account acc = new Account(
      Name = 'TestAccountUK',
      Country__c = 'United Kingdom',
      BillingCountry = 'United Kingdom',
      Industry = 'Others'
    );
    insert acc;

    Opportunity opp = new Opportunity(
      Name = 'Test',
      AccountId = acc.Id,
      StageName = 'Proposal',
      CloseDate = System.today(),
      Amount = 100,
      Description = 'Test description'
    );
    insert opp;

    Case cs = new Case(
      AccountId = acc.Id,
      Id = caseId,
      Opportunity__c = opp.Id,
      Subject = 'Case1',
      RecordTypeId = legalRequestRecordTypeId,
      Status = 'New'
    );

    fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ cs });

    fflib_SObjectDomain.triggerHandler(SalesCases.class);
    System.assertEquals(cs.AccountId, cs.Bill_To__c);
  }
}
