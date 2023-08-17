trigger BatchTrigger on npsp__Batch__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) 
{
	Trigger_Settings__c settings = Trigger_Settings__c.getInstance();

	if (settings != null && settings.Batch_Trigger_Enabled__c != null && settings.Batch_Trigger_Enabled__c == true)
	{
		System.debug('### Running BatchTrigger!');
		trigger_Controller.getInstance().process(npsp__Batch__c.sObjectType);
	}
}