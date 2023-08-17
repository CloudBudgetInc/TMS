/**
* @description Base class used as a template for donation process types
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
public virtual class DonationProcessBatchBase  
{
	/* Constants */
	public final String PROCESS_NAME;
	public final String BATCH_NAME_PREFIX;
	public final String BATCH_TYPE;

	/* Enums & Structs */

	/* Public Members */

	/* Private Members */
	protected List<Nubik_FilterCriteria> OpportunityFilters = new List<Nubik_FilterCriteria>();

	/* Properties */

	/* Apex API */

	/* Public API */

	public DonationProcessBatchBase()
	{
		SetOpportunityFilters();
	}

	/**
	* @description Create the conditions of the WHERE clause based on the set filters
	* @param criterias List of criterias used to make the WHERE clause
	* @return Returns the conditions for the WHERE clause
	*/ 
	public virtual String GetAndFilteredCriteria(List<Nubik_FilterCriteria> criterias) 
	{
		return Nubik_FilterCriteria.GetAndFilteredCriteria(criterias);
	}

	/**
	* @description Create the conditions of the WHERE clause based on the set filters
	* @return Returns the conditions for the WHERE clause
	*/ 
	public virtual String GetAndFilteredCriteria() 
	{
		return Nubik_FilterCriteria.GetAndFilteredCriteria(OpportunityFilters);
	}

	/* Protected API */

	/**
	* @description Set new filters to be used in the WHERE clause
	*/ 
	protected virtual void SetOpportunityFilters()
	{
		OpportunityFilters.add(new Nubik_FilterCriteria('RecordType.Name', '\'Donation\'', '='));
		OpportunityFilters.add(new Nubik_FilterCriteria('StageName', '\'Received\'', '='));
		OpportunityFilters.add(new Nubik_FilterCriteria('CnP_PaaS__CnP_OrderNumber__c', 'null', '!='));
		OpportunityFilters.add(new Nubik_FilterCriteria('npsp__Batch__c', 'null', '=')); 
	}

	/* Private API */

	/* Interface Implementation */
}