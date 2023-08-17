/**
* @description Unit test class for Nubik_ScheduleSettings
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
@isTest private class Nubik_ScheduleSettings_Test 
{
	@isTest private static void Main() 
	{
		Schedule_Settings__c hammerTimeSchedule = Schedule_Settings__c.getValues('STOP');

		Nubik_ScheduleSettings scheduleSettings = new Nubik_ScheduleSettings(hammerTimeSchedule);
	}

	@TestSetup private static void Setup() 
	{
		Schedule_Settings__c scheduleSettings = new Schedule_Settings__c();
		scheduleSettings.Name             = 'STOP';
		scheduleSettings.Schedule_Name__c = 'HammerTime';
		scheduleSettings.Seconds__c       = '0';
		scheduleSettings.Minutes__c       = '0';
		scheduleSettings.Hours__c         = '5';
		scheduleSettings.Day_of_Month__c  = '*';
		scheduleSettings.Month__c         = '*';
		scheduleSettings.Day_of_Week__c   = '*';
		scheduleSettings.Year__c          = '*';

		insert scheduleSettings;
	}
}