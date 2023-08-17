public with sharing class dao_ClickLinkRule extends sql_Dao
{
	public dao_ClickLinkRule() 
	{
		setSObject(ffirule__IntegrationRule__c.sObjectType);

		addField(ffirule__IntegrationRule__c.Id);
		addField(ffirule__IntegrationRule__c.Name);
		addField(ffirule__IntegrationRule__c.ESI_Queued_CL_Process_Identifier__c);
		addField(ffirule__IntegrationRule__c.ESI_Queued_CL_Process_Include__c);
		addField(ffirule__IntegrationRule__c.ESI_Queued_CL_Process_Source_Trigger_LNK__c);
		addField(ffirule__IntegrationRule__c.ffirule__SourceObject__c);
		addField(ffirule__IntegrationRule__c.ffirule__SourceObjectProcessField__c);
	}

	public List<ffirule__IntegrationRule__c> getRulesIncluded()
	{
		String criteria = sql_Criteria.Equals(ffirule__IntegrationRule__c.ESI_Queued_CL_Process_Include__c, true);
		return (List<ffirule__IntegrationRule__c>) getWhere(criteria);
	}
}