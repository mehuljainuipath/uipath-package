trigger SalesCases on Case(before insert, before update, after update) {
  // Creates Domain class instance and calls appropriate overridable methods according to Trigger state
  fflib_SObjectDomain.triggerHandler(SalesCases.class);
}