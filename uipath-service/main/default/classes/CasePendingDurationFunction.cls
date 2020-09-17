public with sharing class CasePendingDurationFunction implements SObjectToSObjectFunction {
  public SObject apply(Case caseRecord) {
    return caseRecord;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public void calculateDurations(List<Case> newCases, Map<Id, SObject> oldCasesMap) {
    List<String> pickListValuesList = CaseMetadata.AwaitingPendingReasons;

    for (Case newCase : newCases) {
      Case oldcase = (Case) oldCasesMap.get(newCase.Id);

      if (oldcase.Awaiting_Pending_Reason__c == pickListValuesList[0]) {
        newCase.Duration_in_Pending_Tech_support__c = calculateDurationInPending(
          newCase.Pending_Tech_support_time_stamp__c,
          newCase.Duration_in_Pending_Tech_support__c
        );
      } else if (oldcase.Awaiting_Pending_Reason__c == pickListValuesList[1]) {
        newCase.Duration_Pending_Sr_Tech_Support__c = calculateDurationInPending(
          newCase.Pending_Sr_Tech_Support_time_stamp__c,
          newCase.Duration_Pending_Sr_Tech_Support__c
        );
      } else if (oldcase.Awaiting_Pending_Reason__c == pickListValuesList[2]) {
        newCase.Duration_in_Pending_Infra_MCS_support__c = calculateDurationInPending(
          newCase.Pending_Infra_MCS_Time_stamp__c,
          newCase.Duration_in_Pending_Infra_MCS_support__c
        );
      } else if (oldcase.Awaiting_Pending_Reason__c == pickListValuesList[3]) {
        System.debug('### 4');
        newCase.Duration_in_Pending_Product__c = calculateDurationInPending(
          newCase.Pending_Product_Timestamp__c,
          newCase.Duration_in_Pending_Product__c
        );
      }
    }
  }

  public static void derivePendingDuration(List<SObject> Records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Case.Awaiting_Pending_Reason__c },
      Records,
      existingRecords
    );

    List<Case> eligibleCases = Collection.of(Records)
      .filter(hasChanged)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(
            new Set<String>{ CaseMetadata.EngagementRequestRecordType, CaseMetadata.JapanEngagementRequestRecordType }
          )
      )
      .asList();
    if (!eligibleCases.isEmpty()) {
      new CasePendingDurationFunction().calculateDurations(eligibleCases, existingRecords);
    }
  }

  private Decimal calculateDurationInPending(DateTime pendingTimestamp, Decimal durationInPending) {
    Datetime dateTimeNow = DateTime.now();
    Id businessHourId = CaseMetadata.DefaultBusinessHourId;
    durationInPending = (durationInPending != null) ? durationInPending : 0;
    if (pendingTimestamp <> dateTimeNow) {
      Decimal durationinMins = (Decimal) BusinessHours.diff(businessHourId, pendingTimestamp, dateTimeNow) / 60000;
      durationInPending = durationinMins + durationInPending;
    }
    return durationInPending;
  }
}
