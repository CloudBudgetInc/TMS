/* **************************************************************************
  * Class: BatchViewController
  * Created by Jordan Ojeda, 07/31/2018
  *
  * Purpose/Methods: Controller(extension) for the batchView page
  *
  * Unit Test: BatchViewControllerTest
  *
  * Modifications:
  * - {DevName}, {MM/DD/YYYY} : {Description of changes made post deployment to client}
  ************************************************************************** */
public class BatchViewController  
{
	public npsp__Batch__c batch{get;set;}
	public boolean posted {get;set;}
	public boolean batchReviewCompleted {get;set;}
	

	public PageReference verifyStatus()
	{
		posted = true;
		boolean reviewCompleted = false;

		

		npsp__Batch__c  batchRef = [SELECT npsp__Batch_Status__c, Job_Id__c FROM npsp__Batch__c WHERE ID = :batch.id];
		reviewCompleted = batchRef.npsp__Batch_Status__c == 'Complete';

		System.debug('reviewCompleted: ' + batchRef.npsp__Batch_Status__c);

		if(batchRef != null && batchRef.Job_Id__c == null)
		{
			list<Opportunity> oppsToPost = [SELECT Id FROM Opportunity WHERE Create_Journal_Status__c != 'Ready to create' AND StageName != 'Declined' AND npsp__Batch__c = :batchRef.id LIMIT 1];
			if(oppsToPost.size() <= 0)
			{
				posted = false; 		
			}
		}
		
		batchReviewCompleted = reviewCompleted;
		return null;
	}

	public BatchViewController(ApexPages.StandardController stdController) 
	{
		//posted=false;
		batch = (npsp__Batch__c)stdController.getRecord();
	}
}