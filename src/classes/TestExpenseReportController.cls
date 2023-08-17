@isTest
public class TestExpenseReportController {
    
    @isTest(SeeAllData=true) static void TestExpenseToPayable() {
        

        Department__c ap = new Department__c (name='Test Department');
    	insert ap;

        c2g__codaGeneralLedgerAccount__c gl0 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='7000'];
        c2g__codaGeneralLedgerAccount__c gl1 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='5000'];
        c2g__codaGeneralLedgerAccount__c gl2 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='2000'];
        c2g__codaGeneralLedgerAccount__c gl3 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='1250'];
        
         Account acc = (Account) TestFactory.createSObject(new Account());
        insert acc;
        
 		Expense_Report__c ER = new Expense_Report__c(Payee__c='Mustard Seed', Date__c=system.today(),Approval_Department__c=ap.id,Vendor_Account__c=acc.id,Status__c='Draft');
        insert ER;

        List<Expense_Report_Line_Item__c> lstERL = new List<Expense_Report_Line_Item__c>();
        for (Integer i=0; i<10; i++) {
            lstERL.add(new Expense_Report_Line_Item__c(Date__c=system.today(), GLA__c=gl0.id, Expense_Report__c=ER.id, Amount__c=10, GST_Amount__c=1));
        }
        insert lstERL;
        Test.startTest();
        
        ApexPages.StandardController con = new ApexPages.StandardController(ER);
        
		ExpenseReportController ERC= new ExpenseReportController(con);
        ERC.CreatePayableInvoices();
        
        Test.stopTest();
        
     }
    @isTest(SeeAllData=true) static void TestExpenseToPayableWrongStatus() {
        

        Department__c ap = new Department__c (name='Test Department');
    	insert ap;

        c2g__codaGeneralLedgerAccount__c gl0 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='7000'];
        c2g__codaGeneralLedgerAccount__c gl1 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='5000'];
        c2g__codaGeneralLedgerAccount__c gl2 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='2000'];
        c2g__codaGeneralLedgerAccount__c gl3 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='1250'];
        
         Account acc = (Account) TestFactory.createSObject(new Account());
        insert acc;
        
 		Expense_Report__c ER = new Expense_Report__c(Payee__c='Mustard Seed', Date__c=system.today(),Approval_Department__c=ap.id,Vendor_Account__c=acc.id,Status__c='Submitted');
        insert ER;

        List<Expense_Report_Line_Item__c> lstERL = new List<Expense_Report_Line_Item__c>();
        for (Integer i=0; i<10; i++) {
            lstERL.add(new Expense_Report_Line_Item__c(Date__c=system.today(), GLA__c=gl0.id, Expense_Report__c=ER.id, Amount__c=10, GST_Amount__c=1));
        }
        insert lstERL;
        Test.startTest();
        
        ApexPages.StandardController con = new ApexPages.StandardController(ER);
        
		ExpenseReportController ERC= new ExpenseReportController(con);
        ERC.CreatePayableInvoices();
        
        Test.stopTest();
        
     }
    
    @isTest(SeeAllData=true) static void TestExpenseErrorCreatingPayable() {
        

        Department__c ap = new Department__c (name='Test Department');
    	insert ap;

        c2g__codaGeneralLedgerAccount__c gl0 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='7000'];
        c2g__codaGeneralLedgerAccount__c gl1 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='5000'];
        c2g__codaGeneralLedgerAccount__c gl2 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='2000'];
        c2g__codaGeneralLedgerAccount__c gl3 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='1250'];
        
         Account acc = (Account) TestFactory.createSObject(new Account());
        insert acc;
        
 		Expense_Report__c ER = new Expense_Report__c(Payee__c='Mustard Seed', Date__c=system.today(),Approval_Department__c=ap.id,Status__c='Draft');
        insert ER;

        List<Expense_Report_Line_Item__c> lstERL = new List<Expense_Report_Line_Item__c>();
        for (Integer i=0; i<10; i++) {
            lstERL.add(new Expense_Report_Line_Item__c(Date__c=system.today(), GLA__c=gl0.id, Expense_Report__c=ER.id, Amount__c=10, GST_Amount__c=1));
        }
        insert lstERL;
        Test.startTest();
        
        ApexPages.StandardController con = new ApexPages.StandardController(ER);
		ExpenseReportController ERC= new ExpenseReportController(con);
        
        ERC.CreatePayableInvoices();
        
        Test.stopTest();
        
     }    
    
}