/**
 * TODO: To refactor
 */
public with sharing class CaseShowErrodOnOpenERFunction implements SObjectToSObjectFunction {
  Map<Id, List<String>> parentCaseIdChieldStats = new Map<Id, List<String>>();
  List<Case> erCases = new List<Case>();

  public CaseShowErrodOnOpenERFunction(List<Case> cases) {
    //Updated by dharani 19-10-2018 removed// status != 'Closed'
    erCases = [
      SELECT id, ParentId, Status, RecordTypeId
      FROM case
      WHERE
        ParentId IN :cases
        AND (RecordTypeId = :CaseMetadata.EngagementRequestRecordType
        OR RecordTypeId = :CaseMetadata.JapanEngagementRequestRecordType)
        AND status NOT IN ('Closed', 'Pending from Engineering')
    ]; //recordtype calling modified by deepali

    system.debug('erCases------------' + erCases);
    for (Case c : erCases) {
      if (parentCaseIdChieldStats.containsKey(c.ParentId)) {
        parentCaseIdChieldStats.get(c.ParentId).add(c.Status);
      } else
        parentCaseIdChieldStats.put(c.ParentId, new List<String>{ c.Status });
    }
  }

  public SObject apply(Case eachCase) {
    if (parentCaseIdChieldStats.containsKey(eachCase.id)) {
      if (eachCase.Status == 'Closed') {
        eachCase.addError('There is an Open Engagement Request for this Ticket. Please close the ER first.');
      }
    }
    return eachCase;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void deriveShowErrodOnOpenEROnUpdate(List<Case> records) {
    Collection.of(records)
      .mapSome(Match.field(Case.Status).equals('Closed'), new CaseShowErrodOnOpenERFunction(records));
  }
}
