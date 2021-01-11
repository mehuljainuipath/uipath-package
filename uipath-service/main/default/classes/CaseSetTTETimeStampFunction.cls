public with sharing class CaseSetTTETimeStampFunction implements SObjectToSObjectFunction {
  private Map<Id, SObject> oldCases;

  public CaseSetTTETimeStampFunction(List<Case> cases) {
    this.oldCases = oldCases;
  }

  public SObject apply(Case caseRecord) {
    caseRecord.TTE_Time_Stamp__c = system.now();
    return caseRecord;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void deriveTTETimeStamp(List<Case> records) {
    Collection.of(records)
      .filter(Match.field(Case.IsEscalated).notEquals(null).also(Case.IsEscalated).equals(true))
      .mapAll(new CaseSetTTETimeStampFunction(records));
  }
}
