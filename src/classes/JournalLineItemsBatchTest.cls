/* **************************************************************************
* Test Class: JournalLineItemsBatchTest
* Created by lv@nubik.ca, 06/01/2017
*
* Purpose/Methods:
* - Unit test to cover the class JournalLineItemsBatch
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
@isTest
private class JournalLineItemsBatchTest 
{
	@testSetup static void setup()
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
		accCurrency.Name = 'AED';
		accCurrency.c2g__Dual__c = true ;
		accCurrency.ownerid = testGroup.Id;
		insert accCurrency;

		c2g__codaExchangeRate__c exchRate = new c2g__codaExchangeRate__c();
		exchRate.c2g__ExchangeRateCurrency__c = accCurrency.id;
		exchRate.c2g__OwnerCompany__c = company.id;
		exchRate.c2g__ExternalId__c ='12323232';
		exchRate.c2g__Rate__c =44.55;
		exchRate.c2g__StartDate__c = system.today()-10;
		exchRate.c2g__UnitOfWork__c =10;
		insert exchRate;  
		
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

		c2g__codaGeneralLedgerAccount__c gLedger = new c2g__codaGeneralLedgerAccount__c();
		gLedger.Name = '1020 - Foundation - ATB - Chequing';
		gLedger.c2g__ReportingCode__c = '1020';
		gLedger.c2g__BalanceSheet1__c ='Balance Sheet'; 
		gLedger.c2g__ExternalId__c ='testID2';
		gLedger.c2g__UnitOfWork__c =123;
		gLedger.c2g__TrialBalance1__c = 'Balance Sheet' ;
		gLedger.c2g__Type__c = 'Balance Sheet';
		insert gLedger;
        
        c2g__codaGeneralLedgerAccount__c gLedger2 = new c2g__codaGeneralLedgerAccount__c();
		gLedger2.Name = 'FoundationChequing';
		gLedger2.c2g__BalanceSheet1__c ='Balance Sheet'; 
		gLedger2.c2g__ExternalId__c ='test2ID';
		gLedger2.c2g__ReportingCode__c = '1234567543334';
		gLedger2.c2g__UnitOfWork__c =124;
		gLedger2.c2g__TrialBalance1__c = 'Balance Sheet' ;
		gLedger2.c2g__Type__c = 'Balance Sheet';
		insert gLedger2;

		Account a = new Account();
		a.Name = 'AccountTest';
        a.c2g__CODAAccountTradingCurrency__c = 'AED';
		insert a;
		
		Opportunity opp = new Opportunity();
		opp.Name = 'Test';
		opp.CloseDate = Date.today().addDays(10);
		opp.StageName = 'Received';
		opp.Gift_Needs_Further_Attention__c = false;
		opp.Journal_Header__c = null;
		opp.Amount = 10;
		opp.kell6_core__Benefit_Value__c = 5;
		opp.AccountId = a.Id;
		opp.recordTypeId = rt.Id;
		insert opp;

		c2g__codaDimension3__c project = new c2g__codaDimension3__c();
		project.Name = 'Project Name';
		project.c2g__ExternalId__c = '111111';
		project.c2g__ReportingCode__c = '222222';
		project.c2g__UnitOfWork__c = 1;
		insert project;

		donation_split__Designation__c designation = new donation_split__Designation__c();
		designation.Name = 'Designation';
		designation.Dimension3_Project__c = project.Id;
		insert designation;

		donation_split__Designation_Budget__c desigBudget = 
				new donation_split__Designation_Budget__c();
		desigBudget.donation_split__Opportunity__c = opp.Id;
		desigBudget.donation_split__Amount__c = 10;
		desigBudget.donation_split__Designation__c = designation.Id;
		desigBudget.Receiptable_Amount_GL__c = 'FoundationChequing';
		desigBudget.Benefit_Value_GL__c = 'FoundationChequing';
		insert desigBudget;
	}

	@istest
	static void createJournals()
	{
		Map<Id,Map<Id,Integer>> oppPerJournal = new Map<Id,Map<Id,Integer>>();
		Id oppId = [Select Id from Opportunity where Name = 'Test' limit 1].Id;
		Map<Id,Integer> journals = new Map<Id,Integer>();
		journals.put(oppId,0);
		oppPerJournal.put(oppId,journals);

		Test.startTest();
		JournalLineItemsBatch batch = new JournalLineItemsBatch(oppPerJournal);
		Database.executeBatch(batch/*,1*/);
		Test.stopTest();
	}
}