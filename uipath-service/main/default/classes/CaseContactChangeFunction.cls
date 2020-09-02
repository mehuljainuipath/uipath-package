public with sharing class CaseContactChangeFunction implements SObjectToSObjectFunction {
  private Map<Id, Contact> contactMap;
  public CaseContactChangeFunction(List<Case> cases) {
    System.debug('### CaseContactChangeFunction ' + cases);
    Set<Id> contactIds = new Set<Id>();
    for (Case record : cases) {
      contactIds.add(record.ContactId);
    }
    System.debug('### contactIds ' + contactIds);
    contactMap = new Map<Id, Contact>([SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds]);
  }

  public SObject apply(Case record) {
    record.AccountId = contactMap.get(record.ContactId).AccountId;
    System.debug('### Apply ' + record.AccountId);
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void deriveAccountBasedOnContact(List<SObject> cases, Map<Id, SObject> existingCases) {
    System.debug('### deriveAccountBasedOnContact');
    SObjectPredicate hasChanged = new HasRecordChanged(new Set<SObjectField>{ Case.ContactId }, cases, existingCases);

    Collection.of(cases)
      .filter(hasChanged)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(
            new Set<String>{
              CaseMetadata.AcademyRecordType,
              CaseMetadata.EngagementRequestRecordType,
              CaseMetadata.IncidentRecordType,
              CaseMetadata.JapanAcademyRecordType,
              CaseMetadata.JapanEngagementRequestRecordType,
              CaseMetadata.JapanIncidentRecordType,
              CaseMetadata.JapanLicensingRecordType,
              CaseMetadata.ProactiveCareRecordType,
              CaseMetadata.ProactiveCareRecordType,
              CaseMetadata.SalesOperationRecordType,
              CaseMetadata.ServiceIncidentRecordType,
              CaseMetadata.ServiceRequestRecordType
            }
          )
          .also(Case.ContactId)
          .hasValue()
      )
      .mapAll(new CaseContactChangeFunction(cases));
  }
}
