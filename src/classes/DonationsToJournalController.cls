/* **************************************************************************
  * Class: DonationsToJournalController
  * Created by Jordan Ojeda, 07/05/2018
  *
  * Purpose/Methods: Controller for the page that will be invoked from the batch 
  *					layout button to create journals by processing the associated opportunities
  *
  * Unit Test: DonationsToJournalControllerTest
  *
  * Modifications:
  * - {DevName}, {MM/DD/YYYY} : {Description of changes made post deployment to client}
  ************************************************************************** */
public class DonationsToJournalController  
{
	private npsp__Batch__c batch{get;set;}

	/**
	  * @description Method to porcess batch and create journies
	  * @author Jordan Ojeda, 07/05/2018
	*/
	public PageReference processBatch()
	{
		List<Opportunity> oppsToProccess = JournalHelper.getOpportunitiesRelated(batch.id);
		//JournalHelper.processOpportunities(oppsToProccess);
		System.debug('oppsToProccess: ' +oppsToProccess);

		boolean proccessed = JournalHelper.wasAlreadyProccessed(batch.id);
		
		if(proccessed)
		{
			batch.Error__c = 'This batch was already processed or some opportunities were already posted';
			batch.Job_Id__c = null;
			update batch;
		}
		else
		{
			
			if(batch.Job_Id__c!= null)
			{
				batch.Error__c = 'This batch is being processed';
				update batch;
			}
			else
			{
				DonationsToJournalValidationBatch jval = new DonationsToJournalValidationBatch(new List<Id>{batch.id}, oppsToProccess);
				id jobId = Database.executeBatch(jval,1);

				batch.Job_Id__c = jobId;
			
				if(jobId != null)
				{
					update batch;
				}
			}

		}
		//DonationsToJournalBatch j = new DonationsToJournalBatch(oppsToProccess);
		//Database.executeBatch(j,1);
		System.debug('before redirection...');
		return new PageReference('/'+batch.id);
	}

	/**
	  * @description Method to porcess batch and create journies
	  * @author Jordan Ojeda, 07/05/2018
	*/
	public DonationsToJournalController(ApexPages.StandardController stdController) 
	{
		if(!Test.isRunningTest())
		{
			stdController.addFields(new String[]{
				'Job_Id__c'
			});
		}
        batch = (npsp__Batch__c)stdController.getRecord();
		
    }
}