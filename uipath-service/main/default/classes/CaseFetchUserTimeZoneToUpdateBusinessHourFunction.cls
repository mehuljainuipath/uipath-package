/**
 * TODO: To refactor
 */
public with sharing class CaseFetchUserTimeZoneToUpdateBusinessHourFunction implements SObjectToSObjectFunction {
  Set<Id> ownerIdSet = new Set<Id>();
  Set<Id> bsnsHrIdSet = new Set<Id>();
  Set<Id> caseownerIdSet = new Set<Id>();
  Set<String> timeZnSet = new Set<String>();
  Map<String, Id> tmZnToBusnssHrMapping = new Map<String, Id>();
  Map<Id, String> caseIdtoUserTimeZoneMap = new Map<Id, String>();
  Map<Id, User> caseOwnerWithTimeZone;
  List<Case> caseToUpdateList = new List<Case>();
  Map<Id, BusinessHours> orgBusnssHrsMap;
  Map<Id, Case> caseWithBusnssHrMap;

  public CaseFetchUserTimeZoneToUpdateBusinessHourFunction(List<Case> cases) {
    caseWithBusnssHrMap = new Map<Id, Case>(
      [
        SELECT Id, BusinessHoursId, BusinessHours.TimeZoneSidKey, Owner.Type, OwnerId, RecordtypeId
        FROM Case
        WHERE Id IN :cases
      ]
    );

    BusinessHours IncidentDefaultBusinessHours = new BusinessHours();
    Map<String, BusinessHours> mapOfNametoBusinessHours = new Map<String, BusinessHours>();
    for (BusinessHours it : [
      SELECT Id, NAme, TimeZoneSidKey
      FROM BusinessHours
      WHERE IsActive = true
      ORDER BY MondayStartTime
    ]) {
      if (it.Name == 'IST 24X7 Business Hours') {
        IncidentDefaultBusinessHours = it;
      }
      mapOfNametoBusinessHours.put(it.name, it);
    }
    system.debug('mapOfNametoBusinessHours' + mapOfNametoBusinessHours);
  }

  public SObject apply(Case eachCase) {
    if (!mapOfNametoBusinessHours.isEmpty()) {
      if (eachCase.time_zone__c != null && mapOfNametoBusinessHours.get(eachCase.Time_Zone__c) != null) {
        eachCase.BusinessHoursId = mapOfNametoBusinessHours.get(eachCase.Time_Zone__c).Id;
      }
    }
    return eachCase;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void deriveFetchUserTimeZoneToUpdateBusinessHourOnInsert(List<SObject> cases) {
    Collection.of(cases)
      .mapSome(
        Match.field(Case.RecordTypeId)
          .isIn(
            new Set<String>{
              CaseMetadata.IncidentRecordType,
              CaseMetadata.ServiceRequestRecordType,
              CaseMetadata.AcademyRecordType,
              CaseMetadata.JapanLicensingRecordType,
              CaseMetadata.SalesOperationRecordType,
              CaseMetadata.JapanAcademyRecordType,
              CaseMetadata.JapanIncidentRecordType
            }
          ),
        new CaseFetchUserTimeZoneToUpdateBusinessHourFunction(cases)
      );
  }
}
