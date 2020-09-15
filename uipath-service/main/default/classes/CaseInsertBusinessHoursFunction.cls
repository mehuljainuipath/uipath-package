/**
 * TODO: To refactor
 */
public with sharing class CaseInsertBusinessHoursFunction implements SObjectToSObjectFunction {
    //Map to Store  Country With Their BusinessHours
    Map<String, Id> mapOfCounBH = new Map<String, Id>();

  public CaseInsertBusinessHoursFunction(List<Case> cases) {

    List<BusinessHours> lstOfBH = new List<BusinessHours>([SELECT Id, Name FROM BusinessHours WHERE IsActive = true]);
    System.debug('updateBusinessHours @35' + cases);

    //Putting value of BusinessHours in Map
    for (BusinessHours eachBH : lstOfBH) {
      mapOfCounBH.put(eachBH.Name, eachBH.Id);
    }
  }

  public SObject apply(Case eachCase) {
    if (eachCase.Priority == 'Urgent' || eachCase.Priority == 'High') {
      eachCase.BusinessHoursId = mapOfCounBH.get('DefaultBusinessHours');
    } else if (eachCase.Priority == 'Medium' || eachCase.Priority == 'Low' && (eachCase.Country__c != null)) {
      if (eachCase.Country__c == 'United States') {
        if (eachCase.Time_Zone__c != null) {
          if (
            eachCase.Time_Zone__c == 'GMT-05:00  Eastern Standard Time' ||
            eachCase.Time_Zone__c == 'GMT-04:00  Eastern Standard Time'
          ) {
            eachCase.BusinessHoursId = mapOfCounBH.get('US(EST) Business Hours(9hrs)');
          } else if (
            eachCase.Time_Zone__c == 'GMT-06:00  Central Standard Time' ||
            eachCase.Time_Zone__c == 'GMT-05:00  Central Standard Time'
          ) {
            eachCase.BusinessHoursId = mapOfCounBH.get('US(CST) Business Hours(9hrs)');
          } else if (
            eachCase.Time_Zone__c == 'GMT-08:00  Pacific Standard Time' ||
            eachCase.Time_Zone__c == 'GMT-07:00  Pacific Standard Time'
          ) {
            eachCase.BusinessHoursId = mapOfCounBH.get('US(PST) Business Hours(9hrs)');
          } else if (
            eachCase.Time_Zone__c == 'GMT-04:00  Atlantic Standard Time' ||
            eachCase.Time_Zone__c == 'GMT-05:00  Atlantic Standard Time'
          ) {
            eachCase.BusinessHoursId = mapOfCounBH.get('US(AST) Business Hours(9hrs)');
          } else {
            eachCase.BusinessHoursId = mapOfCounBH.get('US(CST) Business Hours(9hrs)');
          }
        } else {
          eachCase.BusinessHoursId = mapOfCounBH.get('US(CST) Business Hours(9hrs)');
        }
      } else if (mapOfCounBH.containsKey(eachCase.Country__c)) {
        eachCase.BusinessHoursId = mapOfCounBH.get(eachCase.Country__c);
      } else {
        //eachCase.addError('Country not found');
      }
    } else {
      //eachCase.addError('Country not found');
    }
    return eachCase;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void deriveBusinessHoursOnInsert(List<Case> records) {
    Collection.of(records).mapSome(Match.field(Case.Priority).hasValue(), new CaseInsertBusinessHoursFunction(records));
  }
}
