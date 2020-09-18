public with sharing class CaseStatusDurationFunction implements SObjectToSObjectFunction {
  public SObject apply(Case caseRecord) {
    return caseRecord;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public void calculateDurations(List<Case> newCases, Map<Id, SObject> oldMap) {
    for (Case newCase : newCases) {
      if (newCase.Status == 'Closed') {
        if (null != newCase.Start_When_New__c && newCase.Time_taken_to_resolve_in_Mnutes__c == null) {
          Long customFieldLong = newCase.Start_When_New__c.getTime();
          Long currentDTLong = DateTime.now().getTime();
          newCase.Time_taken_to_resolve_in_Mnutes__c = (currentDTLong - customFieldLong) / 60000;
        }
      }

      Case oldCase = (Case) oldMap.get(newCase.Id);
      if (oldCase.Status == 'New') {
        newCase.Total_Case_New_Duration__c = calculateDuration(newCase.CreatedDate, newCase.Total_Case_New_Duration__c);
      } else if (oldCase.Status == 'In Process') {
        newCase.Total_Case_In_Process_Duration__c = calculateDuration(
          newCase.Status_In_Process_Time_Stamp__c,
          newCase.Total_Case_In_Process_Duration__c
        );
      } else if (oldCase.Status == 'Customer Action') {
        newCase.Total_Case_Customer_Action_Duration__c = calculateDuration(
          newCase.Status_Customer_Action_Time_Stamp__c,
          newCase.Total_Case_Customer_Action_Duration__c
        );
      } else if (oldCase.Status == 'Pending From Engineering') {
        newCase.Total_Case_Pending_Engineering_Duration__c = calculateDuration(
          newCase.Status_Pending_Engineering_Time_Stamp__c,
          newCase.Total_Case_Pending_Engineering_Duration__c
        );
      } else if (oldCase.Status == 'Resolved') {
        newCase.Total_Case_Resolved_Duration__c = calculateDuration(
          newCase.Status_Resolved_Time_Stamp__c,
          newCase.Total_Case_Resolved_Duration__c
        );
      }
    }
  }

  public static void deriveStatusDuration(List<SObject> Records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(new Set<SObjectField>{ Case.Status }, Records, existingRecords);

    List<Case> eligibleCases = Collection.of(Records)
      .filter(hasChanged)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(
            new Set<String>{
              CaseMetadata.SalesOperationRecordType,
              CaseMetadata.AcademyRecordType,
              CaseMetadata.IncidentRecordType,
              CaseMetadata.ServiceRequestRecordType,
              CaseMetadata.JapanAcademyRecordType,
              CaseMetadata.JapanLicensingRecordType,
              CaseMetadata.JapanIncidentRecordType,
              CaseMetadata.JapanEngagementRequestRecordType,
              CaseMetadata.EngagementRequestRecordType
            }
          )
      )
      .asList();
    if (!eligibleCases.isEmpty()) {
      new CaseStatusDurationFunction().calculateDurations(eligibleCases, existingRecords);
    }
  }

  private Decimal calculateDuration(DateTime fromTimestamp, Decimal duration) {
    Datetime dateTimeNow = DateTime.now();
    Id businessHourId = CaseMetadata.DefaultBusinessHourId;
    duration = (duration != null) ? duration : 0;
    if (fromTimestamp <> dateTimeNow) {
      Decimal durationinMins = (Decimal) BusinessHours.diff(businessHourId, fromTimestamp, dateTimeNow) / 60000;
      duration = durationinMins + duration;
    }
    return duration;
  }
}
