/* **************************************************************************
  * Batchable Class: DonationsToJournalBatch
  * Created by lv@nubik.ca, 06/01/2017
  *
  * Purpose/Methods:
  * - Create Journal Header from Opportunity
  *
  * Unit Test: DonationsToJournalBatchTest
  *
  * Modifications:
  * - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
  *
  ************************************************************************** */
global class DonationsToJournalBatch implements Database.Batchable<SObject>,
Database.Stateful
{



	//Owner company for the new journals created
	private c2g__codaCompany__c mustardSeedCompany;
	//Journals created per opportunity
	private Map<Id, Map<Id, Integer>> journalsPerOpp;
	public static final String JOURNAL_REFERENCE = 'Donations To Journal Process - ';
	public static final String POSTED_OPPORTUNITY_STAGE = 'Posted';
	public static final Integer MAX_ITEMS_PER_JOURNAL = 250;



	private list<Id> OpportunitiesIds;
	private Id BankAccountRef;
	private integer newJ;
	
	private Map<Id, DonationsToJournalBatch.JournalLineItemsStatus> journalsPerBatchManagerMap;
	Map<Id, List<c2g__codaJournal__c>> journalsPerBatchId;


	global class JournalAndItems
	{
		public c2g__codaJournal__c journal{get;set;}
		public List<c2g__codaJournalLineItem__c> items{get;set;}
		public List<Opportunity> opps{get;set;}

		public JournalAndItems(c2g__codaJournal__c refJournal, List<c2g__codaJournalLineItem__c> lines, List<Opportunity> refOpps)
		{
			journal = refJournal;
			items = lines;
			opps = refOpps;
		}
	}

	global class JournalLineItemsStatus
	{
		
		public  List<DonationsToJournalBatch.JournalAndItems> journalsAndLineItems { get; set; }
		public string errorMessage { get; set; }

		public void createNewJournal()
		{
			//integer index = journals.size() + 1;

			c2g__codaJournal__c journal = new c2g__codaJournal__c();
			journal.c2g__JournalDate__c = Date.today();
			//journal.c2g__Reference__c = JOURNAL_REFERENCE + Date.today() + ' - Part ' + index + 'of ' + numberJournals;
			//journal.c2g__OwnerCompany__c = mustardSeedCompany.Id;
			//journal.c2g__JournalDescription__c = JOURNAL_REFERENCE + Date.today() +' - Part ' + index + 'of ' + numberJournals;
			journalsAndLineItems.add(new JournalAndItems(journal, new List<c2g__codaJournalLineItem__c>(), new List<Opportunity>()));
		}

		public JournalLineItemsStatus()
		{
			journalsAndLineItems = new List<DonationsToJournalBatch.JournalAndItems>();
			createNewJournal();
		}

		public void addLinesItems(List<c2g__codaJournalLineItem__c> lineItems, Opportunity opp)
		{
			if ((journalsAndLineItems[journalsAndLineItems.size()-1].items.size() + lineItems.size()) > DonationsToJournalBatch.MAX_ITEMS_PER_JOURNAL)
			{
				createNewJournal();
			}
			
			journalsAndLineItems[journalsAndLineItems.size()-1].items.addAll(lineItems);		
			journalsAndLineItems[journalsAndLineItems.size()-1].opps.add(opp);
		}

	}



	/**
	 * @author lv@nubik.ca
	 * @date 06/01/2017
	 * @description Constructor method to initilize the data to be used on the 
	 * batch
	 */
	global DonationsToJournalBatch() {
		//Get the mustard seed foundation company set for finantialforce
		mustardSeedCompany = [Select Id from c2g__codaCompany__c where
		                      Name = 'The Mustard Seed Foundation'];

		OpportunitiesIds = new List<Id> ();
		journalsPerBatchManagerMap = new Map<Id, DonationsToJournalBatch.JournalLineItemsStatus> ();
		journalsPerBatchId = new Map<Id, List<c2g__codaJournal__c>> ();
		newJ=0;
	}

	/**
	 * @description Constructor with the specified list 
	 * @author Jordan Ojeda, 05/07/2018
	 */
	global DonationsToJournalBatch(list<Id> oppsIds)
	{
		mustardSeedCompany = [Select Id from c2g__codaCompany__c where
		                      Name = 'The Mustard Seed Foundation'];

		list<c2g__codaBankAccount__c> codaBankAccounts = [SELECT ID FROM c2g__codaBankAccount__c WHERE c2g__ReportingCode__c = '1020'];
		if(codaBankAccounts != null && !codaBankAccounts.isEmpty())
		{ 
			BankAccountRef = codaBankAccounts[0].Id;
		}

		OpportunitiesIds = oppsIds;
		if (OpportunitiesIds == null)
		{
			OpportunitiesIds = new List<Id> ();
		}

		journalsPerBatchManagerMap = new Map<Id, DonationsToJournalBatch.JournalLineItemsStatus> ();
		journalsPerBatchId = new Map<Id, List<c2g__codaJournal__c>> ();
		newJ=0;
	}


	/**
	 * @author lv@nubik.ca
	 * @date 06/01/2017
	 * @description Standard method to initiliaze the batch based on the query
	 */
	global Database.QueryLocator start(Database.BatchableContext context)
	{
		string filter = '';
		if (!OpportunitiesIds.isEmpty())
		{
			filter = ' AND Id in (\'' + String.join(OpportunitiesIds, '\',\'') + '\')';
		}

		String query = 'Select Id,Name,Journal_Lines_To_Create__c,Designation_Line_Number__c,' +
		'Account.Type,Campaign.Top_Parent__r.Name,Type,Tax_Receiptable__c,kell6_cp__Ready_To_Print__c,Site__c,' +
		'kell6_core__Receiptable_Amount__c, kell6_core__Benefit_Value__c ' +
		',npsp__Batch__r.Name,CnP_PaaS__CnP_OrderNumber__r.Name,CnP_PaaS__CnP_Payment_Type__c' +
		' from Opportunity where Create_Journal__c = true' + filter;
		// and id in (\'0060q000003OJAY\',\'0060q000002nCIp\')';
		System.debug('query: ' + query);
		return Database.getQueryLocator(query);
	}

	/**
	 * @author lv@nubik.ca
	 * @date 06/01/2017
	 * @description Method to be executed on each transaction specified by the query 
	 * on the start method
	 */
	//global void execute2(Database.BatchableContext context, List<Opportunity> scope)
	//{
		//List<c2g__codaJournal__c> journals2Insert = new List<c2g__codaJournal__c> ();
		//List<c2g__codaJournalLineItem__c> journalLineItems =
		//new List<c2g__codaJournalLineItem__c> ();

		////The opportunity size to process is only one
		//for (Opportunity opp : scope)
		//{
			//if (opp.Journal_Lines_To_Create__c< 1)
			//{
				//if (opp.Account.type != 'Government' && opp.Account.Type != 'Charity/Foundation')
				//{
					////Create Journal
					//c2g__codaJournal__c journal = new c2g__codaJournal__c();
					//journal.c2g__JournalDate__c = Date.today();
					//journal.c2g__Reference__c = JOURNAL_REFERENCE + Date.today() +
					//' - Part 1 of 1';
					//journal.c2g__OwnerCompany__c = mustardSeedCompany.Id;
					//journal.c2g__JournalDescription__c = JOURNAL_REFERENCE + Date.today() +
					//' - Part 1 of 1';
					//journals2Insert.add(journal);
					////If the Journal is not created let the process to trigger the 
					////standard exception
					//System.debug('journals2Insert: ' + journals2Insert);
					//insert journals2Insert;
					//opp.Journal_Header__c = journals2Insert[0].Id;
					////opp.StageName = POSTED_OPPORTUNITY_STAGE;
					//opp.GL_Post_Status__c = POSTED_OPPORTUNITY_STAGE;
					//opp.Journal_Header_Posted_Date__c = Date.today();
					////opp.Create_Journal_Status__c = 'Created';
					//update opp;
					//journalLineItems.addAll(JournalHelper.generateJournalLineItems(opp,
					                                                               //journals2Insert[0].Id, null, null, null, null));
					//Database.SaveResult[] result2 = Database.insert(journalLineItems, false);
				//}
			//}
			//else
			//{
				//List<AggregateResult> hasEmptyProjects = [Select count(Id) from
				                                          //donation_split__Designation_Budget__c where
				                                          //donation_split__Opportunity__c = :opp.Id and
				//((donation_split__Opportunity__r.Account.Type = 'Government' and
				  //donation_split__Designation__r.Is_GL_Reporting_Code_Between_100_199__c = true) or
				//(donation_split__Opportunity__r.Account.Type = 'Charity/Foundation' and
				 //donation_split__Designation__r.Is_GL_Reporting_Code_Between_100_199__c = true) or
				 //donation_split__Opportunity__r.Type = 'DemoCrew' or
				 //donation_split__Opportunity__r.Type = 'DemoCrewPlunge' or
				 //donation_split__Opportunity__r.Type = ' CollegeCrew') and
				                                          //donation_split__Designation__r.Dimension3_Project__c = null];

				////We has a project for all the desgnation budget
				//if (hasEmptyProjects[0].get('expr0') == 0)
				//{

					////By default we create at least one journal header
					//Double numberJournals = 1;
					////If the number of line items to create is bigger than 250, we need to 
					////create more than one journal header
					//if (opp.Journal_Lines_To_Create__c> MAX_ITEMS_PER_JOURNAL)
					//numberJournals = Math.ceil(opp.Journal_Lines_To_Create__c / MAX_ITEMS_PER_JOURNAL);
					//for (Integer index = 1; index <= numberJournals; index++)
					//{
						//c2g__codaJournal__c journal = new c2g__codaJournal__c();
						//journal.c2g__JournalDate__c = Date.today();
						//journal.c2g__Reference__c = JOURNAL_REFERENCE + Date.today() + ' - Part ' +
						//index + 'of ' + numberJournals;
						//journal.c2g__OwnerCompany__c = mustardSeedCompany.Id;
						//journal.c2g__JournalDescription__c = JOURNAL_REFERENCE + Date.today() +
						//' - Part ' + index + 'of ' + numberJournals;
						//journals2Insert.add(journal);
					//}
					////The batch is intended to run 1 by 1
					//System.debug('journals2Insert: ' + journals2Insert);
					//Database.SaveResult[] result = Database.insert(journals2Insert, false);
					//for (Database.SaveResult r : result)
					//{
						//if (r.isSuccess())
						//{
							//if (journalsPerOpp == null) journalsPerOpp = new Map<Id, Map<Id, Integer>> ();
							//if (!journalsPerOpp.containsKey(opp.Id))
							//journalsPerOpp.put(opp.Id, new Map<Id, Integer> ());
							//Map<Id, Integer> temp = journalsPerOpp.get(opp.Id);
							//temp.put(r.getId(), 0);
						//} else {
							//System.debug(':::Errors:::' + r.getErrors());
						//}
					//}
					//opp.Journal_Header__c = journals2Insert[0].Id;
					////opp.StageName = POSTED_OPPORTUNITY_STAGE;
					//opp.GL_Post_Status__c = POSTED_OPPORTUNITY_STAGE;
					//opp.Journal_Header_Posted_Date__c = Date.today();
					////opp.Create_Journal_Status__c = 'Created';
					//update opp;
				//}
			//}
		//}
	//}

	private void AddLinesToBatch(List<c2g__codaJournalLineItem__c> lItems, Opportunity opp, Map<Id, DonationsToJournalBatch.JournalLineItemsStatus> JournalAndLinesPerBatch)
	{
		if(!JournalAndLinesPerBatch.containsKey(opp.npsp__Batch__c))
		{
			JournalAndLinesPerBatch.put(opp.npsp__Batch__c, new DonationsToJournalBatch.JournalLineItemsStatus());
		}
		JournalAndLinesPerBatch.get(opp.npsp__Batch__c).addLinesItems(lItems, opp);
	}


	global void execute(Database.BatchableContext context, List<Opportunity> scope)
	{
		List<c2g__codaJournal__c> journals2Insert = new List<c2g__codaJournal__c> ();
		List<Opportunity> oppsToUpdate = new List<Opportunity>();
		List<c2g__codaJournalLineItem__c> journalLineItems = new List<c2g__codaJournalLineItem__c>();


		Map<Id, c2g__codaJournalLineItem__c> BankFundationEntries = new Map<Id, c2g__codaJournalLineItem__c>();


		Map<Id, integer> lineItemsCountPerBatch = new Map<Id, integer> ();
		Map<Id, integer> lineItemsCountPerOpp = new Map<Id, integer> ();
		Map<Id, npsp__Batch__c> batchNames = new Map<Id, npsp__Batch__c> ();
		Set<Id> batchesId = new Set<Id> ();
		Set<Id> oppsWithJournalLinesToCreate = new Set<Id> ();
		Set<Id> donationSplitDBudgetPerOppId = new Set<Id> ();
		
		
		Map<Id, List<donation_split__Designation_Budget__c>> bugetsByOpps = new Map<Id, List<donation_split__Designation_Budget__c>> ();
		List<Task> tasksToCreate = new List<Task> ();
		list<User> EROwners = [Select id from User where Name = 'Erica Martin' limit 1];
		Map<String, c2g__codaDimension1__c> dimensions1PerOppSiteMap = new Map<String, c2g__codaDimension1__c>();
		List<c2g__codaDimension1__c> dimensions1 = new List<c2g__codaDimension1__c>();

		Id EROwnerId;
		if (!EROwners.isEmpty())
		{
			EROwnerId = EROwners[0].Id;
		}

		Set<string> oppsSites= new Set<string>();

		
		for (Opportunity opp : scope)
		{
			if (opp.Journal_Lines_To_Create__c >= 1)
			{
				oppsWithJournalLinesToCreate.add(opp.id);
			}
			oppsSites.add(opp.Site__c);
			batchesId.add(opp.npsp__Batch__c);
		}

		if(!batchesId.isEmpty())
		{
			batchNames =  new Map<Id, npsp__Batch__c>([SELECT Name FROM npsp__Batch__c WHERE ID IN :batchesId]);
		}

		try
		{
			dimensions1 = [Select Name from c2g__codaDimension1__c where Name IN :oppsSites];
			for(c2g__codaDimension1__c dimension1 : dimensions1)
			{
				dimensions1PerOppSiteMap.put(dimension1.Name, dimension1);
			}

			List<donation_split__Designation_Budget__c> hasEmptyProjects = [Select Id from
													  donation_split__Designation_Budget__c where
													  donation_split__Opportunity__c IN :oppsWithJournalLinesToCreate and
			((donation_split__Opportunity__r.Account.Type = 'Government' and
			  donation_split__Designation__r.Is_GL_Reporting_Code_Between_100_199__c = true) or
			(donation_split__Opportunity__r.Account.Type = 'Charity/Foundation' and
			 donation_split__Designation__r.Is_GL_Reporting_Code_Between_100_199__c = true) or
			 donation_split__Opportunity__r.Type = 'DemoCrew' or
			 donation_split__Opportunity__r.Type = 'DemoCrewPlunge' or
			 donation_split__Opportunity__r.Type = ' CollegeCrew') and
													  donation_split__Designation__r.Dimension3_Project__c = null];


			List<donation_split__Designation_Budget__c> bugets = [SELECT Id, Receiptable_Amount_GL__c,
																donation_split__Designation__r.Dimension_1__c,
																  donation_split__Designation__r.Dimension2_Department__c,
																  donation_split__Designation__r.Dimension3_Project__c,
																  donation_split__Designation__r.Dimension4_Cost_Center__c,
																  donation_split__Designation__r.Name, donation_split__Opportunity__c,
																  donation_split__Opportunity__r.Amount, donation_split__Amount__c,
																  donation_split__Opportunity__r.Journal_Lines_To_Create__c,
																  donation_split__Opportunity__r.kell6_core__Receiptable_Amount__c,
																  donation_split__Opportunity__r.kell6_core__Benefit_Value__c,
																  Benefit_Value_On_Opportunity__c, Benefit_Value_GL__c
																  FROM donation_split__Designation_Budget__c where donation_split__Opportunity__c
																  IN :oppsWithJournalLinesToCreate order by donation_split__Opportunity__c];

			for (donation_split__Designation_Budget__c buget : bugets)
			{
				if (!bugetsByOpps.containsKey(buget.donation_split__Opportunity__c))
				{
					bugetsByOpps.put(buget.donation_split__Opportunity__c, new List<donation_split__Designation_Budget__c> ());
				}
				bugetsByOpps.get(buget.donation_split__Opportunity__c).add(buget);
			}


			for (donation_split__Designation_Budget__c hasEmptyProject : hasEmptyProjects)
			{
				if (!donationSplitDBudgetPerOppId.contains(hasEmptyProject.donation_split__Opportunity__c))
				{
					donationSplitDBudgetPerOppId.add(hasEmptyProject.donation_split__Opportunity__c);
				}
			}



			Map<Idea, integer> lineItemCountPerJurnalId = new Map<Idea, integer> ();
			//The opportunity size to process is only one
			for (Opportunity opp : scope)
			{
				if (opp.Journal_Lines_To_Create__c< 1)
				{
					if (opp.Account.type != 'Government' && opp.Account.Type != 'Charity/Foundation')
					{
						//Create Journal
					

						
						List<c2g__codaJournalLineItem__c> lItems = JournalHelper.generateJournalLineItems(opp, null, null, dimensions1PerOppSiteMap, BankFundationEntries, BankAccountRef);
						AddLinesToBatch(lItems, opp, journalsPerBatchManagerMap);
						
						//opp.Journal_Header__c = journalsPerBatchManagerMap.get(opp.npsp__Batch__c).getCurrentJournal();
						opp.GL_Post_Status__c = POSTED_OPPORTUNITY_STAGE;
						opp.Journal_Header_Posted_Date__c = Date.today();

						
					
					}
				}
				else
				{
					//We has a project for all the desgnation budget
					if (!donationSplitDBudgetPerOppId.contains(opp.id))
					{

					
						List<c2g__codaJournalLineItem__c> lItems = new List<c2g__codaJournalLineItem__c>();

						for (donation_split__Designation_Budget__c budget : bugetsByOpps.get(opp.id))
						{
								lItems.addAll(JournalHelper.generateJournalLineItems(opp, null, budget, dimensions1PerOppSiteMap, BankFundationEntries, BankAccountRef));
							

							if (budget.Receiptable_Amount_GL__c ==
								'Donations - Not Able to Tax Receipt (Insufficient information or donor request)' ||
								budget.Benefit_Value_GL__c ==
								'Donations - Not Able to Tax Receipt (Insufficient information or donor request)')
							{
								Task t = new Task();
								t.OwnerId = EROwnerId;
								t.Subject = 'Donations - Not Able to Tax Receipt (Insufficient information or donor request)';

								tasksToCreate.add(t);
							}

						}
						if(!lItems.isEmpty())
						{
							AddLinesToBatch(lItems, opp, journalsPerBatchManagerMap);
							
						}
					
						opp.GL_Post_Status__c = POSTED_OPPORTUNITY_STAGE;
						opp.Journal_Header_Posted_Date__c = Date.today();
					
					}
				}
			}


		
			for(Id batchId : batchesId)
			{
				if(journalsPerBatchManagerMap.containsKey(batchId))
				{
					List<DonationsToJournalBatch.JournalAndItems> jAndIs =  journalsPerBatchManagerMap.get(batchId).journalsAndLineItems;
					integer index = 0;
					for(DonationsToJournalBatch.JournalAndItems jAndI : jAndIs)
					{
						index++;
						if(jAndI.journal.Id == null)
						{
						
							jAndI.journal.c2g__Reference__c = JOURNAL_REFERENCE + Date.today() + ' - Part ' + index + 'of ' + jAndIs.size();
							jAndI.journal.c2g__OwnerCompany__c = mustardSeedCompany.Id;
							jAndI.journal.c2g__JournalDescription__c = JOURNAL_REFERENCE + Date.today() +' - Part ' + index + 'of ' + jAndIs.size() + ' - Batch: ' + batchNames.get(batchId).Name;
							journals2Insert.add(jAndI.journal);

						
						}
					}		
				}
			}
			System.debug('journals2Insert: '+journals2Insert.size());
			insert journals2Insert;


			for(Id batchId : batchesId)
			{
				if(journalsPerBatchManagerMap.containsKey(batchId))
				{
					List<DonationsToJournalBatch.JournalAndItems> jAndIs =  journalsPerBatchManagerMap.get(batchId).journalsAndLineItems;
				
					for(DonationsToJournalBatch.JournalAndItems jAndI : jAndIs)
					{
						for(Opportunity opp: jAndI.opps)
						{
							if(opp.Journal_Header__c == null)
							{
								opp.Journal_Header__c = jAndI.journal.Id;
								oppsToUpdate.add(opp);
						
							}
						}
					
						for(c2g__codaJournalLineItem__c lineItem : jAndI.items)
						{
							if(lineItem.c2g__Journal__c == null)
							{
								lineItem.c2g__Journal__c = jAndI.journal.Id;	
								journalLineItems.add(lineItem);
							}
						}
					}
				}
			}
	
		
			update oppsToUpdate;
			insert journalLineItems;
			insert tasksToCreate;
		}
		catch(Exception e)
		{
			for(Id batchId : batchesId)
			{
				if(journalsPerBatchManagerMap.containsKey(batchId))
				{
					journalsPerBatchManagerMap.get(batchId).errorMessage = e.getMessage();
				}
			}
		}
		
	}

	/**
	 * @author lv@nubik.ca
	 * @date 06/01/2017
	 * @description Method to be executed when the batch finish
	 */
	global void finish(Database.BatchableContext context)
	{
		System.debug(':::[DonationsToJournalBatch finish]::: journalPerOpp -> ' + journalsPerOpp);
		//if (journalsPerOpp != null)
		//{
		//JournalLineItemsBatch lineItems = new JournalLineItemsBatch(journalsPerOpp);
		//Database.executeBatch(lineItems,50);
		//}
		List<npsp__Batch__c> batchesInJob = new List<npsp__Batch__c>();
		System.debug('journalsPerBatchManagerMap.keySet: ' + journalsPerBatchManagerMap.keySet());
		for(Id batchInJob : journalsPerBatchManagerMap.keySet() )
		{
			npsp__Batch__c batch = new npsp__Batch__c();
			batch.id = batchInJob;
			batch.Job_Id__c = null;
			batch.Error__c=journalsPerBatchManagerMap.get(batchInJob).errorMessage;
			if(String.isBlank(batch.Error__c))
			{
				batch.npsp__Batch_Status__c = 'Posted';
			}
			batchesInJob.add(batch); 
		}
			
		if(!batchesInJob.isEmpty())
		{
			update batchesInJob;
		}

		System.debug('newJ: ' + newJ);
	}
}