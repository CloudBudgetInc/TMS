/**
* @description Handles the online batch settings
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
public class DonationProcessOnlineBatch extends DonationProcessBatchBase
{
	/* Constants */

	/* Enums & Structs */

	/* Public Members */
	
	/* Private Members */

	/* Properties */

	/* Apex API */

	/* Public API */

	public DonationProcessOnlineBatch()
	{
		PROCESS_NAME = 'Online Batch';
		BATCH_NAME_PREFIX = 'O';
		BATCH_TYPE = 'Credit Card';

		SetOpportunityFilters();
	}

	/**
	* @description Create the conditions of the WHERE clause based on the set filters
	* @return Returns the conditions for the WHERE clause
	*/ 
	public override String GetAndFilteredCriteria() 
	{
		return super.GetAndFilteredCriteria(OpportunityFilters);
	}

	/* Protected API */

	/**
	* @description Set new filters to be used in the WHERE clause
	*/ 
	protected override void SetOpportunityFilters()
	{
		super.SetOpportunityFilters();

		OpportunityFilters.add(new Nubik_FilterCriteria('CnP_PaaS__C_P_Recurring__c', 'null', '=')); 
	}

	/* Private API */

	/* Interface Implementation */
}