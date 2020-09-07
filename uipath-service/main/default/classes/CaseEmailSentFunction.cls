public with sharing class CaseEmailSentFunction implements SObjectToSObjectFunction {
  private Map<Id, Case> parentCaseMap;

  public CaseEmailSentFunction(List<Case> cases) {
  }

  public SObject apply(Case caseRecord) {
    caseRecord.No_of_Emails_Sent__c = 1;
    return caseRecord;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void incrementEmailCount(List<Case> records) {
    Collection.of(records)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(
            new Set<String>{
              CaseMetadata.IncidentRecordType,
              CaseMetadata.SalesOperationRecordType,
              CaseMetadata.AcademyRecordType,
              CaseMetadata.JapanIncidentRecordType,
              CaseMetadata.JapanAcademyRecordType,
              CaseMetadata.JapanLicensingRecordType
            }
          )
          .also(Case.ContactId)
          .hasValue()
      )
      .mapSome(
        Match.field(Case.Status)
          .equals('New')
          .also(Case.Origin)
          .isIn(new Set<String>{ 'Web', 'Phone', 'Select One', 'Internally - On behalf of customer' }),
        new CaseEmailSentFunction(records)
      );
  }
}
