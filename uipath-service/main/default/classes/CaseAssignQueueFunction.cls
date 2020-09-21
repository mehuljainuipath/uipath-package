public with sharing class CaseAssignQueueFunction implements SObjectToSObjectFunction {
  public CaseAssignQueueFunction() {
  }

  public SObject apply(Case newCase) {
    if (newCase.Origin == 'Community') {
      if (newCase.RecordTypeId == CaseMetadata.IncidentRecordType) {
        if (newCase.Related_To__c == 'Studio') {
          newCase.OwnerId = CaseMetadata.QueueNameToIdMap.get('Studio_Queue');
        } else if (CaseMetadata.SupportedProducts.contains(newCase.Related_To__c)) {
          newCase.OwnerId = CaseMetadata.QueueNameToIdMap.get('Product_Support_Queue');
        } else if (newCase.Related_To__c == 'Orchestrator') {
          newCase.OwnerId = CaseMetadata.QueueNameToIdMap.get('Orchestrator_Queue');
        } else if (newCase.Related_To__c == 'Robot') {
          newCase.OwnerId = CaseMetadata.QueueNameToIdMap.get('Robot_Queue');
        } else if (newCase.Related_To__c == 'Partner Product') {
          newCase.OwnerId = CaseMetadata.QueueNameToIdMap.get('Partner_Product');
        }
      } else if (
        newCase.RecordTypeId == CaseMetadata.JapanIncidentRecordType &&
        newCase.Case_Web_Form_Region__c == 'Japan'
      ) {
        if (newCase.Related_To__c == 'Studio') {
          newCase.OwnerId = CaseMetadata.QueueNameToIdMap.get('Japan_Studio_Queue');
        } else if (CaseMetadata.SupportedProducts.contains(newCase.Related_To__c)) {
          newCase.OwnerId = CaseMetadata.QueueNameToIdMap.get('Japan_Product_Support_Queue');
        } else if (newCase.Related_To__c == 'Orchestrator') {
          newCase.OwnerId = CaseMetadata.QueueNameToIdMap.get('Japan_Orchestrator_Queue');
        } else if (newCase.Related_To__c == 'Robot') {
          newCase.OwnerId = CaseMetadata.QueueNameToIdMap.get('Japan_Robot_Queue');
        } else if (newCase.Related_To__c == 'Partner Product') {
          newCase.OwnerId = CaseMetadata.QueueNameToIdMap.get('Japan_Partner_Product');
        } else if (newCase.Related_To__c == 'Academy') {
          newCase.RecordTypeId = CaseMetadata.JapanAcademyRecordType;
          newCase.OwnerId = CaseMetadata.QueueNameToIdMap.get('Japan_Academy_Queue');
        } else if (newCase.Related_To__c == 'Cloud Platform') {
          newCase.RecordTypeId = CaseMetadata.JapanLicensingRecordType;
          newCase.OwnerId = CaseMetadata.QueueNameToIdMap.get('Japan_Licensing_Queue');
        }
      } else if (newCase.RecordTypeId == CaseMetadata.JapanEngagementRequestRecordType) {
        newCase.OwnerId = CaseMetadata.QueueNameToIdMap.get('ER_Queue');
      }
    } else if (newCase.Origin == null) {
      newCase.Origin = CaseMetadata.ORIGIN_INTERNAL;
    }
    return newCase;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void deriveOwners(List<SObject> cases) {
    Collection.of(cases)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(
            new Set<String>{
              CaseMetadata.IncidentRecordType,
              CaseMetadata.JapanIncidentRecordType,
              CaseMetadata.JapanEngagementRequestRecordType
            }
          )
      )
      .mapAll(new CaseAssignQueueFunction());
  }
}
