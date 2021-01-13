/**
 * TODO REWRITE
 * Move to Service Layer
 * this code was just moved here from the sync Trigger context into a Queueable Context.
 * Needs to be rewritten entirely
 * Updates the Completion date on CaseMilestone for First Response cases
 */
public without sharing class CaseFirstResponseQueueable extends AbstractQueueable {
  private final List<Id> recordIds;
  private final Datetime currentTime;
  @TestVisible
  private static Boolean isAlreadyRun = false;

  public CaseFirstResponseQueueable(List<Id> recordIds, Datetime currentTime) {
    super('CaseFirstResponseQueueable');
    this.recordIds = recordIds;
    this.currentTime = currentTime;
  }

  public override void work() {
    this.updateMilestones(this.recordIds, this.currentTime);
  }

  private void updateMilestones(List<Id> recordIds, Datetime dateNow) {
    List<CaseMilestone> milestoneList = new List<CaseMilestone>();
    for (CaseMilestone milestone : [
      SELECT Id, CompletionDate
      FROM CaseMilestone
      WHERE
        CaseId IN :recordIds
        AND MilestoneType.Name = 'First Response'
        AND IsCompleted = false
        AND CompletionDate = null
      FOR UPDATE
    ]) {
      milestone.CompletionDate = dateNow;
      milestoneList.add(milestone);
    }
    update milestoneList;
  }

  public static void setCompletionDateOnMilestones(List<SObject> cases, Map<Id, SObject> existingCases) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Case.No_of_Emails_Sent__c },
      cases,
      existingCases
    );

    List<Case> eligibleCases = (List<Case>) Collection.of(cases)
      .filter(hasChanged)
      .filter(Match.field(Case.No_of_Emails_Sent__c).equals(2))
      .asList();

    if (!eligibleCases.isEmpty()) {
      if (!isAlreadyRun) {
        isAlreadyRun = true;
        List<Id> recordIds = Collection.of(cases).pluckIds();
        AbstractQueueable.enqueue(new CaseFirstResponseQueueable(recordIds, System.now()));
        //updateMilestones(new Set<Id>(recordIds));
      }
    }
  }
}
