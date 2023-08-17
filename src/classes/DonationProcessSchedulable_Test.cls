/**
* @description Unit test class for DonationProcessSchedulable
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
@isTest private class DonationProcessSchedulable_Test 
{
    @isTest private static void Main() 
    {
        Test.startTest();

        DonationProcessSchedulable donationProcessSchedule = new DonationProcessSchedulable();

        CronTrigger aCronTrigger = 
        [
            SELECT 
                Id, 
                CronExpression, 
                TimesTriggered, 
                NextFireTime 
            FROM CronTrigger 
            WHERE Id = :donationProcessSchedule.ScheduleID
        ];

        System.assertEquals('0 0 0 1 1 ? 2020', aCronTrigger.CronExpression); 
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
        
        Email_Settings__c emailSettings = new Email_Settings__c();
        emailSettings.Name= 'Donation Process Batch';
        emailSettings.To_Address__c='test@nubik.ca';
        emailSettings.Reply_To_Address__c='tets@nubik.ca';
        emailSettings.Sender_Display_Name__c='test Nubik';
        emailSettings.Subject__c='Test Batch';

        insert emailSettings;
    }
}