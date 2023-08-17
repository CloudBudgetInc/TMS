/* **************************************************************************
  * Helper Class: JournalHelper
  * Created by lv@nubik.ca, 07/04/2017
  *
  * Purpose/Methods:
  * - Create Journal Header from Opportunity. 
  * - The class is referenced from the classes DonationToJournalBatch and 
  * JournalLineItemsBatch
  *
  * Unit Test: JournalHelperTest
  *
  * Modifications:
  * - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
  * - Jordan ojeda, 05/07/2018 - Adding the methods getOpportunitiesRelated and processOpportunities
  ************************************************************************** */
public class JournalHelper
{
	public static final String LINE_TYPE = 'General Ledger Account';
	//by Jordan ojeda: GL 1020 entries must be "Bank Account" and not "General Ledger Account"
	public static final String LINE_TYPE_1020 = 'Bank Account';
	public static final String JOURNAL_REFERENCE = 'Donations To Journal Process - ';
	public static final String POSTED_OPPORTUNITY_STAGE = 'Posted';
	public static final Integer MAX_ITEMS_PER_JOURNAL = 250;
	/**
	 * @author lv@nubik.ca
	 * @date
	 * @description
	 */
	public static c2g__codaJournalLineItem__c journalLineItem(Id oppId,
	                                                          Id journalId, Id refAccount, Decimal valueLineItem, string lineType,
	                                                          Id dimension2, Id dimension3, Id dimension1, String lineDescription,
	                                                          string paymenttype, string batch, Id BankAccountRef)
	{
		c2g__codaJournalLineItem__c journalLineItem =
		new c2g__codaJournalLineItem__c();
		//by Jordan ojeda: this new parameter is added since GL 1020 must be "Bank Account" and not "General Ledger Account"
		journalLineItem.c2g__LineType__c = lineType;
		journalLineItem.c2g__Dimension2__c = dimension2;
		journalLineItem.c2g__Dimension3__c = dimension3;
		//by Jordan ojeda:  we were mapping to Dimension 4, but it was needed to be moved to Dimension 1 instead.
		//journalLineItem.c2g__Dimension4__c = dimension4;
		journalLineItem.c2g__Dimension1__c = dimension1;
		journalLineItem.Opportunity__c = oppId;
		journalLineItem.c2g__Journal__c = journalId;
		journalLineItem.c2g__GeneralLedgerAccount__c = refAccount;
		if(lineType == LINE_TYPE_1020)
		{
			journalLineItem.c2g__BankAccount__c = BankAccountRef;
		}
		journalLineItem.c2g__Value__c = valueLineItem.setScale(2);
		journalLineItem.c2g__LineDescription__c = lineDescription;
		journalLineItem.Payment_Type__c = paymenttype;
		journalLineItem.Batch__c = batch;
		return journalLineItem;
	}

	/**
	 * @author lv@nubik.ca
	 * @date
	 * @description
	 */
	public static List<c2g__codaJournalLineItem__c> generateJournalLineItems(
	                                                                         Opportunity opp, Id journalId, donation_split__Designation_Budget__c budget, Map<String, c2g__codaDimension1__c> dimensions1PerOppSiteMap, Map<Id, c2g__codaJournalLineItem__c> BankFundationEntries, ID bankAccountRef)
	{
		List<c2g__codaJournalLineItem__c> journalLineItems =
		new List<c2g__codaJournalLineItem__c> ();
		Decimal valueLineItem = 0;
		Decimal valueLineItemBenefit = 0;
		String lineDescription = '';
		String lineDescriptionBenefit = '';
		Id dimension2 = null;
		Id dimension3 = null;
		Id dimension4 = null;
		Id dimension1 = null;
		if (budget == null)
		{
			//dimension4 = [Select id from c2g__codaDimension4__c where Name = :opp.Site__c].Id;
			//dimension4 = [Select id from c2g__codaDimension4__c where Name = :opp.Site__c].Id;
			if (dimensions1PerOppSiteMap != null && dimensions1PerOppSiteMap.containsKey(opp.Site__c))
			{
				dimension1 = dimensions1PerOppSiteMap.get(opp.Site__c).id;
			}
			System.debug(dimension4);
			valueLineItem = opp.kell6_core__Receiptable_Amount__c;
			valueLineItemBenefit = opp.kell6_core__Benefit_Value__c;

			lineDescription = opp.Name;

			System.debug(valueLineItem);
		}
		else
		{
			//dimension4 = budget.donation_split__Designation__r.Dimension4_Cost_Center__c;
			dimension2 = budget.donation_split__Designation__r.Dimension2_Department__c;
			dimension3 = budget.donation_split__Designation__r.Dimension3_Project__c;
			dimension1 = budget.donation_split__Designation__r.Dimension_1__c;
			valueLineItem = (budget.donation_split__Amount__c *
			                 budget.donation_split__Opportunity__r.kell6_core__Receiptable_Amount__c) /
			budget.donation_split__Opportunity__r.Amount;
			//lineDescription = budget.donation_split__Designation__r.Name + ' - ' +
			//budget.donation_split__Opportunity__r.kell6_core__Receiptable_Amount__c;

			lineDescription = budget.donation_split__Designation__r.Name + ' - ' +
			budget.donation_split__Opportunity__r.kell6_core__Receiptable_Amount__c + ' - ' + opp.Name;


			Decimal benefitValue = 0;
			if (budget.donation_split__Opportunity__r.kell6_core__Benefit_Value__c != null &&
			    budget.donation_split__Opportunity__r.kell6_core__Benefit_Value__c != 0)
			benefitValue = budget.donation_split__Opportunity__r.kell6_core__Benefit_Value__c;

			//lineDescriptionBenefit = budget.donation_split__Designation__r.Name + ' - ' +
			//benefitValue;

			lineDescriptionBenefit = budget.donation_split__Designation__r.Name + ' - ' +
			benefitValue + ' - ' + opp.Name;

			valueLineItemBenefit = (budget.donation_split__Amount__c *
			                        benefitValue) /
			budget.donation_split__Opportunity__r.Amount;
			if (opp == null)
			{
				opp = [Select Id, Journal_Lines_To_Create__c, Designation_Line_Number__c,
				       Account.Type, Type, Tax_Receiptable__c, Site__c,
				       kell6_cp__Ready_To_Print__c, kell6_core__Benefit_Value__c,
				       kell6_core__Receiptable_Amount__c,
				       npsp__Batch__r.Name, CnP_PaaS__CnP_OrderNumber__r.Name,
				       CnP_PaaS__CnP_Payment_Type__c
				       from Opportunity where
				       Id = :budget.donation_split__Opportunity__c limit 1];

			}
		}
		Id ATBChecking = [Select Id from c2g__codaGeneralLedgerAccount__c where
		                  c2g__ReportingCode__c = '1020'].Id;
		//String glDescription = getGLDescription(opp, false);
		String glDescription = getGLDescriptionCode(opp, false);
		System.debug('glDescription: ' + glDescription);
		Id generalLedgerAccount = [Select Id from c2g__codaGeneralLedgerAccount__c
		                           where c2g__ReportingCode__c = :glDescription limit 1].Id;

		String pt = (opp != null) ? opp.CnP_PaaS__CnP_Payment_Type__c : '';
		String batch = '';
		if (opp != null && opp.npsp__Batch__r != null && !String.isEmpty(opp.npsp__Batch__r.Name)) {
			batch = opp.npsp__Batch__r.Name;
		} else if (opp != null && opp.CnP_PaaS__CnP_OrderNumber__r != null
		           && !String.isEmpty(opp.CnP_PaaS__CnP_OrderNumber__r.Name)) {
			string subs = opp.CnP_PaaS__CnP_OrderNumber__r.Name.substring(6, 12);
			batch = subs;
		}
		//Credit and debit line items
		//by Joran Ojeda: GL 1020 is positive (a debit in accounting) and the other entries are negative (a credit in accounting)
		//("* -1" was chnaged from the second entry to the fisrt entry)
		c2g__codaJournalLineItem__c journalLineItem = journalLineItem(opp.Id,
		                                                              journalId, generalLedgerAccount, valueLineItem * - 1, LINE_TYPE, dimension2, dimension3,
		                                                              dimension1, lineDescription, pt, batch, null);
		journalLineItems.add(journalLineItem);

		if(BankFundationEntries.containsKey(opp.Id))
		{
			c2g__codaJournalLineItem__c bf = BankFundationEntries.get(opp.Id);
			bf.c2g__Value__c += valueLineItem.setScale(2);
		}
		else
		{
			c2g__codaJournalLineItem__c journalLineItem2 = journalLineItem(opp.Id,
		                                                               journalId, ATBChecking, valueLineItem, LINE_TYPE_1020, null, null,
		                                                               null, lineDescription, pt, batch, bankAccountRef);

			journalLineItems.add(journalLineItem2);
			BankFundationEntries.put(opp.Id, journalLineItem2);
		}
		
		

		//Credit and debit line items for the benefits
		if (opp.kell6_core__Benefit_Value__c != null && opp.kell6_core__Benefit_Value__c != 0)
		{
			//by Joran Ojeda: GL 1020 is positive (a debit in accounting) and the other entries are negative (a credit in accounting)
			//("* -1" was chnaged from the second entry to the fisrt entry)
			//String glDescriptionBenefit = getGLDescription(opp, true);
			String glDescriptionBenefit = getGLDescriptionCode(opp, true);
			Id generalLedgerAccountBenefit = [Select Id from c2g__codaGeneralLedgerAccount__c
			                                  where c2g__ReportingCode__c = :glDescriptionBenefit limit 1].Id;
			c2g__codaJournalLineItem__c journalLineItemBenefit = journalLineItem(opp.Id,
			                                                                     journalId, generalLedgerAccountBenefit, valueLineItemBenefit * - 1, LINE_TYPE,
			                                                                     dimension2, dimension3, dimension1, lineDescriptionBenefit, pt, batch, null);
			journalLineItems.add(journalLineItemBenefit);

			

			//if(BankFundationEntries.containsKey(opp.Id))
			//{
				c2g__codaJournalLineItem__c bf = BankFundationEntries.get(opp.Id);
				bf.c2g__Value__c += valueLineItemBenefit.setScale(2);
			//}
			//else
			//{
				//c2g__codaJournalLineItem__c journalLineItemBenefit2 = journalLineItem(opp.Id,
			                                                                      //journalId, ATBChecking, valueLineItemBenefit, LINE_TYPE_1020,
			                                                                      //null, null, null, lineDescriptionBenefit, pt, batch);

				//journalLineItems.add(journalLineItemBenefit2);
				//BankFundationEntries.put(opp.Id, journalLineItemBenefit2);
			//}


			
			
		}
		System.debug('journalLineItems: ' + journalLineItems);
		return journalLineItems;
	}

	//public static String getGLDescription2(Opportunity opp, Boolean isBenefit)
	//{
		//String glDescription =
		//'4201 - Donations - Not Able to Tax Receipt';
		//if (opp.Account.Type == 'Government')
		//glDescription = '4510 - Capital Contributions - Government';
		//else if (opp.Account.Type == 'Charity/Foundation')
		//glDescription = '4500 - Capital Contributions - Other Charities';
		//else if (opp.Type == 'DemoCrew' || opp.Type == 'DemoCrewPlunge' ||
		         //opp.Type == 'CollegeCrew')
		//glDescription = '4600 - Services Revenue';
		//else if (opp.Account.Type == 'Charity/Foundation' ||
		         //opp.Account.Type == 'Church' || opp.Account.Type == 'School')
		//glDescription = '4100 - Donations - Other Charities';
		////Only check this two for the benefits
		//else if (!isBenefit && (opp.Tax_Receiptable__c == 'Not Receiptable No Acknowledgement' ||
		                        //opp.Tax_Receiptable__c == 'Acknowledge Only End of Year' ||
		                        //opp.Tax_Receiptable__c == 'Acknowledge Only Immediately'))
		//glDescription = '4200 - Donations - Non Tax Reciepted';
		//else if (!isBenefit && (opp.Tax_Receiptable__c == 'Receiptable Immediately' ||
		                        //opp.Tax_Receiptable__c == 'Receiptable End of Year'))
		//glDescription = '4000 - Donations - Tax Receipted';

		//return glDescription;
	//}

	//public static String getGLDescription(Opportunity opp, Boolean isBenefit)
	//{
		//String glDescription =
		//'4201 - Donations - Not Able to Tax Receipt';
		//if(isBenefit)
		//{
			//glDescription = '4200 - Donations - Non Tax Reciepted';
		//}
		//if (opp.Account.Type == 'Government')
		//{
			//glDescription = '4400 - Government Funding';
		//}


		//else if (opp.Account.Type == 'Charity/Foundation')
		//glDescription = '4500 - Capital Contributions - Other Charities';
		//else if (opp.Type == 'DemoCrew' || opp.Type == 'DemoCrewPlunge' ||
		         //opp.Type == 'CollegeCrew')
		//glDescription = '4600 - Services Revenue';
		//else if (opp.Account.Type == 'Charity/Foundation' ||
		         //opp.Account.Type == 'Church' || opp.Account.Type == 'School')
		//glDescription = '4100 - Donations - Other Charities';
		////Only check this two for the benefits
		//else if (!isBenefit && (opp.Tax_Receiptable__c == 'Not Receiptable No Acknowledgement' ||
		                        //opp.Tax_Receiptable__c == 'Acknowledge Only End of Year' ||
		                        //opp.Tax_Receiptable__c == 'Acknowledge Only Immediately'))
		//glDescription = '4200 - Donations - Non Tax Reciepted';
		//else if (!isBenefit && (opp.Tax_Receiptable__c == 'Receiptable Immediately' ||
		                        //opp.Tax_Receiptable__c == 'Receiptable End of Year'))
		//glDescription = '4000 - Revenue - Donation';

		//if(opp.Campaign.Top_Parent__r.name == 'Other Revenue')
		//{
			//glDescription = '4990 - Other Revenue';
		//}
		//else if(opp.Campaign.Top_Parent__r.name == 'Services Revenue')
		//{
			//glDescription = '4600 - Services Revenue';
		//}


		//return glDescription;
	//}

	public static String getGLDescriptionCode(Opportunity opp, Boolean isBenefit)
	{
		String glDescriptionCode ='4201';
		if(isBenefit)
		{
			glDescriptionCode = '4200';
		}
		if (opp.Account.Type == 'Government')
		{
			glDescriptionCode = '4400';
		}


		else if (opp.Account.Type == 'Charity/Foundation')
		{
			glDescriptionCode = '4500';
		}
		else if (opp.Type == 'DemoCrew' || opp.Type == 'DemoCrewPlunge' ||
		         opp.Type == 'CollegeCrew')
		{
			glDescriptionCode = '4600';
		}
		else if (opp.Account.Type == 'Charity/Foundation' ||
		         opp.Account.Type == 'Church' || opp.Account.Type == 'School')
		{
			glDescriptionCode = '4100';
		}
		//Only check this two for the benefits
		else if (!isBenefit && (opp.Tax_Receiptable__c == 'Not Receiptable No Acknowledgement' ||
		                        opp.Tax_Receiptable__c == 'Acknowledge Only End of Year' ||
		                        opp.Tax_Receiptable__c == 'Acknowledge Only Immediately'))
		{
			glDescriptionCode = '4200';
		}
		else if (!isBenefit && (opp.Tax_Receiptable__c == 'Receiptable Immediately' ||
		                        opp.Tax_Receiptable__c == 'Receiptable End of Year'))
		{
			glDescriptionCode = '4000';

		}
		if(opp.Campaign.Top_Parent__r.name == 'Other Revenue')
		{
			glDescriptionCode = '4990';
		}
		else if(opp.Campaign.Top_Parent__r.name == 'Services Revenue')
		{
			glDescriptionCode = '4600';
		}


		return glDescriptionCode;
	}


	/**
	 * @description method to obtain the opportunities associted with a batch record
	 * @author Jordan Ojeda, 07/05/2018
	 */
	public static List<Opportunity> getOpportunitiesRelated(Id batchId)
	{
		//List<Opportunity> opps = [SELECT 
		//Journal_Lines_To_Create__c,
		//Journal_Header__c,
		//GL_Post_Status__c,
		//Journal_Header_Posted_Date__c,
		//Account.Type,
		//kell6_core__Receiptable_Amount__c,
		//kell6_core__Benefit_Value__c,
		//Site__c,
		//CnP_PaaS__CnP_Payment_Type__c,
		//npsp__Batch__r.Name,
		//CnP_PaaS__CnP_OrderNumber__r.name,
		//Type,
		//Tax_Receiptable__c
		//FROM 
		//Opportunity 
		//WHERE 
		//npsp__Batch__c = :batchId];

		//return opps;
		List<Id> ids = new List<Id> ();
		List<Opportunity> opps = [SELECT
		                          Id,
								  npsp__Batch__c
		                          FROM
		                          Opportunity
		                          WHERE
		                          npsp__Batch__c = :batchId AND StageName != 'Declined'];

		//for (Opportunity opp : opps)
		//{
			//ids.add(opp.id);
		//}

		return opps;
	}



	/**
	 * @description method to obtain the opportunities associted with a batch record
	 * @author Jordan Ojeda, 07/05/2018
	 */
	public static boolean wasAlreadyProccessed (Id batchId)
	{
		//return opps;
		integer c = [SELECT COUNT()
		                          FROM
		                          Opportunity
		                          WHERE
		                          npsp__Batch__c = :batchId AND 
								  Create_Journal__c = false AND 
								  StageName != 'Declined'];

		//for (Opportunity opp : opps)
		//{
			//ids.add(opp.id);
		//}

		return c>0;
	}





	/**
	 * @description This method process the specified opportunities from a specific Batch record to create the journals acordingly. 
	 *         This code is an almost an exact copy from the solution base on a batch to process opportunities, this time, not even belonged 
	 *         to the same batch record. The implementation contains some bad practices that have been reported. 
	 *         So far the code is as it used to be but it might change in a near future in order to fix thes bad practices. 
	 * @author Jordan ojeda, 07/05/2018
	 */
	//public static void processOpportunities(List<Opportunity> scope)
	//{
		//List<c2g__codaJournal__c> journals2Insert = new List<c2g__codaJournal__c> ();
		//List<c2g__codaJournalLineItem__c> journalLineItems =
		//new List<c2g__codaJournalLineItem__c> ();

		//c2g__codaCompany__c mustardSeedCompany = [Select Id from c2g__codaCompany__c where Name = 'The Mustard Seed Foundation'];
		//Map<Id, Map<Id, Integer>> journalsPerOpp;

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
					////insert journals2Insert;
					//insert journal;
					//opp.Journal_Header__c = journal.Id;
					////opp.StageName = POSTED_OPPORTUNITY_STAGE;
					//opp.GL_Post_Status__c = POSTED_OPPORTUNITY_STAGE;
					//opp.Journal_Header_Posted_Date__c = Date.today();
					////opp.Create_Journal_Status__c = 'Created';
					//update opp;
					////journalLineItems.addAll(JournalHelper.generateJournalLineItems(opp,
					////       journals2Insert[0].Id,null));

					//journalLineItems.addAll(JournalHelper.generateJournalLineItems(opp,
					                                                               //journal.Id, null, null, null, null));
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
}