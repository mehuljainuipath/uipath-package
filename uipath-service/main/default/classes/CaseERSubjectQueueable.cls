public without sharing class CaseERSubjectQueueable extends AbstractQueueable {
  private final List<SObject> cases;
  public CaseERSubjectQueueable(List<SObject> cases) {
    super('CaseERSubjectQueueable');
    this.cases = cases;
  }

  public override void work() {
    this.updateCaseSubject(cases);
  }

  private void updateCaseSubject(List<Case> cases) {
    List<Case> casesToUpdate = new List<Case>();
    for (Case record : cases) {
      if (record.Subject != null && record.Subject.contains(CaseMetadata.CASE_NUMBER)) {
        record.Subject = record.Subject.replace(CaseMetadata.CASE_NUMBER, record.CaseNumber);
        casesToUpdate.add(record);
      }
    }
    if (!casesToUpdate.isEmpty()) {
      fflib_SObjectDomain.getTriggerEvent(Cases.class).disableAll();
      update casesToUpdate;
      fflib_SObjectDomain.getTriggerEvent(Cases.class).enableAll();
    }
  }

  public static void setCaseNumberOnSubject(List<SObject> cases) {
    List<Case> eligibleCases = (List<Case>) Collection.of(cases)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(
            new Set<String>{ CaseMetadata.EngagementRequestRecordType, CaseMetadata.JapanEngagementRequestRecordType }
          )
          .also(Case.Subject)
          .hasValue()
      )
      .asList();

    if (!eligibleCases.isEmpty()) {
      AbstractQueueable.enqueue(new CaseERSubjectQueueable(eligibleCases));
    }
  }
}
