public with sharing class service_ClickLinks extends service_Base
{
	private dao_ClickLinkRule clrDao = new dao_ClickLinkRule();
	private List<ffirule__IntegrationRule__c> rules;

	public service_ClickLinks() 
	{
		
	}

	public override void process(service_Request request, service_Response response)
	{
		List<npsp__Batch__c> batchJournals = (List<npsp__Batch__c>) request.Parameters.get('batchJournals');
		
		//******************************************************
		//Get all included rules
		//******************************************************
		rules = clrDao.getRulesIncluded();

		if (!rules.isEmpty())
		{
			System.debug('### service_ClickLinks.process - Got Rules!');
			System.debug('### service_ClickLinks.process - Rules: ' + rules.size());

			//for (ffirule__IntegrationRule__c rule : rules)
			//{
			//	System.debug('### service_ClickLinks.process - Rule: ' + rule.Name);
			//}

			//Set<Id> journalIds = sql_Utility.getIds(npsp__Batch__c.ESi_Journal__c, batchJournals);

			//******************************************************
			//Creating SQL Statements dynamically, and storing them
			//with their Rule ID
			//******************************************************

			queueable_RuleService nextQueueable = null;

			for (npsp__Batch__c batchJournal : batchJournals)
			{
				for (ffirule__IntegrationRule__c rule : rules)
				{
					System.debug('### service_ClickLinks.process - Journal ID: ' + batchJournal.ESi_Journal__c + '  Rule: ' + rule.Name);
					nextQueueable = new queueable_RuleService(batchJournal.Id, batchJournal.ESi_Journal__c, rule, nextQueueable);
				}
			}

			System.debug('### Spawning the first Queueable!');
			System.enqueueJob(nextQueueable);
		}
	}
}