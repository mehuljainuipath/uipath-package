/**
 * Sets Bill_To__c to AccountId before insert.
 */
public class SalesCaseSetContractDateFunction implements SObjectToSObjectFunction {
  Map<Id, Case> completeCases = new Map<Id, Case>();

  public SalesCaseSetContractDateFunction(List<Case> cases) {
    for (Case caseRecord : [
      SELECT
        Id,
        Contract_Start_Date__c,
        Contract_End_Date__c,
        Opportunity__r.Contract_Start_Date__c,
        Opportunity__r.Contract_End_Date__c
      FROM Case
      WHERE Id IN :cases
    ]) {
      completeCases.put(caseRecord.Id, caseRecord);
    }
  }

  public SObject apply(Case record) {
    record.Contract_Start_Date__c = completeCases.get(record.Id).Opportunity__r.Contract_Start_Date__c;
    record.Contract_End_Date__c = completeCases.get(record.Id).Opportunity__r.Contract_End_Date__c;
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void setContractDatesOnInsert(List<Case> records) {
    Collection.of(records)
      .filter(Match.field(Case.RecordTypeId).isIn(new Set<String>{ SalesCaseMetadata.FinanceRequestRecordType }))
      .mapSome(
        Match.field(Case.Billing_Event__c).equals(null).also(Case.Opportunity__c).hasValue(),
        new SalesCaseSetContractDateFunction(records)
      );
  }
}
