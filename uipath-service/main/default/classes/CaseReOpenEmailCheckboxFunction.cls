/**
 * Sets IsClosed_NotifyOnMail to TRUE after Closed Email is sent.
 */
public class CaseReOpenEmailCheckboxFunction implements SObjectToSObjectFunction {
  public CaseReOpenEmailCheckboxFunction(List<Case> cases) {
  }

  public SObject apply(Case record) {
    record.IsClosed_NotifyOnMail__c = true;
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void deriveCheckboxOnUpdate(List<SObject> cases, Map<Id, SObject> existingCases) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Case.No_of_Emails_Received__c },
      cases,
      existingCases
    );

    Collection.of(cases)
      .filter(hasChanged)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(
            new Set<String>{
              CaseMetadata.IncidentRecordType,
              CaseMetadata.ServiceIncidentRecordType,
              CaseMetadata.AcademyRecordType,
              CaseMetadata.SalesOperationRecordType,
              CaseMetadata.JapanLicensingRecordType,
              CaseMetadata.JapanIncidentRecordType,
              CaseMetadata.JapanAcademyRecordType
            }
          )
          .also(Case.Status)
          .equals('Closed')
          .also(Case.IsClosed_NotifyOnMail__c)
          .equals(false)
      )
      .mapAll(new CaseReOpenEmailCheckboxFunction(cases));
  }
}
