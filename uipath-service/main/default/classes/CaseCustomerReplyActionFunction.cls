public class CaseCustomerReplyActionFunction implements SObjectToSObjectFunction {
  private Map<Id, SObject> existingRecords;
  public CaseCustomerReplyActionFunction(List<Case> cases, Map<Id, SObject> existingRecords) {
    this.existingRecords = existingRecords;
  }

  public SObject apply(Case record) {
    record.CheckCustomerFirstResponse__c = true;
    record.Status = 'In Process';
    if (
      record.RecordTypeId == CaseMetadata.AcademyRecordType ||
      record.RecordTypeId == CaseMetadata.SalesOperationRecordType
    ) {
      record.NoOfReceived_Prior_value__c = ((Case) existingRecords.get(record.Id)).No_of_Emails_Received__c;
    }
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
      .mapAll(new CaseCustomerReplyActionFunction(Records, existingRecords));
  }
}
