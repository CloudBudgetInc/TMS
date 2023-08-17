/**
* @description Handles the recurring gift batch settings
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
public class DonationProcessRecurringGiftBatch extends DonationProcessBatchBase
{
	/* Constants */

	/* Enums & Structs */

	/* Public Members */

	/* Private Members */

	/* Properties */

	/* Apex API */

	/* Public API */

	public DonationProcessRecurringGiftBatch()
	{
		PROCESS_NAME = 'Recurring Gift Batch';
		BATCH_NAME_PREFIX = 'R';
		BATCH_TYPE = 'Monthly Donor';

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
		
		OpportunityFilters.add(new Nubik_FilterCriteria('CnP_PaaS__C_P_Recurring__c', 'null', '!=')); 
		OpportunityFilters.add(new Nubik_FilterCriteria('Amount', '0', '>')); 
	}

	/* Private API */

	/* Interface Implementation */
}