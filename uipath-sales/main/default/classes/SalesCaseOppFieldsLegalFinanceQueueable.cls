/**
 * TODO REWRITE
 * Move to Service Layer
 * this code was just moved here from the sync Trigger context into a Queueable Context.
 * Needs to be rewritten entirely
 */

public with sharing class SalesCaseOppFieldsLegalFinanceQueueable extends AbstractQueueable {
  private final List<SObject> cases;
  private final Map<Id, SObject> oldCasessMap;

  public SalesCaseOppFieldsLegalFinanceQueueable(List<SObject> cases, Map<Id, SObject> oldCasessMap) {
    super('SalesCaseOppFieldsLegalFinanceQueueable');
    this.cases = cases;
    this.oldCasessMap = oldCasessMap;
  }

  public override void work() {
    this.setOpptyFieldsFromLegalAndFinanceCase(cases, oldCasessMap);
  }

  private void setOpptyFieldsFromLegalAndFinanceCase(List<SObject> cases, Map<Id, SObject> oldMap) {
    
    /** CPQ Controls **/
    Id cpqRtId = null;
    CPQ_Controls__mdt cpqControls = null;
    try {
      cpqControls = [
        SELECT Id, Opp_CPQ_Record_Type_Developer_Name__c, Case_C_CaseTriggerHandler__c
        FROM CPQ_Controls__mdt
        LIMIT 1
      ];

      if (
        Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
          .get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c)
          .getRecordTypeId() != null
      ) {
        cpqRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
          .get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c)
          .getRecordTypeId();
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'Metadata and system have not been correctly configured for CPQ operation');
    }
    /** **/

    List<Case> legalCases = new List<Case>();
    List<Case> financeCases = new List<Case>();
    List<Case> CPQFinanceCases = new List<Case>();
    Set<Id> opportunityIds = new Set<Id>();

    for (SObject updatedCase : cases) {
      if (updatedCase.Opportunity__c != null) {
        opportunityIds.add(updatedCase.Opportunity__c);
      }
    }

    Map<Id, Opportunity> opportunityMap = new Map<ID, Opportunity>(
      [
        SELECT
          Id,
          StageName,
          Payment_Cycle__c,
          Termination_Clause__c,
          Contract_Start_Date__c,
          Contract_End_Date__c,
          Account.BillingCountry,
          RecordTypeId
        FROM Opportunity
        WHERE Id IN :opportunityIds
      ]
    );

    for (Case updatedCase : cases) {
      Opportunity opp = null;
      opp = opportunityMap.get(updatedCase.Opportunity__c);

      if (
        updatedCase.RecordTypeId == SalesCaseMetadata.LegalRequestRecordType &&
        updatedCase.Status == 'Signed' &&
        oldMap.get(updatedCase.Id).Status != 'Signed'
      ) {
        legalCases.add(updatedCase);
      }

      //Finance Case - standard processing branch
      if (
        updatedCase.RecordTypeId == SalesCaseMetadata.FinanceRequestRecordType &&
        updatedCase.Status == 'Finance Review' &&
        oldMap.get(updatedCase.Id).Status != 'Finance Review'
      ) {
        System.debug('^^^ Fin case branch - non CPQ');
        financeCases.add(updatedCase);
      }

      //Finance Case - CPQ additional processing
      if (
        updatedCase.RecordTypeId == SalesCaseMetadata.FinanceRequestRecordType &&
        cpqRtId != null &&
        opp != null &&
        opp.RecordTypeId == cpqRtId &&
        ((updatedCase.Status == 'Invoiced and delivered' &&
        oldMap.get(updatedCase.Id).Status != 'Invoiced and delivered') ||
        (updatedCase.Status == 'Invoiced and batch delivery' &&
        oldMap.get(updatedCase.Id).Status != 'Invoiced and batch delivery'))
      ) {
        System.debug('^^^ Fin case branch - CPQ');
        CPQFinanceCases.add(updatedCase);
      }

      //if CPQ-opp related cases have been processed, delegate their handling to utility
      //Bharti- adding a check to run below code only if order integration custom setting is off.
      if (!isOrderIntegrationFeatureOn() && CPQFinanceCases.size() > 0) {
        CaseCPQUtility.handleCPQRelatedCases(CPQFinanceCases, opportunityMap);
      }

      List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

      for (Case legalCase : legalCases) {
        Opportunity caseOpportunity = null;
        caseOpportunity = opportunityMap.get(legalCase.Opportunity__c);
        //CPQ control
        if (
          caseOpportunity != null &&
          (cpqRtId == null ||
          caseOpportunity.RecordTypeId != cpqRtId ||
          (cpqControls != null && cpqControls.Case_C_CaseTriggerHandler__c))
        ) {
          //   if(caseOpportunity.Account.BillingCountry != 'Japan' && caseOpportunity.StageName != 'Closed Won Booked'){
          if (caseOpportunity.StageName != 'Closed Won Booked') {
            caseOpportunity.Payment_Cycle__c = legalCase.Payment_Cycle__c;
            caseOpportunity.Termination_Clause__c = legalCase.Termination_Clause__c;
            caseOpportunity.Contract_Start_Date__c = legalCase.Contract_Start_Date__c;
            caseOpportunity.Contract_End_Date__c = legalCase.Contract_End_Date__c;
            opportunitiesToUpdate.add(caseOpportunity);
          }
        }
      }

      for (Case financeCase : financeCases) {
        Opportunity caseOpportunity = null;
        caseOpportunity = opportunityMap.get(financeCase.Opportunity__c);

        //CPQ control
        if (
          caseOpportunity != null &&
          (cpqRtId == null ||
          caseOpportunity.RecordTypeId != cpqRtId ||
          (cpqControls != null && cpqControls.Case_C_CaseTriggerHandler__c))
        ) {

          // if(caseOpportunity.Account.BillingCountry != 'Japan' && caseOpportunity.StageName != 'Closed Won Booked'){
          if (caseOpportunity.StageName != 'Closed Won Booked') {
            caseOpportunity.Payment_Cycle__c = financeCase.Payment_Cycle__c;
            caseOpportunity.Termination_Clause__c = financeCase.Termination_Clause__c;
            caseOpportunity.Contract_Start_Date__c = financeCase.Contract_Start_Date__c;
            caseOpportunity.Contract_End_Date__c = financeCase.Contract_End_Date__c;
            caseOpportunity.FinanceReviewReached__c = true;
            caseOpportunity.StageName = 'Closed Won Booked';
            opportunitiesToUpdate.add(caseOpportunity);
          }
        }
      }
      System.debug('^^^:' + opportunitiesToUpdate);
      update opportunitiesToUpdate;
    }
  }
}
