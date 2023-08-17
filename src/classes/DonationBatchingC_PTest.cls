@isTest
public class DonationBatchingC_PTest  {
		
	@isTest (seeAllData=true)
	private static void RunBathProcess() {
		//CPTransactionDefaults
		//CnP_PaaS__CnP_Transaction__c cnpTransaction = (CnP_PaaS__CnP_Transaction__c) TestFactory.createSObject(new CnP_PaaS__CnP_Transaction__c(), 'TestFactory.CPTransactionDefaults', true);
		//System.debug(cnpTransaction);
		//List<Opportunity> onlineOpportunities = TestFactory.createSObjectList(new Opportunity(), 75, 'TestFactory.OnlineDonationOpportunityDefaults', true);
		//List<Opportunity> recurringOpportunities = TestFactory.createSObjectList(new Opportunity(), 50, 'TestFactory.RecurringDonationOpportunityDefaults', true);
		
	
		Test.startTest();

		DonationBatchingC_P batchP= new DonationBatchingC_P();
		Database.executeBatch(batchP); 
		Test.stopTest();
	}
}