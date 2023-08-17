/**
* @description Unit test class for DonationProcessSchedulableUI
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
@isTest private class DonationProcessSchedulableUI_Test 
{
	@isTest private static void Main() 
	{
		Test.startTest();

		string cronExpression = '0 0 0 1 1 ? 2020';
		string scheduleId     = System.schedule('ScheduleTest', cronExpression, new DonationProcessSchedulableUI());

		CronTrigger aCronTrigger = 
		[
			SELECT 
				Id, 
				CronExpression, 
				TimesTriggered, 
				NextFireTime 
			FROM CronTrigger 
			WHERE Id = :scheduleId
		];

        System.assertEquals(cronExpression, aCronTrigger.CronExpression); 
        System.assertEquals(0, aCronTrigger.TimesTriggered);
        System.assertEquals('2020-01-01 00:00:00', String.valueOf(aCronTrigger.NextFireTime));

		Test.stopTest();
	}

	@TestSetup private static void Setup()
	{
		Schedule_Settings__c scheduleSettings = new Schedule_Settings__c();
		scheduleSettings.Name             = 'DonationProcessSchedule';
		scheduleSettings.Schedule_Name__c = 'Test Schedule';
		scheduleSettings.Seconds__c       = '0';
		scheduleSettings.Minutes__c       = '0';
		scheduleSettings.Hours__c         = '0';
		scheduleSettings.Day_of_Month__c  = '1';
		scheduleSettings.Month__c         = '1';
		scheduleSettings.Day_of_Week__c   = '?';
		scheduleSettings.Year__c          = '2020';

		insert scheduleSettings;
	}
}