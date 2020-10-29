public without sharing class SalesCaseMetadata {
  public static final String TECHNOLOGY_ALLIANCE_AGREEMENT = 'Technology Alliance Agreement';
  public static final String SIGNED = 'Signed';
  public static final String NOT_SIGNED = 'Not Signed';

  private static final String LEGAL_PRODUCT_REQUEST = 'Legal_Product_Request';
  private static final String LEGAL_REQUEST = 'Legal_Request';
  private static final String UIPATH_JAPAN_PARTNER_STANDARD = 'UiPath_Japan_Partner_standard';

  public static Id getRecordTypeId(String developerName) {
    Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
    return recordTypeId;
  }

  public static Id LegalProductRequestRecordType {
    get {
      return getRecordTypeId(LEGAL_PRODUCT_REQUEST);
    }
    set;
  }

  public static Id LegalRequestRecordType {
    get {
      return getRecordTypeId(LEGAL_REQUEST);
    }
    set;
  }

  public static Id UiPathJapanPartnerStandardRecordType {
    get {
      return getRecordTypeId(UIPATH_JAPAN_PARTNER_STANDARD);
    }
    set;
  }
}
