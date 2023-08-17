@isTest
private class ScannedPayableInvoiceControllerTest {
    
    @isTest(SeeAllData=true) static void CreatePayableWrongStatus() {
        
        List <Scanned_Payable_Invoice__c> lstSPIN = new List<Scanned_Payable_Invoice__c>();
        List<SPIN_Descriptions__c> lstSD = new List<SPIN_Descriptions__c>();
        
        Department__c ap = (Department__c) TestFactory.createSObject(new Department__c());
        insert ap;
        
        c2g__codaGeneralLedgerAccount__c gl0 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='7000'];
        c2g__codaGeneralLedgerAccount__c gl1 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='1250'];
        
        Account acc = (Account) TestFactory.createSObject(new Account());
        insert acc;
        
        for (Integer i=0; i<5; i++) {
            lstSPIN.add(new Scanned_Payable_Invoice__c(Invoice_Date__c=system.today(), Account_Name__c=acc.id, Invoice_Number__c='00000'+String.valueOf(i), Total_Amount__c=100, Department_Name__c=ap.id));
        }
        insert lstSPIN;

        lstSPIN[0].Status__c='Confirmed';
        update lstSPIN[0];
        
        for (Scanned_Payable_Invoice__c sp: lstSPIN) {
            lstSD.add(new SPIN_Descriptions__c(SPIN__c=sp.id,Payable_Control_GL__c=gl0.id,Net_Amount__c=75));
            lstSD.add(new SPIN_Descriptions__c(SPIN__c=sp.id,Payable_Control_GL__c=gl1.id,Net_Amount__c=25));
        }
        insert lstSD;
        
        Test.startTest();
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(lstSPIN);
        con.setSelected(lstSPIN);
        ScannedPayableInvoiceController mycon = new ScannedPayableInvoiceController(con);
        mycon.CreatePayableInvoices();
        
        Test.stopTest();
        
		List<Scanned_Payable_Invoice__c> spis= [select id, Payable_Invoice__c, Status__c from Scanned_Payable_Invoice__c where id in :lstSPIN]; 
        
        system.assertNotEquals(spis[0].Payable_Invoice__c, null);
        system.assertEquals(spis[0].Status__c, 'FF PIN Generated');

        system.assertEquals(spis[1].Payable_Invoice__c, null);
        system.assertNotEquals(spis[1].Status__c, 'FF PIN Generated');
        system.assertEquals(spis[2].Payable_Invoice__c, null);
        system.assertEquals(spis[3].Payable_Invoice__c, null);
        system.assertEquals(spis[4].Payable_Invoice__c, null);
        
        List<c2g__codaPurchaseInvoiceExpenseLineItem__c> pil = [select id, c2g__NetValue__c from c2g__codaPurchaseInvoiceExpenseLineItem__c where c2g__PurchaseInvoice__c=:spis[0].Payable_Invoice__c];
        system.assertEquals(2, pil.size());
        system.assertEquals(75, pil[1].c2g__NetValue__c);
        system.assertEquals(25, pil[0].c2g__NetValue__c);
        
    }
    
    @isTest(SeeAllData=true) static void CreatePayableConfirmedStatus() {
        
        List <Scanned_Payable_Invoice__c> lstSPIN = new List<Scanned_Payable_Invoice__c>();
        List<SPIN_Descriptions__c> lstSD = new List<SPIN_Descriptions__c>();
        
        Department__c ap = (Department__c) TestFactory.createSObject(new Department__c());
        insert ap;
        
        
        c2g__codaGeneralLedgerAccount__c gl0 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='7000'];
        c2g__codaGeneralLedgerAccount__c gl1 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='1250'];
        
        Account acc = (Account) TestFactory.createSObject(new Account());
        insert acc;
        
        for (Integer i=0; i<5; i++) {
            lstSPIN.add(new Scanned_Payable_Invoice__c(Invoice_Date__c=system.today(), Account_Name__c=acc.id, Invoice_Number__c='00000'+String.valueOf(i), Total_Amount__c=100, Department_Name__c=ap.id));
        }
        insert lstSPIN;
        for (Scanned_Payable_Invoice__c sp: lstSPIN) {
            sp.Status__c='Confirmed';
        }
        update lstSPIN;
        
        for (Scanned_Payable_Invoice__c sp: lstSPIN) {
            lstSD.add(new SPIN_Descriptions__c(SPIN__c=sp.id,Payable_Control_GL__c=gl0.id,Net_Amount__c=75));
            lstSD.add(new SPIN_Descriptions__c(SPIN__c=sp.id,Payable_Control_GL__c=gl1.id,Net_Amount__c=25));
        }
        insert lstSD;
        
        Test.startTest();
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(lstSPIN);
        con.setSelected(lstSPIN);
        ScannedPayableInvoiceController mycon = new ScannedPayableInvoiceController(con);
        
        mycon.CreatePayableInvoices();
        
        Test.stopTest();
        
		List<Scanned_Payable_Invoice__c> spis= [select id, Payable_Invoice__c, Status__c from Scanned_Payable_Invoice__c where id in :lstSPIN]; 
        
       List<Id> pis=new  List<id>();
        for (Scanned_Payable_Invoice__c spi: spis) {
            pis.add(spi.Payable_Invoice__c);
        	system.assertNotEquals(spi.Payable_Invoice__c, null);
            system.assertEquals(spi.Status__c, 'FF PIN Generated');
        }
        
        Integer pil = [select COUNT() from c2g__codaPurchaseInvoiceExpenseLineItem__c where c2g__PurchaseInvoice__c in :pis];
        system.assertEquals(10, pil);
        
    }
    
    @isTest(SeeAllData=true) static void CreatePayableSameInvoiceNumber() {
        
        List <Scanned_Payable_Invoice__c> lstSPIN = new List<Scanned_Payable_Invoice__c>();
        List<SPIN_Descriptions__c> lstSD = new List<SPIN_Descriptions__c>();
        
        Department__c ap = (Department__c) TestFactory.createSObject(new Department__c());
        insert ap;
        
        
        c2g__codaGeneralLedgerAccount__c gl0 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='7000'];
        c2g__codaGeneralLedgerAccount__c gl1 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='1250'];
        
        Account acc = (Account) TestFactory.createSObject(new Account());
        insert acc;
        
        for (Integer i=0; i<2; i++) {
            lstSPIN.add(new Scanned_Payable_Invoice__c(Invoice_Date__c=system.today(), Status__c='Confirmed', Account_Name__c=acc.id, Invoice_Number__c='00000', Total_Amount__c=100, Department_Name__c=ap.id));
        }
        insert lstSPIN;
        for (Scanned_Payable_Invoice__c sp: lstSPIN) {
            sp.Status__c='Confirmed';
        }
        update lstSPIN;
        
        for (Scanned_Payable_Invoice__c sp: lstSPIN) {
            lstSD.add(new SPIN_Descriptions__c(SPIN__c=sp.id,Payable_Control_GL__c=gl0.id,Net_Amount__c=75));
            lstSD.add(new SPIN_Descriptions__c(SPIN__c=sp.id,Payable_Control_GL__c=gl1.id,Net_Amount__c=25));
        }
        insert lstSD;
        
        Test.startTest();
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(lstSPIN);
        con.setSelected(lstSPIN);
        ScannedPayableInvoiceController mycon = new ScannedPayableInvoiceController(con);
        
        mycon.CreatePayableInvoices();
        
        Test.stopTest();
        
		List<Scanned_Payable_Invoice__c> spis= [select id, Payable_Invoice__c, Status__c from Scanned_Payable_Invoice__c where id in :lstSPIN]; 
           	system.assertNotEquals(spis.get(0).Payable_Invoice__c, null);
            system.assertEquals(spis.get(0).Status__c, 'FF PIN Generated');
           	system.assertEquals(spis.get(1).Payable_Invoice__c, null);
            system.assertNotEquals(spis.get(1).Status__c, 'FF PIN Generated');
        
    }
    
    @isTest(SeeAllData=true) static void CreateWithoutLineAmount() {
        
        List<Scanned_Payable_Invoice__c> SPINS = new List<Scanned_Payable_Invoice__c>();
        Scanned_Payable_Invoice__c lstSPIN = new Scanned_Payable_Invoice__c();
        List<SPIN_Descriptions__c> lstSD = new List<SPIN_Descriptions__c>();
        
        Department__c ap = (Department__c) TestFactory.createSObject(new Department__c());
        insert ap;
        
        
        c2g__codaGeneralLedgerAccount__c gl0 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='7000'];
        c2g__codaGeneralLedgerAccount__c gl1 = [select id from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c='1250'];
        
        Account acc = (Account) TestFactory.createSObject(new Account());
        insert acc;
        
        lstSPIN = new Scanned_Payable_Invoice__c(Invoice_Date__c=system.today(), Account_Name__c=acc.id, Invoice_Number__c='00000', Total_Amount__c=100, Department_Name__c=ap.id);
        insert lstSPIN;
       lstSPIN.Status__c='Confirmed';
        update lstSPIN;
        
            lstSD.add(new SPIN_Descriptions__c(SPIN__c=lstSPIN.id,Payable_Control_GL__c=gl0.id,Net_Amount__c=75));
            lstSD.add(new SPIN_Descriptions__c(SPIN__c=lstSPIN.id,Payable_Control_GL__c=gl1.id));
        insert lstSD;
        
        SPINS.add(lstSPIN);
        Test.startTest();
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(SPINS);
        con.setSelected(SPINS);
        ScannedPayableInvoiceController mycon = new ScannedPayableInvoiceController(con);
        
        mycon.CreatePayableInvoices();
        
        Test.stopTest();
        
		Scanned_Payable_Invoice__c spis= [select id, Payable_Invoice__c, Status__c from Scanned_Payable_Invoice__c where id = :lstSPIN.id LIMIT 1]; 
           	system.assertEquals(spis.Payable_Invoice__c, null);
            system.assertNotEquals(spis.Status__c, 'FF PIN Generated');
    }
}