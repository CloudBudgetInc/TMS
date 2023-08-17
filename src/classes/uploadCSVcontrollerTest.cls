@isTest
public class uploadCSVcontrollerTest {
    @isTest static void TestloadingNormalSCV() {
        
        List<Expense_Report__c> ERL = new List<Expense_Report__c>();
 		Expense_Report__c ER = new Expense_Report__c();
        
        Department__c dep = new Department__c(Name='TestDep');
        insert dep;
        List<Account> accs= New Account[]{new Account(Name='TestAcc1', Approval_Department__c=dep.id,Email__c='test@email.com',MC__c='8932'),new Account(Name='TestAcc2', Approval_Department__c=dep.id,Email__c='test1@email.com',MC__c='3735')};
        insert accs;    
        
        String TestCSV='Transaction Date,Account Rtn,Account Number,Transaction Type,Customer Reference Number,Debit Amount,Credit Amount,,Extended Text,Bank Reference Number\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******8932,180,,,SAFEWAY #8867            EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******8932,90,,,TIM HORTONS 1645 QTH     EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******8932,12,,,LUCKY EXPRESS CONVENIE   EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******3735,287.65,,,LONDON DRUG LIMITED 87   CALGARY      AB,\r';
        
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(ERL);
		uploadCSVcontroller ERC= new uploadCSVcontroller(con);
        
        ERC.contentFile=Blob.valueOf(TestCSV);
        ERC.nameFile='6309 MC.csv';
       
        ERC.DateFormat='MDY';
        ERC.CSDate='Transaction Date';
        ERC.CSReference='Customer Reference';
        ERC.CSDebit='Debit';
        ERC.CSCredit ='Credit';   
        ERC.CSDesc='Extended Text';
        ERC.saveSettings(); 
           
        Test.startTest();
        
        ERC.uploadFile();
		
        system.assert(ERC.CDate!=null);
        System.assert(ERC.CReference!=null);
        system.assert(ERC.CDebit!=null);
        system.assert(ERC.CCredit!=null);
        System.assert(ERC.CText!=null);
        System.assert(ERC.DisableReportCreating=true);
       
        Test.stopTest();
        
    }
    
    @isTest static void TestSCVWithWrongHeader() {
        
        List<Expense_Report__c> ERL = new List<Expense_Report__c>();
 		Expense_Report__c ER = new Expense_Report__c();
        
        Department__c dep = new Department__c(Name='TestDep');
        insert dep;
        List<Account> accs= New Account[]{new Account(Name='TestAcc1', Approval_Department__c=dep.id,Email__c='test@email.com',MC__c='8932'),new Account(Name='TestAcc2', Approval_Department__c=dep.id,Email__c='test1@email.com',MC__c='3735')};
        insert accs;    
		
        String TestCSV='Transaction Date,Account Rtn,Account Number,Transaction Type,Customer Reference Number,Debit Amount,Cred+t Amount,,Extended Text,Bank Reference Number\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******8932,180,,,SAFEWAY #8867            EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******8932,90,,,TIM HORTONS 1645 QTH     EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******8932,12,,,LUCKY EXPRESS CONVENIE   EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******3735,287.65,,,LONDON DRUG LIMITED 87   CALGARY      AB,\r';
        
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(ERL);
		uploadCSVcontroller ERC= new uploadCSVcontroller(con);
        
        ERC.contentFile=Blob.valueOf(TestCSV);
        ERC.nameFile='6309 MC.csv';
        
        ERC.DateFormat='MDY';
        ERC.CSDate='Transaction Date';
        ERC.CSReference='Customer Reference';
        ERC.CSDebit='Debit';
        ERC.CSCredit ='Credit';   
        ERC.CSDesc='Extended Text';
        ERC.saveSettings(); 
        
       
        Test.startTest();
        ERC.uploadFile();
        
		system.debug('TestSCVWithWrongHeader - ERC.CCredit: ' + ERC.CCredit);
        system.assert(ERC.CCredit==null);

		system.debug('TestSCVWithWrongHeader - ERC.DisableReportCreating: ' + ERC.DisableReportCreating);
        System.assert(ERC.DisableReportCreating=true);
        Test.stopTest();
        
    }
    
    @isTest static void TestSCVWrongDateFormat() {
        
        List<Expense_Report__c> ERL = new List<Expense_Report__c>();
 		Expense_Report__c ER = new Expense_Report__c();
        
        Department__c dep = new Department__c(Name='TestDep');
        insert dep;
        List<Account> accs= New Account[]{new Account(Name='TestAcc1', Approval_Department__c=dep.id,Email__c='test@email.com',MC__c='8932'),new Account(Name='TestAcc2', Approval_Department__c=dep.id,Email__c='test1@email.com',MC__c='3735')};
        insert accs;    
        
        
        String TestCSV1='Transaction Date,Account Rtn,Account Number,Transaction Type,Customer Reference Number,Debit Amount,Credit Amount,,Extended Text,Bank Reference Number\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******8932,180,,,SAFEWAY #8867            EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******3735,287.65,,,LONDON DRUG LIMITED 87   CALGARY      AB,\r';
        
        String TestCSV2='Transaction Dt,Account Rtn,Account Number,Transaction Type,Customer Reference Number,Debit Amount,Credit Amount,,Extended Text,Bank Reference Number\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******8932,180,,,SAFEWAY #8867            EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******3735,287.65,,,LONDON DRUG LIMITED 87   CALGARY      AB,\r';
        
        String TestCSV3='Transaction Date,Account Rtn,Account Number,Transaction Type,Customer Reference Number,Debit Amount,Credit Amount,,Extended Text,Bank Reference Number\r' +
				'7/18/2017/12,21909119,MasterCard - 547511******6309,Miscellaneous,547511******8932,180,,,SAFEWAY #8867            EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******3735,287.65,,,LONDON DRUG LIMITED 87   CALGARY      AB,\r';

        ApexPages.StandardSetController con = new ApexPages.StandardSetController(ERL);
		uploadCSVcontroller ERC= new uploadCSVcontroller(con);
        
        ERC.nameFile='6309 MC.csv';
        
        Test.startTest();
        ERC.contentFile=Blob.valueOf(TestCSV1);
        
        ERC.DateFormat='YMD';
        ERC.CSDate='Transaction Date';
        ERC.CSReference='Customer Reference';
        ERC.CSDebit='Debit';
        ERC.CSCredit ='Credit';   
        ERC.CSDesc='Extended Text';
        ERC.saveSettings(); 
        
        ERC.uploadFile();
        
        system.assert(ERC.ReportDate==null);
        system.assert(ERC.Twist==false);
        system.assert(ERC.DisableReportCreating==true);
        
        ERC.DateFormat='MDY';
        ERC.contentFile=Blob.valueOf(TestCSV2);
        ERC.uploadFile();

        system.assert(ERC.CDate==null);
        system.assert(ERC.Twist==false);
        system.assert(ERC.DisableReportCreating==true);
        
        ERC.DateFormat='MDY';
        ERC.contentFile=Blob.valueOf(TestCSV3);
        ERC.uploadFile();
        
        system.assert(ERC.ReportDate==null);
        system.assert(ERC.DisableReportCreating==true);
        
        ERC.DateFormat='MDDDY';
        ERC.contentFile=Blob.valueOf(TestCSV1);
        ERC.uploadFile();

        system.assert(ERC.ReportDate==null);
        
        Test.stopTest();
        
    }
    
    @isTest static void TestNoCSV() {
        
        List<Expense_Report__c> ERL = new List<Expense_Report__c>();
 		Expense_Report__c ER = new Expense_Report__c();
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(ERL);
		uploadCSVcontroller ERC= new uploadCSVcontroller(con);
        
        Test.startTest();
        
        ERC.uploadFile();
        ERC.createReports();
        
        system.assert(ERC.contentFile==null);
        system.assert(ERC.DisableReportCreating==true);
        system.assertEquals(ApexPages.getMessages()[0].getSummary().right(30),'No CSV file chosen for upload!');
         Test.stopTest();
        
    }    

    @isTest(SeeAllData=true) static void TestCreatingInvoicesWrongMC() {
        
        List<Expense_Report__c> ERL = new List<Expense_Report__c>();
 		Expense_Report__c ER = new Expense_Report__c();
        
        Department__c dep = new Department__c(Name='TestDep');
        insert dep;
        List<Account> accs= New Account[]{new Account(Name='TestAcc1', Approval_Department__c=dep.id,Email__c='test@email.com',MC__c='8888'),new Account(Name='TestAcc2', Approval_Department__c=dep.id,Email__c='test1@email.com',MC__c='3333')};
        insert accs;    
        
        
        String TestCSV='Transaction Date,Account Rtn,Account Number,Transaction Type,Customer Reference Number,Debit Amount,Credit Amount,,Extended Text,Bank Reference Number\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******8888,180,,,SAFEWAY #8867            EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******0000,90,,,TIM HORTONS 1645 QTH     EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******0001,12,,,LUCKY EXPRESS CONVENIE   EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******3333,287.65,,,LONDON DRUG LIMITED 87   CALGARY      AB,\r';
        
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(ERL);
		uploadCSVcontroller ERC= new uploadCSVcontroller(con);
        
        ERC.contentFile=Blob.valueOf(TestCSV);
        ERC.nameFile='6309 MC.csv';
        
        ERC.DateFormat='MDY';
        ERC.CSDate='Transaction Date';
        ERC.CSReference='Customer Reference';
        ERC.CSDebit='Debit';
        ERC.CSCredit ='Credit';   
        ERC.CSDesc='Extended Text';
        ERC.saveSettings(); 
        
       
        Test.startTest();
        
        ERC.uploadFile();
 
        System.assert(ERC.createReports()==null);

		List<String> messages = new List<String>();
        for (ApexPages.Message Msg: ApexPages.getMessages()) {
			string aMessage = Msg.getSummary().right(10);

			messages.add(aMessage);

			system.debug('Message: ' + aMessage);
        }
        System.assertEquals(messages.get(0), 'not found!');
        System.assertEquals(messages.get(1), 'not found!');
 	       
        Test.stopTest();
        
    }    
 
        @isTest(SeeAllData=true) static void TestCreatingInvoicesNormalMC() {
        
        List<Expense_Report__c> ERL = new List<Expense_Report__c>();
 		Expense_Report__c ER = new Expense_Report__c();
            
        Department__c dep = new Department__c(Name='TestDep');
        insert dep;
        List<Account> accs= New Account[]{new Account(Name='TestAcc0', Approval_Department__c=dep.id,MC__c='0000'),new Account(Name='TestAcc1', Approval_Department__c=dep.id,Email__c='test@email.com',MC__c='1111'),new Account(Name='TestAcc2', Approval_Department__c=dep.id,MC__c='2222')};
        insert accs;    
            
        
        String TestCSV='Transaction Date,Account Rtn,Account Number,Transaction Type,Customer Reference Number,Debit Amount,Credit Amount,,Extended Text,Bank Reference Number\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******0000,180,,,SAFEWAY #8867            EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******1111,90,,,TIM HORTONS 1645 QTH     EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******1111,12,,,LUCKY EXPRESS CONVENIE   EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******2222,287.65,,,LONDON DRUG LIMITED 87   CALGARY      AB,\r';
        
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(ERL);
		uploadCSVcontroller ERC= new uploadCSVcontroller(con);
        
        ERC.contentFile=Blob.valueOf(TestCSV);
        ERC.nameFile='6309 MC.csv';
            
        ERC.DateFormat='MDY';
        ERC.CSDate='Transaction Date';
        ERC.CSReference='Customer Reference';
        ERC.CSDebit='Debit';
        ERC.CSCredit ='Credit';   
        ERC.CSDesc='Extended Text';
        ERC.saveSettings(); 
       
        Test.startTest();
        
        ERC.uploadFile();
        ERC.createReports();

		List<String> messages = new List<String>();
        for (ApexPages.Message Msg: ApexPages.getMessages()) {
            string aMessage = Msg.getSummary().right(34);

			messages.add(aMessage);

			system.debug('Message: ' + aMessage);
        }
        
        system.assertEquals(messages.get(0), 'No email address for this Account!');
        system.assertEquals(messages.get(1), 'No email address for this Account!');

        Test.stopTest();
       
    }

@isTest(SeeAllData=true) static void TestCreatingInvoicesNormalMCEmail() {
        
        List<Expense_Report__c> ERL = new List<Expense_Report__c>();
 		Expense_Report__c ER = new Expense_Report__c();

        Department__c dep = new Department__c(Name='TestDep');
        insert dep;
        List<Account> accs= New Account[]{new Account(Name='TestAcc0', Approval_Department__c=dep.id,Email__c='test_email@email.com',MC__c='2222'),new Account(Name='TestAcc1', Approval_Department__c=dep.id,Email__c='test@email.com',MC__c='8888'),new Account(Name='TestAcc2', Approval_Department__c=dep.id,Email__c='test1@email.com',MC__c='3333')};
        insert accs;    
    
    
        String TestCSV='Transaction Date,Account Rtn,Account Number,Transaction Type,Customer Reference Number,Debit Amount,Credit Amount,,Extended Text,Bank Reference Number\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******2222,180,,,SAFEWAY #8867            EDMONTON     AB,\r' +
				'7/18/2017,21909119,MasterCard - 547511******6309,Miscellaneous,547511******2222,287.65,,,LONDON DRUG LIMITED 87   CALGARY      AB,\r';
        
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(ERL);
		uploadCSVcontroller ERC= new uploadCSVcontroller(con);
        
        ERC.contentFile=Blob.valueOf(TestCSV);
        ERC.nameFile='6309 MC.csv';

        ERC.DateFormat='MDY';
        ERC.CSDate='Transaction Date';
        ERC.CSReference='Customer Reference';
        ERC.CSDebit='Debit';
        ERC.CSCredit ='Credit';   
        ERC.CSDesc='Extended Text';
        ERC.saveSettings(); 
        Test.startTest();
        
        ERC.uploadFile();
        ERC.updateSettingsChanges();
        ERC.createReports();
    
    	Integer invocations = Limits.getEmailInvocations();
            
        Test.stopTest();
		
    	system.assertEquals(1, invocations);
    }    
}