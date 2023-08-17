/**
* @description Unit test class for Nubik_FilterCriteria
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
@isTest private class Nubik_FilterCriteria_Test 
{
	@isTest private static void Main() 
	{
		List<Nubik_FilterCriteria> filterClients = new List<Nubik_FilterCriteria>();
		filterClients.add(new Nubik_FilterCriteria('FirstName', '\'Clark\'', '='));
		filterClients.add(new Nubik_FilterCriteria('LastName', '\'Kent\'', '='));
		
		System.assert(filterClients.get(0).IsFieldValueNullOrEmpty());
		
		System.assertEquals('FirstName = \'Clark\'', filterClients.get(0).GetFilter());
		System.assertEquals('FirstName = \'Clark\' AND LastName = \'Kent\'', Nubik_FilterCriteria.GetAndFilteredCriteria(filterClients));
	}
}