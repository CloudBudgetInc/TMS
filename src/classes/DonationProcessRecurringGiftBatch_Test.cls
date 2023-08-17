/**
* @description Unit test class for DonationProcessRecurringGiftBatch
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
@isTest private class DonationProcessRecurringGiftBatch_Test 
{
	@isTest private static void Main() 
	{
		List<Nubik_FilterCriteria> filterCriterias = new List<Nubik_FilterCriteria>();
		filterCriterias.add(new Nubik_FilterCriteria('FirstName', '\'Arthur\'', '='));
		filterCriterias.add(new Nubik_FilterCriteria('LastName', '\'Curry\'', '='));

		DonationProcessRecurringGiftBatch donationProcessBatch = new DonationProcessRecurringGiftBatch();

		System.assertEquals('Monthly Donor', donationProcessBatch.BATCH_TYPE);
		System.assertEquals('Recurring Gift Batch', donationProcessBatch.PROCESS_NAME);
		System.assertEquals('R', donationProcessBatch.BATCH_NAME_PREFIX);
		
		System.debug(donationProcessBatch.GetAndFilteredCriteria());
	}
}