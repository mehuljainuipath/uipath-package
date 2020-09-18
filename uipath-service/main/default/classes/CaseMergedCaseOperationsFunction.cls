/**
 * TODO: To refactor
 */
public with sharing class CaseMergedCaseOperationsFunction implements SObjectToSObjectFunction {
  Set<Id> mergedCaseIdSet = new Set<Id>();

  public CaseMergedCaseOperationsFunction(List<Case> cases) {
    for (case caseObj : cases) {
      if (
        (caseObj.status == system.label.MergedCaseStatus) &&
        caseObj.RecordTypeId == CaseMetadata.IncidentRecordType &&
        !system.isFuture() &&
        !system.isBatch()
      ) {
        mergedCaseIdSet.add(caseObj.Id);
        caseObj.EntitlementId = null;
      }
    }

    if (null != mergedCaseIdSet && mergedCaseIdSet.size() > 0) {
      mergeCaseFutureHandler(mergedCaseIdSet);
    }
  }

  public SObject apply(Case eachCase) {
    return eachCase;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  @future
  public static void mergeCaseFutureHandler(Set<Id> mergedCaseIdSet) {
    final String matchPattern = 'has been merged with Case';
    final String mergedTemplateName = 'Case Close EmailTemplate for MergedCase';

    try {
      List<String> splitString;
      Map<Id, Case> caseWithCaseCommentMap = new Map<Id, Case>();
      for (CaseComment casecomObj : [
        SELECT Id, ParentId, Parent.contactId, CommentBody
        FROM CaseComment
        WHERE ParentId IN :mergedCaseIdSet
      ]) {
        splitString = new List<String>();
        if (casecomObj.CommentBody.contains(matchPattern))
          splitString = casecomObj.CommentBody.split('Case');
        if (!test.isRunningTest()) {
          case caseSingleObj = new case();
          caseSingleObj.Id = casecomObj.ParentId;
          caseSingleObj.Merged_To_Case_Number__c = splitString[2] != null ? splitString[2].trim() : '';
          caseSingleObj.contactId = casecomObj.Parent.contactId;
          caseWithCaseCommentMap.put(caseSingleObj.Id, caseSingleObj);
        }
      }

      if (null != caseWithCaseCommentMap && caseWithCaseCommentMap.size() > 0)
        update caseWithCaseCommentMap.values();

      OrgWideEmailAddress owa = [
        SELECT id, DisplayName, Address
        FROM OrgWideEmailAddress
        WHERE Address = 'uipathsupport@uipath.com'
      ];
      EmailTemplate templateId = [SELECT id, subject, htmlvalue FROM EmailTemplate WHERE name = :mergedTemplateName];
      List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();

      for (Id caseObjId : caseWithCaseCommentMap.keyset()) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setTemplateID(templateId.Id);
        mail.setSaveAsActivity(false);

        mail.setWhatId(caseObjId); // This is the record I
        mail.setTargetObjectId(caseWithCaseCommentMap.get(caseObjId).contactId);
        mail.setOrgWideEmailAddressId(owa.id);
        allmsg.add(mail);
      }

      Messaging.sendEmail(allmsg, false);
    } catch (Exception e) {
      throw new IllegalArgumentException(e.getMessage());
    }
  }

  public static void deriveMergedCaseOperationsOnUpdate(List<SObject> cases, Map<Id, SObject> existingCases) {

    Collection.of(cases).mapAll(new CaseMergedCaseOperationsFunction(cases));
  }
}
