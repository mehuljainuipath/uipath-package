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
          Long milliseconds = currentDTLong - customFieldLong;
          Long seconds = milliseconds / 1000;
          newCase.Time_taken_to_resolve_in_Mnutes__c = seconds / 60;
        }
      }

      Decimal previousValue;
      Decimal durationInMins;
      Decimal durationInMSecs;
      Case oldCase = (Case) oldMap.get(newCase.Id);
      if (oldCase.Status == 'New') {
        if (newCase.Total_Case_New_Duration__c != null) {
          previousValue = newCase.Total_Case_New_Duration__c;
        } else {
          previousValue = 0.0;
        }
        if (newCase.CreatedDate != null && newCase.CreatedDate != DateTime.Now()) {
          durationInMSecs = (Decimal) BusinessHours.diff(newCase.BusinessHoursId, newCase.CreatedDate, DateTime.Now());
          durationInMins = durationInMSecs / 60000;
          newCase.Total_Case_New_Duration__c = durationInMins + previousValue;
        }
      } else if (oldCase.Status == 'In Process') {
        if (newCase.Total_Case_In_Process_Duration__c != null) {
          previousValue = newCase.Total_Case_In_Process_Duration__c;
        } else {
          previousValue = 0.0;
        }
        if (
          newCase.Status_In_Process_Time_Stamp__c != null &&
          newCase.Status_In_Process_Time_Stamp__c != DateTime.Now()
        ) {
          durationInMSecs = (Decimal) BusinessHours.diff(
            newCase.BusinessHoursId,
            newCase.Status_In_Process_Time_Stamp__c,
            DateTime.Now()
          );
          durationInMins = durationInMSecs / 60000;
          newCase.Total_Case_In_Process_Duration__c = durationInMins + previousValue;
        }
      } else if (oldCase.Status == 'Customer Action') {
        if (newCase.Total_Case_Customer_Action_Duration__c != null) {
          previousValue = newCase.Total_Case_Customer_Action_Duration__c;
        } else {
          previousValue = 0.0;
        }
        if (
          newCase.Status_Customer_Action_Time_Stamp__c != null &&
          newCase.Status_Customer_Action_Time_Stamp__c != DateTime.Now()
        ) {
          durationInMSecs = (Decimal) BusinessHours.diff(
            newCase.BusinessHoursId,
            newCase.Status_Customer_Action_Time_Stamp__c,
            DateTime.Now()
          );
          durationInMins = durationInMSecs / 60000;
          newCase.Total_Case_Customer_Action_Duration__c = durationInMins + previousValue;
        }
      } else if (oldCase.Status == 'Pending From Engineering') {
        if (newCase.Total_Case_Pending_Engineering_Duration__c != null) {
          previousValue = newCase.Total_Case_Pending_Engineering_Duration__c;
        } else {
          previousValue = 0.0;
        }
        if (
          newCase.Status_Pending_Engineering_Time_Stamp__c != null &&
          newCase.Status_Pending_Engineering_Time_Stamp__c != DateTime.Now()
        ) {
          durationInMSecs = (Decimal) BusinessHours.diff(
            newCase.BusinessHoursId,
            newCase.Status_Pending_Engineering_Time_Stamp__c,
            DateTime.Now()
          );
          durationInMins = durationInMSecs / 60000;
          newCase.Total_Case_Pending_Engineering_Duration__c = durationInMins + previousValue;
        }
      } else if (oldCase.Status == 'Resolved') {
        if (newCase.Total_Case_Resolved_Duration__c != null) {
          previousValue = newCase.Total_Case_Resolved_Duration__c;
        } else {
          previousValue = 0.0;
        }
        if (newCase.Status_Resolved_Time_Stamp__c != null && newCase.Status_Resolved_Time_Stamp__c != DateTime.Now()) {
          durationInMSecs = (Decimal) BusinessHours.diff(
            newCase.BusinessHoursId,
            newCase.Status_Resolved_Time_Stamp__c,
            DateTime.Now()
          );
          durationInMins = durationInMSecs / 60000;
          newCase.Total_Case_Resolved_Duration__c = durationInMins + previousValue;
        }
      }
    }
  }

  public static void deriveDurationInEachStatus(List<SObject> Records, Map<Id, SObject> existingRecords) {
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
    Id businessHourId; // = CaseMetadata.DefaultBusinessHourId;
    duration = (duration != null) ? duration : 0;
    if (fromTimestamp <> dateTimeNow) {
      Decimal durationinMins = (Decimal) BusinessHours.diff(businessHourId, fromTimestamp, dateTimeNow) / 60000;
      duration = durationinMins + duration;
    }
    return duration;
  }
}
