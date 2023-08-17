/**
* @description Unit test class for DonationProcessBatchBase
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
@isTest private class DonationProcessBatchBase_Test 
{
	@isTest private static void Main() 
	{
		List<Nubik_FilterCriteria> filterCriterias = new List<Nubik_FilterCriteria>();
		filterCriterias.add(new Nubik_FilterCriteria('FirstName', '\'Hal\'', '='));
		filterCriterias.add(new Nubik_FilterCriteria('LastName', '\'Jordan\'', '='));

		DonationProcessBatchBase donationProcessBatch = new DonationProcessBatchBase();

		System.assertEquals(null, donationProcessBatch.BATCH_TYPE);
		System.assertEquals(null, donationProcessBatch.PROCESS_NAME);
		System.assertEquals(null, donationProcessBatch.BATCH_NAME_PREFIX);
		System.assertEquals('RecordType.Name = \'Donation\' AND StageName = \'Received\' AND CnP_PaaS__CnP_OrderNumber__c != null AND npsp__Batch__c = null', donationProcessBatch.GetAndFilteredCriteria());
		System.assertEquals('FirstName = \'Hal\' AND LastName = \'Jordan\'', donationProcessBatch.GetAndFilteredCriteria(filterCriterias));
	}
}