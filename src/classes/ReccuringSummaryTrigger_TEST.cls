@isTest
private class ReccuringSummaryTrigger_TEST {
    
    private static testMethod void TestSummary() {
        
        Test.startTest();
        
        // To Insert Contact
        
        Contact oneContact = new Contact();
        oneContact.LastName = 'Gautam';
        oneContact.Phone = '101010';
        insert oneContact;
        
        kell6_core__Receipt__c testReceipt = new kell6_core__Receipt__c();
        
        testReceipt.Name = 'Test00001';
        testReceipt.RecordTypeId = '01236000001HqN1';
        testReceipt.kell6_core__Receipted_Year__c='2020';
        testReceipt.kell6_core__Receipt_Contact__c=oneContact.Id;
        
        insert testReceipt;
        
         
        Opportunity Opp = new Opportunity();
        Opp.Name='ww';
        Opp.Amount=5;
        Opp.npsp__Primary_Contact__c=oneContact.Id;
        Opp.Type='Recurring Gift';
        Opp.StageName='Received';
        Opp.Payment_Method__c='Credit Card';
        Opp.Gift_Channel__c='Online';
        Opp.CloseDate=Date.today();
        Opp.AccountId=OneContact.AccountId;
        Opp.Site__c='Calgary';
        Opp.kell6_core__Benefit_Value__c=0;
        Opp.kell6_core__Receipt_Acknowledgement__c=testReceipt.Id;
        
        insert Opp;

        Opportunity Opp1 = new Opportunity();
        Opp1.Name='ww1';
        Opp1.Amount=6;
        Opp1.npsp__Primary_Contact__c=oneContact.Id;
        Opp1.Type='Recurring Gift';
        Opp1.StageName='Received';
        Opp1.Payment_Method__c='Credit Card';
        Opp1.Gift_Channel__c='Online';
        Opp1.CloseDate=Date.today();
        Opp1.AccountId=OneContact.AccountId;
        Opp1.Site__c='Calgary';
        Opp1.kell6_core__Benefit_Value__c=0;
        
        insert Opp1;

        
        testreceipt.kell6_core__Donor_s_Household_Name__c='No donor';
        update testReceipt;

        Test.stopTest();
    }

}