/**
 * Set Comm_Update__c to true if No_of_Emails_Sent__c greater or equal than 3.
 */
public class CaseSetCommUpdateFunction implements SObjectToSObjectFunction {
  public CaseSetCommUpdateFunction(List<Case> cases) {
  }

  public SObject apply(Case record) {
    record.Comm_Update__c = true;
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void deriveCommUpdate(List<SObject> cases, Map<Id, SObject> existingCases) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Case.No_of_Emails_Sent__c },
      cases,
      existingCases
    );

    Collection.of(cases)
      .filter(hasChanged)
      .filter(Match.field(Case.No_of_Emails_Sent__c).greaterThanOrEquals(3))
      .mapAll(new CaseSetCommUpdateFunction(cases));
  }
}
