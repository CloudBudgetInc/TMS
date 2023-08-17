public with sharing class trigger_TestData extends test_Data
{
    public c2g__codaCompany__c company1 { get; set; }
    public ffirule__IntegrationRule__c rule1 { get; set; }
    public c2g__codaJournal__c journal1 { get; set; }
    public npsp__Batch__c batch1 { get; set; }

    public trigger_TestData() 
    {
        super();

        Trigger_Settings__c settings = new Trigger_Settings__c();
        settings.Batch_Trigger_Enabled__c = true;
        insert settings;

        Group testGroup = new Group(Name='test group', Type='Queue');
		insert testGroup;

        RecordType rt = [Select id from RecordType where DeveloperName = 'Donation' 
			and sObjectType = 'Opportunity' limit 1];

        setupQueue(testGroup);

        company1 = new c2g__codaCompany__c();
        company1.Name = 'The Mustard Seed Foundation';
		company1.c2g__CashMatchingCurrencyMode__c = 'Test Account';
		company1.c2g__YearEndMode__c = 'Test Code';
		company1.c2g__ExternalId__c = 'ABCDE1234567876';
		company1.c2g__LogoURL__c ='ww.XYZ.com';
		company1.c2g__ECCountryCode__c = 'AE' ;
		company1.c2g__VATRegistrationNumber__c = 'Test 222.222.222 TVA' ;
		company1.c2g__Website__c = 'ww.xyz.com';
		company1.c2g__Country__c ='US';
		company1.ownerid = testGroup.Id;
        insert company1;

        c2g__codaYear__c yr = new c2g__codaYear__c();
		yr.Name ='2015';
		yr.c2g__AutomaticPeriodList__c =  true;
		yr.c2g__OwnerCompany__c = company1.id;
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
		prd.c2g__OwnerCompany__c = company1.id;
		prd.c2g__PeriodNumber__c ='123';
		prd.c2g__Description__c ='test Desc';
		prd.c2g__PeriodGroup__c = 'Q1';
		prd.c2g__PeriodNumber__c = '1';
		prd.c2g__YearName__c = yr.id;
		insert prd;

		c2g__codaUserCompany__c userCompany = new c2g__codaUserCompany__c();
		userCompany.c2g__Company__c =company1.id;
		userCompany.c2g__User__c = userInfo.getUserId();
		userCompany.c2g__ExternalId__c = 'ABCDE1234567876';
		userCompany.c2g__UnitOfWork__c = 111 ;
		insert userCompany;

        c2g__codaAccountingCurrency__c accCurrency = new c2g__codaAccountingCurrency__c();
		accCurrency.c2g__OwnerCompany__c = company1.id;
		accCurrency.c2g__DecimalPlaces__c = 2;
		accCurrency.Name = 'AED';
		accCurrency.c2g__Dual__c = true ;
		accCurrency.ownerid = testGroup.Id;
		insert accCurrency;

		c2g__codaExchangeRate__c exchRate = new c2g__codaExchangeRate__c();
		exchRate.c2g__ExchangeRateCurrency__c = accCurrency.id;
		exchRate.c2g__OwnerCompany__c = company1.id;
		exchRate.c2g__ExternalId__c ='12323232';
		exchRate.c2g__Rate__c =44.55;
		exchRate.c2g__StartDate__c = system.today()-10;
		exchRate.c2g__UnitOfWork__c =10;
		insert exchRate;  

        Account a = new Account();
		a.Name = 'AccountTest';
        a.c2g__CODAAccountTradingCurrency__c = 'AED';
		insert a;
		
        //company1.c2g__IntercompanyAccount__c = a.Id;
        //update company1;

        rule1 = new ffirule__IntegrationRule__c();
        rule1.ESI_Queued_CL_Process_Identifier__c = 'ESi_CL_Batch_Journal_Id__c';
        rule1.ESI_Queued_CL_Process_Include__c = true;
        rule1.ESI_Queued_CL_Process_Source_Trigger_LNK__c = 'Id';
        rule1.ffirule__SourceObject__c = 'npsp__Batch__c';
        rule1.ffirule__SourceObjectProcessField__c = 'ESi_CL_Control_JNL_DR_Line_OK__c';
        rule1.ffirule__SourceObjectNameField__c = 'Name';
        rule1.ffirule__TargetObject__c = 'c2g__codaJournalLineItem__c';
        rule1.ffirule__TargetObjectNameField__c = 'Name';
        insert rule1;

        batch1 = new npsp__Batch__c();
        batch1.ESi_CL_Control_Batch_Processed__c = false;
        //batch1.ESi_Journal__c = journal1.Id;
        batch1.npsp__Object_Name__c = 'Opportunity';
        insert batch1;

        journal1 = new c2g__codaJournal__c();
        journal1.ESi_Batch__c = batch1.Id;
        //journal1.c2g__OwnerCompany__c = company1.Id;
        journal1.c2g__JournalCurrency__c = accCurrency.Id;
        insert journal1;

        batch1.ESi_Journal__c = journal1.Id;
        update batch1;
    }

    private void setupQueue(Group testGroup)
    {
        QueuesObject testQueue;

		System.runAs(new User(Id = UserInfo.getUserId()))
		{
			List<queuesobject >  listQueue = new List<queuesobject >();
			queuesobject q1 = new queuesobject (queueid=testGroup.id, sobjecttype='Case'); 
            queuesobject q2 = new queuesobject (queueid=testGroup.id, sobjecttype='c2g__codaAccountingCurrency__c'); 
            queuesobject q3 = new queuesobject (queueid=testGroup.id, sobjecttype='c2g__codaPurchaseInvoice__c'); 
            queuesobject q4 = new queuesobject (queueid=testGroup.id, sobjecttype='c2g__codaCompany__c');
            queuesobject q5 = new queuesobject (queueid=testGroup.id, sobjecttype='c2g__codaYear__c'); 
            queuesobject q6 = new queuesobject (queueid=testGroup.id, sobjecttype='c2g__codaInvoice__c'); 

			listQueue.add(q1);
			listQueue.add(q2);
			listQueue.add(q3);
			listQueue.add(q4);
			listQueue.add(q5);
			listQueue.add(q6);

			insert listQueue;

			GroupMember GroupMemberObj = new GroupMember();
			GroupMemberObj.GroupId = testGroup.id;
			GroupMemberObj.UserOrGroupId = UserInfo.getUserId();
			insert GroupMemberObj;
		}
    }
}