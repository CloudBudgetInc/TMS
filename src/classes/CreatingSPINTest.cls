// When do test don't forget to 'Deactivate' process 'SPIN Account Information' in process builder!!!!!
@isTest
private class CreatingSPINTest {
    
    @isTest static void myTest() {
        List<Id> sp0ID= new List<Id>();
        List<Id> sp1ID= new List<Id>();
        List<Id> sp2ID= new List<Id>();
        
        
        Department__c ap = new Department__c(name='testDepartment');
        insert ap;
        
        Account acc = new Account(name='testAccount', Reference__c=false, Approval_Department__c=ap.id);
        insert acc;
        
        c2g__codaGeneralLedgerAccount__c gl0 = new c2g__codaGeneralLedgerAccount__c(c2g__Type__c='Balance Sheet',c2g__ReportingCode__c='1550');
        insert gl0;
        c2g__codaGeneralLedgerAccount__c gl1 = new c2g__codaGeneralLedgerAccount__c(c2g__Type__c='Balance Sheet',c2g__ReportingCode__c='1250');
        insert gl1;
        
        List<Account_References__c> ar = new List<Account_References__c>();
        
        for (Integer i=0;i<10;i++) {
        	Account_References__c ars=new Account_References__c(Account__c=acc.id, Payable_Control_GL__c=gl0.id, Percentage_of_Net_Amount__c=10);
            ar.add(ars);
        }
        insert ar;
        
        Scanned_Payable_Invoice__c sp1 = new Scanned_Payable_Invoice__c(Account_Name__c=acc.id, GST__c=37.33, Invoice_Date__c=System.today(), Invoice_Number__c='Test_Test', Total_Amount__c=1000);
        insert sp1;
        sp1ID.add(sp1.id);
        
       Test.startTest();
      
        try {
            CreatingSPIN.AccountReferencesToSPINDescriptions(sp0ID);
        }catch (Exception e){
             system.assertEquals('No record on enter!',e.getMessage());
        }
        
        try {  
            CreatingSPIN.AccountReferencesToSPINDescriptions(sp1ID);
        } catch (Exception e){
            system.debug('sp1'+ e.getMessage());
        }
        List<SPIN_Descriptions__c> sps=[select SPIN__c, Payable_Control_GL__c, Dimension_1__c, Dimension_2__c, Dimension_3__c, Dimension_4__c, Description__c, Net_Amount__c from SPIN_Descriptions__c where SPIN__c=:sp1.id];
        
        System.assertEquals(sps.size(), 22);
        System.assertEquals(sps[10].Payable_Control_GL__c, gl1.id);
        System.assertEquals(sps[10].Net_Amount__c, 18.67);
        System.assertEquals(sps[9].Net_Amount__c, 98.13);
        
        Test.stopTest();
        
    }
}