/* **************************************************************************
 * Class: BatchViewControllerTest
 * Created by Jordan ojeda, 08/24/2018
 *
 * Purpose/Methods: unit test for the trigger ShareDetailsTrigger
 *
 * Modifications:
 * - {DevName}, {MM/DD/YYYY} : {Description of changes made post deployment to client}
 ************************************************************************** */
@isTest
public class BatchViewControllerTest 
{
	static List<Opportunity> opportunitiesForTesting = new List<Opportunity>();
	static Account accountForTesting;
	static List<npsp__Batch__c> batchesForTesting = new List<npsp__Batch__c>();
	static List<donation_split__Designation_Budget__c> budgetsForTesting = new List<donation_split__Designation_Budget__c>();
	static donation_split__Designation__c designation;
	static donation_split__Budget_Year__c year;







	/**
		* @description creating accounts for Testing
		* @author Developer, 01/01/2017
		*/
	public static void createYearBudgetForTesting()
	{
		year = (donation_split__Budget_Year__c)TestFactory.createSObject(new donation_split__Budget_Year__c());
		insert year;
	}

	public static void createSettings()
	{
		


		
	}




	/**
	* @description creating Batches for Testing
	* @author Jordan ojeda, 08/23/2018
	*/
	public static void createBatchesForTesting(integer quantity)
	{
		batchesForTesting = TestFactory.createSObjectList(new npsp__Batch__c(), quantity);
		for(npsp__Batch__c batchForTesting : batchesForTesting)
		{
			batchForTesting.npsp__Object_Name__c = 'Opportunity';
			batchForTesting.Name='test';

		}
		
		insert batchesForTesting;
	}

	/**
	* @description creating opportunities for Testing
	* @author Jordan ojeda, 08/23/2018
	*/
	public static void createOpportunitiesForTesting(integer quantity)
	{
		Integer index = 0;
		opportunitiesForTesting = TestFactory.createSObjectList(new Opportunity(), quantity * batchesForTesting.size());

		for(Integer i = 0 ; i < quantity; i++)
		{
			for(npsp__Batch__c batchForTesting : batchesForTesting)
			{
				opportunitiesForTesting[index].npsp__Batch__c = batchForTesting.Id;
				opportunitiesForTesting[index].AccountId = accountForTesting.id;
				opportunitiesForTesting[index].Amount= 1000;
				opportunitiesForTesting[index].CloseDate = Date.newInstance(2090, 12, 01);
				opportunitiesForTesting[index].StageName='Received';
				opportunitiesForTesting[index].Type='Cash';
				opportunitiesForTesting[index].Gift_Channel__c= 'Online';
				opportunitiesForTesting[index].Payment_Method__c = 'Cash';
			}
			index++;
		}

		insert opportunitiesForTesting;
	}

	
	/**
	* @description creating opportunities for Testing
	* @author Jordan ojeda, 08/23/2018
	*/
	public static void createBudgetsForTesting(integer quantity)
	{
		Integer index = 0;
		budgetsForTesting = TestFactory.createSObjectList(new donation_split__Designation_Budget__c(), quantity * opportunitiesForTesting.size());

		for(Integer i = 0 ; i < quantity; i++)
		{
			for(Opportunity opportunitieForTesting : opportunitiesForTesting)
			{
				budgetsForTesting[index].donation_split__Opportunity__c = opportunitieForTesting.Id;
				budgetsForTesting[index].donation_split__Amount__c= 500;
				budgetsForTesting[index].donation_split__Budget_Year__c = year.id;
				budgetsForTesting[index].donation_split__Designation__c = designation.id;
				index++;
			}
			
		}

		insert budgetsForTesting;
	}



	



	/**
	* @description creating Data
	* @author Jordan ojeda, 08/23/2018
	*/
	public static void createData1()
	{
		createSettings();
		setup();
		createYearBudgetForTesting();
		//createAccountForTesting();
		createBatchesForTesting(1);
		createOpportunitiesForTesting(1);
		createBudgetsForTesting(2);
	}






	static void setup()
	{
		RecordType rt = [Select id from RecordType where DeveloperName = 'Donation' 
				and sObjectType = 'Opportunity' limit 1];
		Group testGroup = new Group(Name='test group', Type='Queue');
		insert testGroup;
		QueuesObject testQueue ; 
		System.runAs(new User(Id=UserInfo.getUserId()))
		{
			List<queuesobject >  listQueue = new List<queuesobject >();
			queuesobject q1 = new queuesobject (queueid=testGroup.id, sobjecttype='Case'); 
			listQueue.add(q1);
			queuesobject q2 = new queuesobject (queueid=testGroup.id, 
					sobjecttype='c2g__codaAccountingCurrency__c'); 
			listQueue.add(q2);
			queuesobject q3 = new queuesobject (queueid=testGroup.id,
					sobjecttype='c2g__codaPurchaseInvoice__c'); 
			listQueue.add(q3);
			queuesobject q4 = new queuesobject (queueid=testGroup.id, 
					sobjecttype='c2g__codaCompany__c'); 
			listQueue.add(q4);
			queuesobject q5 = new queuesobject (queueid=testGroup.id, 
					sobjecttype='c2g__codaYear__c'); 
			listQueue.add(q5);
			queuesobject q6 = new queuesobject (queueid=testGroup.id, 
					sobjecttype='c2g__codaInvoice__c'); 
			listQueue.add(q6);
			queuesobject q7 = new queuesobject (queueid=testGroup.id, 
					sobjecttype='c2g__codaJournal__c'); 
			listQueue.add(q7);
			queuesobject q8 = new queuesobject (queueid=testGroup.id, 
					sobjecttype='c2g__codaBankAccount__c'); 
			listQueue.add(q8);
			insert listQueue;
			GroupMember GroupMemberObj = new GroupMember();
			GroupMemberObj.GroupId = testGroup.id;
			GroupMemberObj.UserOrGroupId = UserInfo.getUserId();
			insert GroupMemberObj;
		}
		c2g__codaCompany__c company = new c2g__codaCompany__c();
		company.Name = 'The Mustard Seed Foundation';
		company.c2g__CashMatchingCurrencyMode__c = 'Test Account';
		company.c2g__YearEndMode__c = 'Test Code';
		company.c2g__ExternalId__c = 'ABCDE1234567876';
		company.c2g__LogoURL__c ='ww.XYZ.com';
		company.c2g__ECCountryCode__c = 'AE' ;
		company.c2g__VATRegistrationNumber__c = 'Test 222.222.222 TVA' ;
		company.c2g__Website__c = 'ww.xyz.com';
		company.c2g__Country__c ='US';
		company.ownerid = testGroup.Id;
		insert company;
		c2g__codaYear__c yr = new c2g__codaYear__c();
		yr.Name ='2015';
		yr.c2g__AutomaticPeriodList__c =  true;
		yr.c2g__OwnerCompany__c = company.id;
		yr.c2g__ExternalId__c = 'yzsd1234';
		yr.c2g__NumberOfPeriods__c =11;
		yr.c2g__StartDate__c =  system.today() - 10;
		yr.c2g__Status__c = 'Open';
		yr.c2g__PeriodCalculationBasis__c = '445';
		yr.c2g__YearEndMode__c = 'Full Accounting Code' ; 
		yr.c2g__UnitOfWork__c = 12;
		yr.ownerid = testGroup.Id;
		insert yr;

		List<c2g__codaGeneralLedgerAccount__c> glas = new List<c2g__codaGeneralLedgerAccount__c>();
		c2g__codaGeneralLedgerAccount__c cglAcc = new c2g__codaGeneralLedgerAccount__c();
		cglAcc.Name = '1020 - Foundation - ATB - Chequing';
		cglAcc.c2g__ReportingCode__c='1020';
		cglAcc.c2g__Type__c='Balance Sheet';
		glas.add(cglAcc);

		c2g__codaGeneralLedgerAccount__c cglAcc2 = new c2g__codaGeneralLedgerAccount__c();
		cglAcc2.Name = '4000 - Revenue - Donation';
		cglAcc2.c2g__ReportingCode__c='4000';
		cglAcc2.c2g__Type__c='Profit and Loss';

		glas.add(cglAcc2);
		insert glas;

	

		c2g__codaPeriod__c prd = new c2g__codaPeriod__c();
		prd.Name ='Test2015';
		prd.c2g__ExternalId__c ='abdc12345';
		prd.c2g__StartDate__c = System.today()-10;
		prd.c2g__EndDate__c= System.today()+10;
		prd.c2g__OwnerCompany__c = company.id;
		prd.c2g__PeriodNumber__c ='123';
		prd.c2g__Description__c ='test Desc';
		prd.c2g__PeriodGroup__c = 'Q1';
		prd.c2g__PeriodNumber__c = '1';
		prd.c2g__YearName__c = yr.id;
		insert prd;

		c2g__codaUserCompany__c userCompany = new c2g__codaUserCompany__c();
		userCompany.c2g__Company__c =company.id;
		userCompany.c2g__User__c = userInfo.getUserId();
		userCompany.c2g__ExternalId__c = 'ABCDE1234567876';
		userCompany.c2g__UnitOfWork__c = 111 ;
		insert userCompany;

		c2g__codaAccountingCurrency__c accCurrency = new c2g__codaAccountingCurrency__c();
		accCurrency.c2g__OwnerCompany__c = company.id;
		accCurrency.c2g__DecimalPlaces__c = 2;
		accCurrency.Name = 'CAD';
		accCurrency.c2g__Dual__c = true ;
		accCurrency.c2g__Home__c = true ;
		accCurrency.ownerid = testGroup.Id;
		insert accCurrency;

		c2g__codaBankAccount__c ba = new c2g__codaBankAccount__c();
		ba.c2g__ReportingCode__c='1020';
		ba.Name='1020 - Foundation - ATB - Chequing';
		ba.c2g__BankName__c='ATB';
		ba.c2g__AccountName__c='Foundation Chequing';
		ba.c2g__AccountNumber__c = '760-00039290100';
		ba.OwnerId = testGroup.Id;
		ba.c2g__GeneralLedgerAccount__c=cglAcc.id;
		ba.c2g__BankAccountCurrency__c=accCurrency.id;
		insert ba;

		//c2g__codaExchangeRate__c exchRate = new c2g__codaExchangeRate__c();
		//exchRate.c2g__ExchangeRateCurrency__c = accCurrency.id;
		//exchRate.c2g__OwnerCompany__c = company.id;
		//exchRate.c2g__ExternalId__c ='12323232';
		//exchRate.c2g__Rate__c =44.55;
		//exchRate.c2g__StartDate__c = system.today()-10;
		//exchRate.c2g__UnitOfWork__c =10;
		//insert exchRate;  
		
		kell6_core__Receipt_Settings__c rSetting = new kell6_core__Receipt_Settings__c();
		rSetting.kell6_core__Mapping_Class__c = 'kell6_cp.ReceiptingMapping_CnP';
		rSetting.kell6_core__Receiptable_Object_Recurring__c = 'CnP_PaaS__CnPRecurring__c';
		insert rSetting;

		npsp__Opportunity_Naming_Settings__c oppSetting = 
				new npsp__Opportunity_Naming_Settings__c();
		oppSetting.Name = '29/11/2016 10:50 AM';
		oppSetting.npsp__Attribution__c = 'Both';
		oppSetting.npsp__Date_Format__c = 'yyyy-MM-dd';
		insert oppSetting;

		accountForTesting = new Account();
		accountForTesting.Name = 'AccountTest';
        accountForTesting.c2g__CODAAccountTradingCurrency__c = 'CAD';
		
		insert accountForTesting;
		
		Opportunity opp = new Opportunity();
		opp.Name = 'Test';
		opp.CloseDate = Date.today().addDays(10);
		opp.StageName = 'Received';
		opp.Gift_Needs_Further_Attention__c = false;
		opp.Journal_Header__c = null;
		opp.Amount = 10;
		opp.kell6_core__Benefit_Value__c = 5;
		opp.AccountId = accountForTesting.Id;
		opp.recordTypeId = rt.Id;
		insert opp;

		c2g__codaDimension3__c project = new c2g__codaDimension3__c();
		project.Name = 'Project Name';
		project.c2g__ExternalId__c = '111111';
		project.c2g__ReportingCode__c = '222222';
		project.c2g__UnitOfWork__c = 1;
		insert project;

		designation = new donation_split__Designation__c();
		designation.Name = 'Designation';
		designation.Dimension3_Project__c = project.Id;
		insert designation;

		donation_split__Designation_Budget__c desigBudget = new donation_split__Designation_Budget__c();
		desigBudget.donation_split__Opportunity__c = opp.Id;
		desigBudget.donation_split__Amount__c = 10;
		desigBudget.donation_split__Designation__c = designation.Id;
		insert desigBudget;
	}

	//@istest
	//static void createJournals()
	//{
		//Test.startTest();
		//DonationsToJournalBatch batch = new DonationsToJournalBatch();
		//Database.executeBatch(batch,1);
		//Test.stopTest();
	//}


	@istest
	static void reviewBatch()
	{
		createData1();

		Test.startTest();

		ApexPages.StandardController sc = new ApexPages.StandardController(batchesForTesting[0]);
        DonationsToJournalController controller = new DonationsToJournalController(sc);
		BatchViewController vController = new BatchViewController(sc);

		controller.processBatch();
		vController.verifyStatus();
		Test.stopTest();

		vController.verifyStatus();

		System.assert(vController.posted);

	}


	
}