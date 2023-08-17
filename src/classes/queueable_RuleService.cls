public class queueable_RuleService implements Queueable 
{
	private Id batchId;
	private Id journalId;
	private ffirule__IntegrationRule__c rule;
	private Queueable nextQueueable;

	public queueable_RuleService(Id batchId, Id journalId, ffirule__IntegrationRule__c rule, Queueable nextQueueable)
	{
		this.batchId = batchId;
		this.journalId = journalId;
		this.rule = rule;
		this.nextQueueable = nextQueueable;
	}

	public void execute(QueueableContext context) 
	{
		Datetime stime = null;
		Datetime etime = null;
		Long millis = null;

		try
		{
			System.debug('### queueable_RuleService.execute - Journal ID: ' + journalId + '  Rule Name: ' + rule.Name);
			System.debug('### queueable_RuleService.execute - ESI_Queued_CL_Process_Identifier__c: ' + rule.ESI_Queued_CL_Process_Identifier__c);

			String query = createQuery();

			stime = Datetime.now();
			List<sObject> results = Database.query(query);
			etime = Datetime.now();

			millis = (etime.getTime() - stime.getTime());
			System.debug('### Query Time in Milliseconds: ' + millis);
			System.debug('### Query Time in Seconds: ' + getReadableTime(millis));

			if (results != null && !results.isEmpty())
			{
				System.debug('### queueable_RuleService.execute Results of Query: ' + results.size());

				Set<Id> soIds = sql_Utility.getIds('Id', results);

				stime = Datetime.now();
				List<Id> idresults = ffirule.RuleService.run(new List<Id>(soIds), rule.Id);
				etime = Datetime.now();

				millis = (etime.getTime() - stime.getTime());
				System.debug('### Service Time in Milliseconds: ' + millis);
				System.debug('### Service Time in Seconds: ' + getReadableTime(millis));

				System.debug('### queueable_RuleService.execute - ClickLink API Call Results: ' + idresults.size());
				System.debug('### queueable_RuleService.execute - ClickLink API Call Results: ' + idresults);
			}
			else
			{
				System.debug('### queueable_RuleService.execute Query Produced No Results!');
			}
		}
		catch (Exception ex)
		{
			System.debug('### ERROR: ' + ex.getMessage() + ': ' + ex.getStackTraceString());
		}

		if (nextQueueable != null)
		{
			System.debug('### Spawning the Next Queueable!');
			System.enqueueJob(nextQueueable);
		}
	}

	private String getReadableTime(Long milliseconds)
	{
		return String.valueOf(DateTime.valueOf(milliseconds).formatGMT('HH:mm:ss'));

	}

	private String createQuery()
	{
		sql_Query query = new sql_Query();
		query.setSObject(rule.ffirule__SourceObject__c);
		query.addField('Id');

		String journalId15 = String.valueOf(journalId).substring(0, 15);

		String criteria = sql_Criteria.AndCriterias(new List<String> {
			sql_Criteria.Equals(rule.ffirule__SourceObjectProcessField__c, true),
			sql_Criteria.Equals(rule.ESI_Queued_CL_Process_Source_Trigger_LNK__c, batchId),
			sql_Criteria.Equals(rule.ESI_Queued_CL_Process_Identifier__c, journalId15)
		});

		query.setCriteria(criteria);

		return query.buildQuery();
	}
}