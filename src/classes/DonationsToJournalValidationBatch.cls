/* *************************************************************************
  * Batch Class: DonationsToJournalValidationBatch
  * Created by Jordan Ojeda, 07/23/2018
  *
  * Purpose/Methods:
  * - 
  *
  * Unit Test: DonationsToJournalValidationBatchTest
  *
  * Modifications:
  * - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
  *
  ************************************************************************** */
public class DonationsToJournalValidationBatch implements Database.Batchable<Sobject>, 
Schedulable,
Database.Stateful
{
	private List<Id> DonationsToJournalValidationIds;
	private Set<Id> batchesToStop;
	private List<Opportunity> oppsToProccess;
	private Map<Id, List<Id>> oppsByBatchMap;
	public list<String> errorsDetected;


	/************************** Constructors ******************************/

	public DonationsToJournalValidationBatch(List<Id> ids, list<Opportunity> opps)
	{
		DonationsToJournalValidationIds = Ids;
		oppsToProccess = opps;
		batchesToStop = new Set<Id>();
		errorsDetected = new list<String>();
		oppsByBatchMap= new Map<Id, List<Id>>();

		for(Opportunity opp : oppsToProccess)
		{
			if(!oppsByBatchMap.containsKey(opp.npsp__Batch__c))
			{
				oppsByBatchMap.put(opp.npsp__Batch__c, new list<Id>());
			}
			oppsByBatchMap.get(opp.npsp__Batch__c).add(opp.id);
		}
	}

	public DonationsToJournalValidationBatch()
	{
		DonationsToJournalValidationIds = new List<Id>();
		errorsDetected = new list<String>();
		batchesToStop = new Set<Id>();
		oppsToProccess = new list<Opportunity>();
		oppsByBatchMap= new Map<Id, List<Id>>();
	}

	/************************** END Constructors ******************************/




	/**
	 * @description this is a method that you can use to schedule the batch
	 * @author Jordan Ojeda, 07/23/2018
	 */ 
	public static void Schedule()
	{
		DonationsToJournalValidationBatch job = new DonationsToJournalValidationBatch();
		//runs every first day of each month
		String sch = '0 0 * 1 * ?';
		system.schedule('Donations To Journal Validation', sch, job);
	}

	/**
	 * @description this is a method that you can use to execute the batch
	 * @author Jordan Ojeda, 07/23/2018
	 */ 
	public static void execute(){
		DonationsToJournalValidationBatch job = new DonationsToJournalValidationBatch();
		Database.executeBatch(job, 50);
	}

	/**
	 * @description this is a method that you can use to execute the batch in a set of records
	 * @author Jordan Ojeda, 07/23/2018
	 */
	public static void execute(List<Id> ids, list<Opportunity> opps){
		DonationsToJournalValidationBatch job = new DonationsToJournalValidationBatch(ids, opps);
		Database.executeBatch(job, 50);
	}

	/**
	 * @description this is a method that you can use to execute the batch unsing an instance of the class
	 * @author Jordan Ojeda, 07/23/2018
	 */
	public void execute(SchedulableContext context){
		DonationsToJournalValidationBatch job = new DonationsToJournalValidationBatch();
		Database.executeBatch(job, 50);
	}

	/**
	 * @description this is the start method from the interface Schedulable, that has to be implemented by the batch 
	 * @author Jordan Ojeda, 07/23/2018
	 */
	public Database.QueryLocator start(Database.BatchableContext BC){            
		return Database.getQueryLocator(DonationsToJournalValidationBatchHelper.getDonationsToJournalValidationBatchQuery('DonationsToJournalValidationIds'));
	}


	/**
	 * @description this is the execute method from the interface Schedulable, that has to be implemented by the batch 
	 * @author Jordan Ojeda, 07/23/2018
	 */
	public void execute(Database.BatchableContext BC, List<Sobject> scope)
	{
		if(scope!=null && !scope.isEmpty())
		{
			List<Opportunity> opportunities = (List<Opportunity>)scope;
			////////// CUSTOM CODE HERE ////////////
			//Set<Id> oppsWithJournalLinesToCreate = new Set<Id> ();
			//for (Opportunity opp : scope)
			//{
				//if (opp.Journal_Lines_To_Create__c >= 1)
				//{
					//oppsWithJournalLinesToCreate.add(opp.id);
				//}
			//}


			Set<Id> donationSplitDBudgetPerOppId = new Set<Id> ();

			List<donation_split__Designation_Budget__c> hasEmptyProjects = [Select Id from
															  donation_split__Designation_Budget__c where
															  donation_split__Opportunity__c IN :opportunities and
					((donation_split__Opportunity__r.Account.Type = 'Government' and
					  donation_split__Designation__r.Is_GL_Reporting_Code_Between_100_199__c = true) or
					(donation_split__Opportunity__r.Account.Type = 'Charity/Foundation' and
					 donation_split__Designation__r.Is_GL_Reporting_Code_Between_100_199__c = true) or
					 donation_split__Opportunity__r.Type = 'DemoCrew' or
					 donation_split__Opportunity__r.Type = 'DemoCrewPlunge' or
					 donation_split__Opportunity__r.Type = ' CollegeCrew') and
															  donation_split__Designation__r.Dimension3_Project__c = null];

			for (donation_split__Designation_Budget__c hasEmptyProject : hasEmptyProjects)
			{
				if (!donationSplitDBudgetPerOppId.contains(hasEmptyProject.donation_split__Opportunity__c))
				{
					donationSplitDBudgetPerOppId.add(hasEmptyProject.donation_split__Opportunity__c);
				}
			}


			for (Opportunity opp : opportunities)
			{
				if (opp.Journal_Lines_To_Create__c< 1)
				{
					if (opp.Account.type == 'Government' || opp.Account.Type == 'Charity/Foundation')
					{
						batchesToStop.add(opp.npsp__Batch__c);
					}
				}
				else
				{
					//We has a project for all the desgnation budget
					if (donationSplitDBudgetPerOppId.contains(opp.id))
					{
						batchesToStop.add(opp.npsp__Batch__c);
					}
				}

				if(opp.Create_Journal_Status__c != 'Ready to create')
				{
					batchesToStop.add(opp.npsp__Batch__c);
					System.debug('batchesToStop:' + batchesToStop);
				}
			}

			List<npsp__Batch__c> batchesWithErrors = new List<npsp__Batch__c>();
			for(Id batchToStop : batchesToStop)
			{
				npsp__Batch__c b = new npsp__Batch__c();
				b.Id = batchToStop;
				b.Error__c = Label.Batch_Error;
				batchesWithErrors.add(b);
			}

			update batchesWithErrors; 
		}  
	}

	/**
	 * @description this is the finish method from the interface Schedulable, that has to be implemented by the batch 
	 * @author Jordan Ojeda, 07/23/2018
	 */
	public void finish(Database.BatchableContext BC)
	{
		////////// CUSTOM CODE HERE ////////////
		List<Id> filteredOppsToProccess = new List<Id>();
		list<Id> batchesInJobIds = new list<Id>();
		list<npsp__Batch__c> batchesInJob = new list<npsp__Batch__c>();
		
		for(Id batchId : oppsByBatchMap.keySet())
		{
			if(!batchesToStop.contains(batchId))
			{
				filteredOppsToProccess.addAll(oppsByBatchMap.get(batchId));
				batchesInJobIds.add(batchId);
			}
		}
		System.debug('filteredOppsToProccess: ' + filteredOppsToProccess);
		if(!filteredOppsToProccess.isEmpty())
		{
			DonationsToJournalBatch j = new DonationsToJournalBatch(filteredOppsToProccess);
			id jobId = Database.executeBatch(j,1);
			for(Id batchInJob : batchesInJobIds )
			{
				npsp__Batch__c batch = new npsp__Batch__c();
				batch.id = batchInJob;
				batch.Job_Id__c = jobId;
				batch.Last_Job_Id__c = jobId;
				batchesInJob.add(batch); 
			}
			
			if(!batchesInJob.isEmpty())
			{
				update batchesInJob;
			}
		}

		
	}
}