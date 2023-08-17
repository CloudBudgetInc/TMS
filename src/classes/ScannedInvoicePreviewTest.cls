@isTest
private class ScannedInvoicePreviewTest {
    
    @isTest static void TestStartPreview() {
        
 		List <Scanned_Payable_Invoice__c> lstSPIN = new List<Scanned_Payable_Invoice__c>();

        Department__c ap = new Department__c (name='New Department');
    	insert ap;
    	c2g__codaGeneralLedgerAccount__c gl1 = new c2g__codaGeneralLedgerAccount__c(c2g__Type__c='Balance Sheet',c2g__ReportingCode__c='1250');
    	insert gl1;
        Account acc = new Account (Name='Test');
        insert acc;
        
      	Scanned_Payable_Invoice__c SPIN0 = new Scanned_Payable_Invoice__c(Invoice_Date__c=system.today(),Account_Name__c=acc.id,Invoice_Number__c='1',Total_Amount__c=100);
      	Scanned_Payable_Invoice__c SPIN1 = new Scanned_Payable_Invoice__c(Invoice_Date__c=system.today(),Account_Name__c=acc.id,Invoice_Number__c='2',Total_Amount__c=100,Department_Name__c=ap.id);
        Scanned_Payable_Invoice__c SPIN2 = new Scanned_Payable_Invoice__c(Invoice_Date__c=system.today(),Account_Name__c=acc.id,Invoice_Number__c='3',Total_Amount__c=100,Department_Name__c=ap.id);
        Scanned_Payable_Invoice__c SPIN3 = new Scanned_Payable_Invoice__c(Invoice_Date__c=system.today(),Account_Name__c=acc.id,Invoice_Number__c='4',Total_Amount__c=100,Department_Name__c=ap.id);
        Scanned_Payable_Invoice__c SPIN4 = new Scanned_Payable_Invoice__c(Invoice_Date__c=system.today(),Account_Name__c=acc.id,Invoice_Number__c='5',Total_Amount__c=100,Department_Name__c=ap.id);
        Scanned_Payable_Invoice__c SPIN5 = new Scanned_Payable_Invoice__c(Invoice_Date__c=system.today(),Account_Name__c=acc.id,Invoice_Number__c='6',Total_Amount__c=100,Department_Name__c=ap.id);
        
        lstSPIN.add(SPIN0);
        lstSPIN.add(SPIN1);
        lstSPIN.add(SPIN2);
        lstSPIN.add(SPIN3);
        lstSPIN.add(SPIN4);
        lstSPIN.add(SPIN5);
        
        insert lstSPIN;
        
        SPIN_Descriptions__c SD = new SPIN_Descriptions__c(SPIN__c=lstSPIN[5].id,Net_Amount__c=100);
        insert SD;
        
		ApexPages.StandardSetController con = new ApexPages.StandardSetController(lstSPIN);
        con.setSelected(lstSPIN);
		ScannedInvoicePreview mycon = new ScannedInvoicePreview(con);
		PageReference pref = Page.ScannedInvoicePreview;       
		Test.setCurrentPage(pref);
        
		Test.startTest();

        mycon.StartPreview();

        mycon.RecordNum	= 1;
        mycon.GoPrevRecord();
        system.assertEquals(mycon.RecordNum,0);

       mycon.GoFirstRecord();
        system.assertEquals(mycon.RecordNum,0);

        mycon.GoLastRecord();
        system.assertEquals(mycon.RecordNum,5);

        mycon.RecordNum	= 1;
        mycon.GoNextRecord();
        system.assertEquals(mycon.RecordNum,2);
        
		mycon.EEmpty();
        
        mycon.RecordNum	= 0;
        mycon.Confirm();
        system.assertNotEquals('Confirmed', mycon.Records[0].Status__c);
        
        mycon.RecordNum	= 1;
        mycon.Confirm();
        system.assertEquals('Scanned', mycon.Records[1].Status__c);
        
        mycon.RecordNum	= 5;
        mycon.StartPreview();
        mycon.Confirm();
        system.assertEquals('Confirmed', mycon.Records[5].Status__c);
        
        mycon.RecordNum=1;
        mycon.Records[1].Invoice_Number__c=null;
        mycon.Confirm();
        system.assertNotEquals('Confirmed', mycon.Records[1].Status__c);

        mycon.RecordNum=1;
        mycon.Records[1].Total_Amount__c=null;
        mycon.Confirm();
        system.assertNotEquals('Confirmed', mycon.Records[1].Status__c);

        mycon.RecordNum=1;
        mycon.Records[1].Invoice_Date__c=null;
        mycon.Confirm();
        system.assertNotEquals('Confirmed', mycon.Records[1].Status__c);
        
        mycon.RecordNum=1;
        mycon.Records[1].Account_Name__c=null;
        mycon.Confirm();
        system.assertNotEquals('Confirmed', mycon.Records[1].Status__c);
        
        mycon.EChangeLinesAmount();
		mycon.EditIt();
        

		Test.stopTest();        

    }
    
     @isTest static void TestEdit() {
         
  		List <Scanned_Payable_Invoice__c> lstSPIN = new List<Scanned_Payable_Invoice__c>();

        Department__c ap = new Department__c (name='New Department');
    	insert ap;
    	c2g__codaGeneralLedgerAccount__c gl1 = new c2g__codaGeneralLedgerAccount__c(c2g__Type__c='Balance Sheet',c2g__ReportingCode__c='1250');
    	insert gl1;
        Account acc = new Account (Name='Test');
        insert acc;
        
         for (Integer i=1;i<6;i++) {
      		Scanned_Payable_Invoice__c SPIN = new Scanned_Payable_Invoice__c(Invoice_Date__c=system.today(),Account_Name__c=acc.id,Invoice_Number__c=String.valueOf(i),Total_Amount__c=100,Department_Name__c=ap.id);
        lstSPIN.add(SPIN);
     
     }
        
        insert lstSPIN;
        
        SPIN_Descriptions__c SD = new SPIN_Descriptions__c(SPIN__c=lstSPIN[0].id,Net_Amount__c=100);
        insert SD;
        SPIN_Descriptions__c SD02 = new SPIN_Descriptions__c(SPIN__c=lstSPIN[3].id,Payable_Control_GL__c=gl1.id, Net_Amount__c=25);
        insert SD02;
        SPIN_Descriptions__c SD00 = new SPIN_Descriptions__c(SPIN__c=lstSPIN[3].id, Net_Amount__c=50);
        insert SD00;
        SPIN_Descriptions__c SD01 = new SPIN_Descriptions__c(SPIN__c=lstSPIN[3].id, Net_Amount__c=25);
        insert SD01;
        SPIN_Descriptions__c SD1 = new SPIN_Descriptions__c(SPIN__c=lstSPIN[2].id,Payable_Control_GL__c=gl1.id, Net_Amount__c=25);
        insert SD1;
        
		ApexPages.StandardSetController con = new ApexPages.StandardSetController(lstSPIN);
        con.setSelected(lstSPIN);
		ScannedInvoicePreview mycon = new ScannedInvoicePreview(con);
		PageReference pref = Page.ScannedInvoiceEdit;       
		Test.setCurrentPage(pref);
        
		Test.startTest();

        mycon.EEmpty();
         
        mycon.RecordNum	= 0;
		mycon.Records[mycon.RecordNum].GST__c=20;
        mycon.StartPreview();
        mycon.EChangeGST(); 

         for (SPIN_Descriptions__c i:mycon.Record_Desc) {
             if (i.Payable_Control_GL__c==gl1.id) {
                 system.assertEquals(10, i.Net_Amount__c);
             } else {
                 system.assertEquals(100, i.Net_Amount__c);
             }
         }
         system.assertEquals(110, mycon.DescTotAmount);
             
         
         mycon.RecordNum	= 3;
		mycon.Records[mycon.RecordNum].GST__c=21;
        mycon.StartPreview();
        mycon.EChangeGST();
         
         system.assertEquals(3, mycon.Record_Desc.size());
         
         for (SPIN_Descriptions__c i:mycon.Record_Desc) {
             if (i.Payable_Control_GL__c==gl1.id) {
                 system.assertEquals(10.50, i.Net_Amount__c);
             }    
         }
        mycon.RecordNum	= 3;
		mycon.Records[mycon.RecordNum].GST__c=0;
        mycon.StartPreview();
        mycon.EChangeGST();
         
		system.assertEquals(2, mycon.Record_Desc.size());         
         
         
        mycon.RecordNum	= 0;
        mycon.StartPreview();
        mycon.EAddDescriptionLine(); 

        system.assertEquals(2, mycon.Record_Desc.size());

         
         mycon.RecordNum	= 1;
        mycon.StartPreview();
        mycon.EAddDescriptionLine(); 
         
         mycon.RecordNum=2;
        mycon.StartPreview();
        mycon.EAddDescriptionLine(); 
         
		
         mycon.RecordNum=3;
        mycon.StartPreview();
         mycon.Edit_Id=1;
         mycon.EDelDescriptionLine();
         
         system.assertEquals(2, mycon.Record_Desc.size());
         
         mycon.ESaveEdit();
         mycon.ECancelEdit();
		
		Test.stopTest();        
        
      }
}