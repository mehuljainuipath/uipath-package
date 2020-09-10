public class CaseCustomerReplyActionFunction implements SObjectToSObjectFunction {
  public CaseCustomerReplyActionFunction(List<Case> cases) {
  }

  public SObject apply(Case record) {
    record.CheckCustomerFirstResponse__c = true;
    record.Status = 'In Process';
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void deriveCustomerFirstResponse(List<SObject> Records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Case.No_of_Emails_Received__c },
      Records,
      existingRecords
    );

    Collection.of(Records)
      .filter(hasChanged)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(
            new Set<String>{
              CaseMetadata.ServiceRequestRecordType,
              CaseMetadata.IncidentRecordType,
              CaseMetadata.JapanAcademyRecordType,
              CaseMetadata.JapanLicensingRecordType,
              CaseMetadata.JapanIncidentRecordType,
              CaseMetadata.AcademyRecordType,
              CaseMetadata.SalesOperationRecordType
            }
          )
          .also(Case.No_of_Emails_Received__c)
          .greaterThanOrEquals(1)
      )
      .mapAll(new CaseCustomerReplyActionFunction(Records));
  }
}
