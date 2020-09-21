public with sharing class CasePopulateEntitlementFunction implements SObjectToSObjectFunction {
  public SObject apply(Case caseRecord) {
    caseRecord.Ischanged_Support_Type__c = false;
    if (caseRecord.RecordtypeId == CaseMetadata.SalesOperationRecordType) {
      caseRecord.EntitlementId = CaseMetadata.EntitlementMap.get(Label.SalesOperationEntitlementName);
    } else if (caseRecord.RecordtypeId == CaseMetadata.AcademyRecordType) {
      caseRecord.EntitlementId = CaseMetadata.EntitlementMap.get(Label.AcademyEntitlementName);
    } else if (
      caseRecord.RecordtypeId == CaseMetadata.JapanLicensingRecordType ||
      caseRecord.RecordtypeId == CaseMetadata.JapanAcademyRecordType ||
      (caseRecord.RecordtypeId == CaseMetadata.JapanIncidentRecordType &&
      caseRecord.Case_Web_Form_Region__c == 'Japan') ||
      (caseRecord.RecordtypeId == CaseMetadata.ServiceRequestRecordType &&
      caseRecord.Case_Web_Form_Region__c == 'Japan')
    ) {
      if (caseRecord.Case_Web_Form_Region__c == 'Japan') {
        if ((caseRecord.AccountId == null || caseRecord.Account_Type__c == 'Standard')) {
          caseRecord.EntitlementId = CaseMetadata.EntitlementMap.get(Label.JapanStandardEntitlementName);
        } else if (caseRecord.Account_Type__c == 'Enterprise') {
          caseRecord.EntitlementId = CaseMetadata.EntitlementMap.get(Label.JapanEnterpriseEntitlementName);
        } else if (caseRecord.Account_Type__c == 'Premium') {
          caseRecord.EntitlementId = CaseMetadata.EntitlementMap.get(Label.JapanPremiumEntitlementName);
        }
      }
    } else if (
      caseRecord.RecordtypeId == CaseMetadata.IncidentRecordType ||
      caseRecord.RecordtypeId == CaseMetadata.ServiceRequestRecordType
    ) {
      if (caseRecord.AccountId == null || caseRecord.Account_Type__c == 'Standard') {
        caseRecord.EntitlementId = CaseMetadata.EntitlementMap.get(Label.Standard_Account_Entitlement);
      } else if (caseRecord.Account_Type__c == 'Enterprise') {
        caseRecord.EntitlementId = CaseMetadata.EntitlementMap.get(Label.Enterprise_Account_Entitlement);
      } else if (caseRecord.Account_Type__c == 'Premium') {
        caseRecord.EntitlementId = CaseMetadata.EntitlementMap.get(Label.Premium_Account_Entitlement);
      } else if (caseRecord.Account_Type__c == 'Premium Plus') {
        caseRecord.EntitlementId = CaseMetadata.EntitlementMap.get(Label.PremiumPlus_Account_Entitlement);
      }
    }
    return caseRecord;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void deriveEntityBasedOnAccountType(List<SObject> cases) {
    Collection.of(cases)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(
            new Set<String>{
              CaseMetadata.AcademyRecordType,
              CaseMetadata.IncidentRecordType,
              CaseMetadata.JapanAcademyRecordType,
              CaseMetadata.JapanIncidentRecordType,
              CaseMetadata.JapanLicensingRecordType,
              CaseMetadata.SalesOperationRecordType,
              CaseMetadata.ServiceRequestRecordType,
              CaseMetadata.ServiceIncidentRecordType
            }
          )
      )
      .mapAll(new CasePopulateEntitlementFunction());
  }

  public static void deriveEntityBasedOnAccountType(List<SObject> cases, Map<Id, SObject> existingCases) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Case.Ischanged_Support_Type__c, Case.AccountId, Case.RecordTypeId },
      cases,
      existingCases
    );
    Collection.of(cases)
      .filter(hasChanged)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(
            new Set<String>{
              CaseMetadata.AcademyRecordType,
              CaseMetadata.IncidentRecordType,
              CaseMetadata.JapanAcademyRecordType,
              CaseMetadata.JapanIncidentRecordType,
              CaseMetadata.JapanLicensingRecordType,
              CaseMetadata.SalesOperationRecordType,
              CaseMetadata.ServiceRequestRecordType,
              CaseMetadata.ServiceIncidentRecordType
            }
          )
          .also(Case.Ischanged_Support_Type__c)
          .hasValue()
          .also(Case.Ischanged_Support_Type__c)
          .equals(true)
      )
      .mapAll(new CasePopulateEntitlementFunction());
  }
}
