public with sharing class trigger_npspBatch extends trigger_Domain
{
	public override void afterUpdate(Map<Id, sObject> newRecords, Map<Id, sObject> oldRecords)
	{
		System.debug('### Run ClickLinks!');
		runClickLinks((Map<Id, npsp__Batch__c>) newRecords, (Map<Id, npsp__Batch__c>) oldRecords);
	}

	private void runClickLinks(Map<Id, npsp__Batch__c> newRecords, Map<Id, npsp__Batch__c> oldRecords)
	{
		List<npsp__Batch__c> batchJournals = new List<npsp__Batch__c>();

		for (npsp__Batch__c newRecord : newRecords.values())
		{
			npsp__Batch__c oldRecord = oldRecords.get(newRecord.Id);

			if (oldRecord != null 
			&& newRecord.ESi_CL_Control_Batch_Processed__c != oldRecord.ESi_CL_Control_Batch_Processed__c 
			&& newRecord.ESi_CL_Control_Batch_Processed__c == true 
			&& newRecord.ESi_Journal__c != null)
			{
				batchJournals.add(newRecord);
			}
		}

		if (!batchJournals.isEmpty())
		{
			System.debug('### trigger_npspBatch.runClickLinks - Calling service_ClickLinks...');

	       	service_Request request = new service_Request();
			request.Parameters.put('batchJournals', batchJournals);
			service_Response response = service_Controller.process(Services.ClickLinks, request);
		}
	}
}