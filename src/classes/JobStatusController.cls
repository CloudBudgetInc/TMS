/* **************************************************************************
  * Controller Class: JobStatusController
  * Created by Luis Velis, 09/15/2015
  *
  * Purpose/Methods:
  * - Display the status of the batch job.
  *
  * Unit Test: JobStatusControllerTest 
  * 
  * Modifications:
  * - {DevName}, {MM/DD/YYYY} – {Description of changes made post deployment to client}
  *
  ************************************************************************** */
public without sharing class JobStatusController {

	public Id recordId { get;set
	{
		recordId=value;
		if(!firstInitialization)
		{
			firstInitialization=true;
			oneTimeinit();
		}
	} }
	public String sObjectname { get;set;}
	public Integer percentComplete { get; set; }
	
	
	public Id jobId { get; set; }
	private boolean jobIdUpdated { get; set; }
	public boolean hasIdJob{ get; set; }


	public boolean posted{ get; set; }
	public boolean notReady{ get; set; }
	public boolean errorReported{ get; set; }
	public string errorMessage{ get; set; }
	public boolean isValidating { get; set; }
	public boolean isPosting { get; set; }
	public boolean isCompleted { get; set; }
	public boolean firstInitialization { get; set; }


	public JobStatusController()
	{
		

		isValidating = true;
		isPosting = false;
		percentComplete=0;

		//oneTimeinit();

		firstInitialization = false;

	}
	public void oneTimeinit() 
	{
		System.debug('oneTimeinit...');
		isCompleted = false;
		
		jobIdUpdated = false;
		hasIdJob = false;
		posted = false;
		notReady=false;
		errorMessage='';
		list<npsp__Batch__c> batches = [SELECT Job_Id__c, Error__c FROM npsp__Batch__c WHERE Id =: recordId];
		
		if(!batches.isEmpty())
		{
			errorMessage = batches[0].Error__c;
			errorReported = !String.isBlank(errorMessage);

			if(batches[0].Job_Id__c == null)
			{
				list<Opportunity> oppsToPost = [SELECT Create_Journal_Status__c FROM Opportunity WHERE (Create_Journal_Status__c != 'Ready to create' AND StageName != 'Declined') AND npsp__Batch__c = :batches[0].id LIMIT 1];
				if(oppsToPost.size() > 0)
				{
					posted = true;
					for(Opportunity oppToPost : oppsToPost)
					{
						if(oppToPost.Create_Journal_Status__c != 'Created')
						{
							posted = false;
							notReady = true;
						}
					}
					
					
				}
			}
			else
			{
				hasIdJob = true;
				jobId=batches[0].Job_Id__c;
			}
		}
		//errorMessage=recordId;
		//init();

		isValidating = true;
		isPosting = false;
		percentComplete=0;
		
		System.debug('oneTimeinit: ' + hasIdJob + ' - '+posted);

	}

	public void init() 
	{
		//if(!firstInitialization)
		//{
			//firstInitialization = true;
			//oneTimeinit();
		//}
		
		
		if(!isCompleted)
		{
			list<npsp__Batch__c> batches = [SELECT Job_Id__c, Last_Job_Id__c FROM npsp__Batch__c WHERE Id =: recordId];
			if(!batches.isEmpty())
			{
				if(batches[0].Job_Id__c != null)
				{
					jobId = batches[0].Job_Id__c;	
				}
				else
				{
					if(batches[0].Last_Job_Id__c != null)
					{
						jobId =batches[0].Last_Job_Id__c;
					}
				}

				
					

					list<AsyncApexJob> aApexjlist = [SELECT TotalJobItems, Status, NumberOfErrors, MethodName, JobType, JobItemsProcessed, Id, 
						CreatedDate, CreatedById, CompletedDate, ApexClassId, ApexClass.Name 
					FROM 
						AsyncApexJob 
					WHERE 
						Id = :jobId];


					if(!aApexjlist.isEmpty())
					{
						AsyncApexJob aJob = aApexjlist[0];

						if(aJob.ApexClass.Name == 'DonationsToJournalValidationBatch')
						{
							isValidating = true;
							isPosting = false;
						}
						else if(aJob.ApexClass.Name == 'DonationsToJournalBatch')
						{
							isValidating = false;
							isPosting = true;
						}

					

						if(aJob.status == 'Failed' || aJob.status == 'Aborted')
						{
							//hasIdJob=false;	
						}
						else if(aJob.status == 'Completed') 
						{
							percentComplete = 100;
							if(isPosting)
							{
								isCompleted = true;
							}
						}
						else if (aJob.TotalJobItems == 0) 
						{
							//A little check here as we don't want to divide by 0.
							percentComplete = 0;
						} 
						else 
						{
							percentComplete = ((decimal)((decimal)aJob.JobItemsProcessed  / (decimal)aJob.TotalJobItems) * 100.0).intValue();
						}



					}

				
			}
		}
		
		
	}
}