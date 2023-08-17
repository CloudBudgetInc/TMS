trigger FrameworkTrigger on Trigger_Framework_Settings__c (
    before insert, before update, before delete, 
  	after insert, after update, 
  	after delete, after undelete) {
    	new FrameworkTriggerHandler().run();
}