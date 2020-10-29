/**
 */
public with sharing class SalesCaseBillToWOppQueueable extends AbstractQueueable {
  private final List<SObject> cases;

  public SalesCaseBillToWOppQueueable(List<SObject> cases) {
    super('SalesCaseBillToWOppQueueable');
    this.cases = cases;
  }

  public override void work() {
    this.updateBillTo(this.cases);
  }

  private void updateBillTo(List<Case> cases) {
    List<Case> casesToUpdate = [SELECT AccountId, Opportunity__r.Sold_to_Partner__c FROM Case WHERE Id IN :cases];

    for (Case caseRecord : casesToUpdate) {
      if (Opportunity__r.Sold_to_Partner__c != null) {
        Bill_To__c = Opportunity__r.Sold_to_Partner__c;
      } else {
        Bill_To__c = AccountId;
      }
    }

    if (!casesToUpdate.isEmpty()) {
      update casesToUpdate;
    }
  }

  public static void updateBillToOnUpdate(List<Case> cases, Map<Id, SObject> existingCases) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Case.AccountId, Case.Opportunity__c },
      cases,
      existingCases
    );

    List<Case> eligibleCases = (List<Case>) Collection.of(cases)
      .filter(hasChanged)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(new Set<String>{ SalesCaseMetadata.LegalRequestRecordType, SalesCaseMetadata.UiPathJapanPartnerStandardRecordType })
          .also(Case.Document_Type__c)
          .equals(SalesCaseMetadata.TECHNOLOGY_ALLIANCE_AGREEMENT)
      )
      .filter(
        Match.field(Case.Status)
          .isIn(new Set<String>{ SalesCaseMetadata.SIGNED, SalesCaseMetadata.NOT_SIGNED })
          .also(Case.AccountId)
          .hasValue()
      )
      .asList();

    if (!eligibleCases.isEmpty()) {
      AbstractQueueable.enqueue(new SalesCaseBillToWOppQueueable(eligibleCases));
    }
  }
}
