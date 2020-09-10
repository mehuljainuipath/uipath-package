public with sharing class CaseSetCommUpdateFunction implements SObjectToSObjectFunction {
  private Map<Id, SObject> oldCases;

  public CaseSetCommUpdateFunction(List<Case> cases) {
    this.oldCases = oldCases;
  }

  public SObject apply(Case caseRecord) {
    caseRecord.Comm_Update__c = true;
    return caseRecord;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void deriveCommUpdate(List<SObject> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Case.No_of_Emails_Sent__c },
      records,
      existingRecords
    );

    Collection.of(records)
      .filter(hasChanged)
      .filter(Match.field(Case.No_of_Emails_Sent__c).greaterThanOrEquals(3))
      .mapAll(new CaseSetCommUpdateFunction(records));
  }
}
