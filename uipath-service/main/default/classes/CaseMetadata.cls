public without sharing class CaseMetadata {
  public static final String CSM_ROLE = 'CSM';
  public static final String CTM_ROLE = 'Case Team Member';
  //Service Record Types
  public static final String ACADEMY = 'Academy';
  public static final String ENGAGEMENT_REQUEST = 'Engagement_Request';
  public static final String INCIDENT = 'Incident';
  public static final String JAPAN_ACADEMY = 'Japan_Academy';
  public static final String JAPAN_ENGAGEMENT_REQUEST = 'Japan_Engagement_Request';
  public static final String JAPAN_INCIDENT = 'Japan_Incident';
  public static final String JAPAN_LICENSING = 'Japan_Licensing';
  public static final String PROACTIVE_CARE = 'Proactive_Care';
  public static final String SALES_OPERATION = 'Sales_Operation';
  public static final String SERVICE_INCIDENT = 'Service_Incident';
  public static final String SERVICE_REQUEST = 'Service_Request';

  public static Id getRecordTypeId(String developerName) {
    Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
    return recordTypeId;
  }

  public static Id EngagementRequestRecordType {
    get {
      return getRecordTypeId(ENGAGEMENT_REQUEST);
    }
    set;
  }

  public static Id JapanEngagementRequestRecordType {
    get {
      return getRecordTypeId(JAPAN_ENGAGEMENT_REQUEST);
    }
    set;
  }

  public static Id AcademyRecordType {
    get {
      return getRecordTypeId(ACADEMY);
    }
    set;
  }

  public static Id ProactiveCareRecordType {
    get {
      return getRecordTypeId(PROACTIVE_CARE);
    }
    set;
  }
  public static Id IncidentRecordType {
    get {
      return getRecordTypeId(INCIDENT);
    }
    set;
  }

  public static Id JapanAcademyRecordType {
    get {
      return getRecordTypeId(JAPAN_ACADEMY);
    }
    set;
  }

  public static Id JapanIncidentRecordType {
    get {
      return getRecordTypeId(JAPAN_INCIDENT);
    }
    set;
  }

  public static Id JapanLicensingRecordType {
    get {
      return getRecordTypeId(JAPAN_LICENSING);
    }
    set;
  }

  public static Id SalesOperationRecordType {
    get {
      return getRecordTypeId(SALES_OPERATION);
    }
    set;
  }

  public static Id ServiceRequestRecordType {
    get {
      return getRecordTypeId(SERVICE_REQUEST);
    }
    set;
  }

  public static Id ServiceIncidentRecordType {
    get {
      return getRecordTypeId(SERVICE_INCIDENT);
    }
    set;
  }

  public static CPQ_Controls__mdt CPQControls {
    get {
      if (CPQControls == null) {
        CPQControls = [
          SELECT Id, Opp_CPQ_Record_Type_Developer_Name__c, Case_C_CaseTriggerHandler__c
          FROM CPQ_Controls__mdt
          LIMIT 1
        ];
      }
      return CPQControls;
    }
    set;
  }

  public static Map<String, Id> TeamRoleMap {
    get {
      if (TeamRoleMap == null) {
        TeamRoleMap = new Map<String, Id>();
        for (CaseTeamRole teamRole : [SELECT Id, Name FROM CaseTeamRole WHERE Name IN (:CSM_ROLE, :CTM_ROLE)]) {
          TeamRoleMap.put(teamRole.Name, teamRole.Id);
        }
      }
      return TeamRoleMap;
    }
    set;
  }
}
