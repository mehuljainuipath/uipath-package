trigger TestSupportObjectTrigger on TestSupportObject__c (
after delete, after insert, after update, before delete, before insert, before update)
{
// Creates Domain class instance and calls appropriate overridable methods according to Trigger state
fflib_SObjectDomain.triggerHandler(TestSupportObject.class);
}
