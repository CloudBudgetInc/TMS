/**
* @description Unit test class for DonationProcessOnlineBatch
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
@isTest private class DonationProcessOnlineBatch_Test 
{
	@isTest private static void Main() 
	{
		List<Nubik_FilterCriteria> filterCriterias = new List<Nubik_FilterCriteria>();
		filterCriterias.add(new Nubik_FilterCriteria('FirstName', '\'Diana\'', '='));
		filterCriterias.add(new Nubik_FilterCriteria('LastName', '\'Prince\'', '='));

		DonationProcessOnlineBatch donationProcessBatch = new DonationProcessOnlineBatch();

		System.assertEquals('Credit Card', donationProcessBatch.BATCH_TYPE);
		System.assertEquals('Online Batch', donationProcessBatch.PROCESS_NAME);
		System.assertEquals('O', donationProcessBatch.BATCH_NAME_PREFIX);
		
		System.debug(donationProcessBatch.GetAndFilteredCriteria());
	}
}