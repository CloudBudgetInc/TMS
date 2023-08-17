/**
* @description Unit test class for DonationProcessBatchable
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
@isTest private class DonationProcessBatchable_Test 
{
	@isTest private static void Main() 
	{
		//CPTransactionDefaults
		//CnP_PaaS__CnP_Transaction__c cnpTransaction = (CnP_PaaS__CnP_Transaction__c) TestFactory.createSObject(new CnP_PaaS__CnP_Transaction__c(), 'TestFactory.CPTransactionDefaults', true);
		//System.debug(cnpTransaction);
		List<Opportunity> onlineOpportunities = TestFactory.createSObjectList(new Opportunity(), 75, 'TestFactory.OnlineDonationOpportunityDefaults', true);
		List<Opportunity> recurringOpportunities = TestFactory.createSObjectList(new Opportunity(), 50, 'TestFactory.RecurringDonationOpportunityDefaults', true);
		
		Test.startTest();

		string batchJobId = System.scheduleBatch(new DonationProcessBatchable(new DonationProcessOnlineBatch()), 'TestDonationProcessBatch', 1);

		Test.stopTest();
	}

	@TestSetup private static void Setup()
	{
		Email_Settings__c emailSettings = new Email_Settings__c();
		emailSettings.Name = 'Donation Process Batch';
		emailSettings.To_Address__c = 'mustard.seed@nubik.ca';
		emailSettings.Reply_To_Address__c = 'no-reply@nubik.ca';
		emailSettings.Sender_Display_Name__c = 'The Mustard Seed';
		emailSettings.Subject__c = 'Donation Process Status Update:';

		insert emailSettings;

		Donation_Process_Settings__c donationProcessSettings = new Donation_Process_Settings__c();
		donationProcessSettings.Batch_Interval__c = 50;
		donationProcessSettings.SetupOwnerId = '00e360000011Uv8';

		insert donationProcessSettings;
	}
}