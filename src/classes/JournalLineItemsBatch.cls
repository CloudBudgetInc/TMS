/* **************************************************************************
* Batchable Class: JournalLineItemsBatch
* Created by lv@nubik.ca, 06/01/2017
*
* Purpose/Methods:
* - Create Journal line items from Opportunity
*
* Unit Test: JournalLineItemsBatchTest
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
global class JournalLineItemsBatch implements Database.Batchable<SObject>, 
		Database.Stateful 
{
	private Map<Id,Map<Id,Integer>> journalsPerOpp;
	public static final Integer MAX_ITEMS_PER_JOURNAL = 250;
	
	/**
	 * @author lv@nubik.ca
	 * @description constructor of the class to initialize the var to use on the batch
	 */
	global JournalLineItemsBatch(Map<Id,Map<Id,Integer>> journalMap) 
	{
		System.debug('::::::::::' + journalMap);
		journalsPerOpp = journalMap;
	}
	
	/**
	 * @description gets invoked when the batch job starts
	 * @param context contains the job ID
	 * @returns the record set as a QueryLocator object that will be batched for execution
	 */ 
	global Database.QueryLocator start(Database.BatchableContext context) 
	{
        Set<Id> journalsIds = journalsPerOpp.keySet();
		String query = 'Select Id,Receiptable_Amount_GL__c,' + 
				'donation_split__Designation__r.Dimension2_Department__c, ' + 
				'donation_split__Designation__r.Dimension3_Project__c, ' + 
				'donation_split__Designation__r.Dimension4_Cost_Center__c, ' + 
				'donation_split__Designation__r.Name, donation_split__Opportunity__c, ' + 
				'donation_split__Opportunity__r.Amount, donation_split__Amount__c, ' + 
				'donation_split__Opportunity__r.Journal_Lines_To_Create__c,' + 
				'donation_split__Opportunity__r.kell6_core__Receiptable_Amount__c,' + 
				'donation_split__Opportunity__r.kell6_core__Benefit_Value__c,' + 
				'Benefit_Value_On_Opportunity__c,Benefit_Value_GL__c ' + 
				'from donation_split__Designation_Budget__c where donation_split__Opportunity__c ' + 
				'in: journalsIds order by donation_split__Opportunity__c';
		System.debug(':::[DonationsToJournalBatch]::: Query -> ' + query);
		return Database.getQueryLocator(query);
	}

	/**
	 * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls 
	 * the main execution logic for the batch job.
	 * @param context contains the job ID
	 * @param scope contains the batch of records to process.
	 */ 
   	global void execute(Database.BatchableContext context, List<donation_split__Designation_Budget__c> scope) 
	{
		List<c2g__codaJournalLineItem__c> journalLineItems = 
				new List<c2g__codaJournalLineItem__c>();
		Id ATBChecking = [Select Id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c = '1020'].Id;
		for (donation_split__Designation_Budget__c budget : scope)
		{
			Map<Id,Integer> lineItemsPerJournal = journalsPerOpp.get(budget.donation_split__Opportunity__c);
			for (Id headerId : lineItemsPerJournal.keySet())
			{
				Integer index = lineItemsPerJournal.get(headerId);
				if (index >= MAX_ITEMS_PER_JOURNAL)
					continue;
				else
				{
					if (index + 2 == MAX_ITEMS_PER_JOURNAL)
					{
						//verify if we need to create 1 additional journal line item if the benefit 
						//value gl has a value
						if (budget.Benefit_Value_GL__c != null && budget.Benefit_Value_GL__c != '' && 
								budget.Benefit_Value_On_Opportunity__c == true)
						{
							continue;
						}
					}

					if (budget.Receiptable_Amount_GL__c == 
							'Donations - Not Able to Tax Receipt (Insufficient information or donor request)' || 
							budget.Benefit_Value_GL__c == 
							'Donations - Not Able to Tax Receipt (Insufficient information or donor request)')
					{
						Task t = new Task();
						t.OwnerId = [Select id from User where Name = 'Erica Martin' limit 1].Id;
						t.Subject = 'Donations - Not Able to Tax Receipt (Insufficient information or donor request)';
						insert t;
					}

//					journalLineItems.addAll(JournalHelper.generateJournalLineItems(null,headerId,budget));
					index = index + 2;
					lineItemsPerJournal.put(headerId,index);

					//Create 1 additional journal line item if the benefit value gl has a value
					if (budget.Benefit_Value_GL__c != null && budget.Benefit_Value_GL__c != '' && 
							budget.Benefit_Value_On_Opportunity__c == true)
					{
						index = index + 2;
						lineItemsPerJournal.put(headerId,index);
					}
					journalsPerOpp.put(budget.donation_split__Opportunity__c,lineItemsPerJournal);
					break;
				}
			}
		}
		Database.insert(journalLineItems,false);
	}
	
	/**
	 * @description gets invoked when the batch job finishes. Place any clean up code in this method.
	 * @param context contains the job ID
	 */ 
	global void finish(Database.BatchableContext context) {
		
	}
}