/**
 * Responsibility: Account Domain Class
 * Mostly just delegates work to Mapped Functions or to Async Queueables
 */
public with sharing class Accounts extends fflib_SObjectDomain implements IAccounts {
  public static IAccounts newInstance(List<Account> recordList) {
    return (IAccounts) Application.Domain.newInstance(recordList);
  }

  public static IAccounts newInstance(Set<Id> recordIdSet) {
    return (IAccounts) Application.Domain.newInstance(recordIdSet);
  }

  public Accounts(List<Account> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
    AccountJapanConvertedLeadFunction.setGeoFields(Records);
    AccountBillingStateFromStateFunction.copyStateToBillingState(Records);
    AccountMapDnBAddressFunction.deriveAddressFieldsOnInsert(Records);
    AccountSetClassificationGlobalFunction.deriveRecordTypeOnInsert(Records);
    AccountSetClassificationFunction.deriveClassificationFieldsOnInsert(Records);
    AccountSetSubsidiaryFunction.deriveSubsidiaryOnInsert(Records);
    AccountSetRecordTypeFunction.deriveRecordTypeOnInsert(Records);
    AccountConvertAcademic.convertAcademicAccount(Records);
    AccountSetChannelTierFunction.deriveChannelTierOnInsert(Records);
    AccountSetDataStewardFunction.deriveDataStewardUserOnInsert(Records);
    AccountSetLegalEntityNameFunction.deriveLegalEntityNameOnInsert(Records);
    AccountSetStateFunction.deriveStateOnInsert(Records);
    AccountTerritoryService.deriveTerritoryFields(Records);
    AccountSetRegionSpecificTierFunction.deriveRegionSpecificFieldsOnInsert(Records);
    AccountCopyCountryFunction.copyCountryOnInsert(Records);
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    AccountSetStateFunction.deriveStateOnUpdate(Records, existingRecords);
    AccountMapDnBAddressFunction.deriveAddressFieldsOnUpdate(Records, existingRecords);
    AccountSetClassificationGlobalFunction.deriveRecordTypeOnUpdate(Records, existingRecords);
    AccountOverwriteRevenueEmpFunction.deriveRecordTypeOnUpdate(Records, existingRecords);
    AccountSetClassificationFunction.deriveClassificationFieldsOnUpdate(Records, existingRecords);
    // 11/4/2020 Roxana A. deactivated run of AccountSetRecordTypeFunction on before update
    // It was causing lead conversion problems, and unnecessarily updated account record type
    //AccountSetRecordTypeFunction.deriveRecordTypeForExistingAccount(Records, existingRecords);
    AccountConvertAcademic.convertAcademicAccountOnUpdate(Records, existingRecords);
    AccountSetDataStewardFunction.deriveDataStewardUserOnUpdate(Records, existingRecords);
    AccountSetSyncStatusFunction.deriveSyncStatusForValidatedAccount(Records, existingRecords);
    AccountTerritoryService.deriveTerritoryFieldsOnUpdate(Records, existingRecords);
    AccountSetRegionSpecificTierFunction.deriveRegionSpecificFieldsOnUpdate(Records, existingRecords);
    //Leave this as the last method in the execution of onBeforeUpdate
    IntegrationHandler.callAccountSyncStatusIntegrationProcess(Records, existingRecords);
  }

  public override void onAfterInsert() {
    //Update contact LeadSource for all Japan converted Leads
    AbstractQueueable.enqueue(new AccountUpdateJapanContactQueueable(Records));
    //For global accounts, grant Opp and Contact Edit access to Top level account owner
    AbstractQueueable.enqueue(new AccountSharingRollupQueueable(Records, null));
    //Insert address record copying from Account. Also set that as Primary Shipping and Billing for the account
    AbstractQueueable.enqueue(new AccountAddressQueueable(Records, null));
    AbstractQueueable.enqueue(new AccountSetGAMEmailQueueable(Records, null));
    AccountDnBSyncQueueable.deriveDnBFieldsOnInsert(Records);
    AccountSharingLeadOwnerQueueable.shareAccount(Records);
    AccountSetCompanyTierQueueable.setUpCompanyTierInsert(Records);
    AccountIntegrationService.publishInsertsToNetsuite(Records);
    AccountIntegrationService.publishInsertsToRDC(Records);
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    AccountSharingRollupQueueable.shareAccountWithParentOwner(Records, existingRecords);
    AccountDNBPrimaryAddressQueueable.updateAddressForDnBCompany(Records, existingRecords);
    AccountDNBCompanyQueueable.createAddressForDnBCompany(Records, existingRecords);
    AccountSetContactOwnerQueueable.setContactOwnerToAccountOwner(Records, existingRecords);
    AccountSetGAMEmailQueueable.setGAMEmailOnGlobalAccounts(Records, existingRecords);
    AccountDnBSyncQueueable.deriveDnBFieldsOnUpdate(Records, existingRecords);
    ZinfiSyncContactWithAccount.zinfiSyncAccountOnUpdate(existingRecords);
    LicensingApiDispatch.licensingApiSyncAccountOnUpdate(Records, existingRecords);
    AccountClassificationGlobalQueueable.setClassificationToGlobal(Records, existingRecords);
    AccountSharingLeadOwnerQueueable.shareAccountOnUpdate(Records, existingRecords);
    AccountSetCompanyTierQueueable.setUpCompanyTierUpdate(Records, existingRecords);
    AccountIntegrationService.publishUpdatesToNetsuite(Records, existingRecords);
  }

  public override void onAfterDelete() {
    ZinfiSyncOnline.zinfiSyncAccountOnDelete(Records);
    LicensingApiDispatch.licensingApiSyncAccountOnDelete(Records);
  }

  /**
   * Validates accounts inserted or Updated
   */
  public override void onValidate() {
    Collection.of(Records).mapAll(new AccountValidationFunction(null, this));
  }

  /**
   * Validates accounts that are updated
   * @param existingRecords updated Records
   */
  public override void onValidate(Map<Id, SObject> existingRecords) {
    Collection.of(Records).mapAll(new AccountValidationFunction(existingRecords, this));
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Accounts(sObjectList);
    }
  }
}
