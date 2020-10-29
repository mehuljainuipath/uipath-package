@IsTest
public class SalesCasesTest {
  @IsTest
  private static void testUpdateBillWOOpsToOnInsert() {
    Id caseId = fflib_IDGenerator.generate(Case.SObjectType);
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Id legalRequestRecordTypeId = SalesCaseMetadata.LegalRequestRecordType;

    Account acc = new Account(
      Id = accountId,
      Name = 'TestAccountUK',
      Country__c = 'United Kingdom',
      BillingCountry = 'United Kingdom',
      Industry = 'Others'
    );

    Case cs = new Case(
      AccountId = accountId,
      Id = caseId,
      Subject = 'Case1',
      RecordTypeId = legalRequestRecordTypeId,
      Status = 'New'
    );

    fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ cs });

    fflib_SObjectDomain.triggerHandler(SalesCases.class);
    System.assertEquals(cs.AccountId, cs.Bill_To__c);
  }

  @IsTest
  private static void testUpdateBillWOOpsToOnUpdate() {
    Id caseId = fflib_IDGenerator.generate(Case.SObjectType);
    Id oldAccountId = fflib_IDGenerator.generate(Account.SObjectType);
    Id newAccountId = fflib_IDGenerator.generate(Account.SObjectType);
    Id legalRequestRecordTypeId = SalesCaseMetadata.LegalRequestRecordType;

    Account oldAccount = new Account(
      Id = oldAccountId,
      Name = 'TestAccountUK',
      Country__c = 'United Kingdom',
      BillingCountry = 'United Kingdom',
      Industry = 'Others'
    );

    Account newAccount = new Account(
      Id = newAccountId,
      Name = 'TestAccountUK2',
      Country__c = 'United Kingdom',
      BillingCountry = 'United Kingdom',
      Industry = 'Others'
    );

    Case oldCase = new Case(
      AccountId = oldAccountId,
      Bill_To__c = AccountId,
      Id = caseId,
      Subject = 'Case1',
      RecordTypeId = legalRequestRecordTypeId,
      Status = 'New'
    );

    Case updatedCase = new Case(
      AccountId = newAccountId,
      Id = caseId,
      Subject = 'Case1',
      RecordTypeId = legalRequestRecordTypeId,
      Status = 'New'
    );

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Case>{ updatedCase },
      new Map<Id, SObject>{ oldCase.Id => oldCase }
    );

    fflib_SObjectDomain.triggerHandler(SalesCases.class);
    System.assertEquals(newAccountId, updatedCase.Bill_To__c);
  }
}
