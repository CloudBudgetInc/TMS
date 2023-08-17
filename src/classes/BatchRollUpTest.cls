@isTest
private class BatchRollUpTest {

    @isTest static void RollThemUp() {
        
        
        npsp__Batch__c Batch = new npsp__Batch__c();
        Batch.Name='TestBatch';
        Batch.Type__c='Cash';
        Batch.npsp__Batch_Status__c='In Progress';
        Batch.npsp__Object_Name__c='testObject';
        
        upsert Batch;    
            
        Opportunity Opp = new Opportunity();
        Opp.Name='GoodTestOpportunity';
        Opp.Amount=121;
        Opp.CloseDate=system.today();
        Opp.StageName='Received';
        Opp.Type='Cash';
        Opp.Payment_Method__c='Cash';
        Opp.npsp__Batch__c=Batch.Id;
        
        Opportunity Opa = new Opportunity();
        Opa.Name='GoodTestOpportunity';
        Opa.Amount=11.11;
        Opa.CloseDate=system.today();
        Opa.StageName='Received';
        Opa.Type='Cash';
        Opa.Payment_Method__c='Cash';
        Opa.npsp__Batch__c=Batch.Id;


        Opportunity Opz = new Opportunity();
        Opz.Name='NoBatchTestOpportunity';
        Opz.Amount=100.00;
        Opz.CloseDate=system.today();
        Opz.StageName='Received';
        Opz.Type='Cash';
        Opz.Payment_Method__c='Cash';

        Test.startTest();
        // Empty batch
        system.assertEquals(null, Batch.Total_Amount__c);
        system.assertEquals(null, Batch.Total_Number__c);

        // Add first opportunity into the batch
        upsert Opp;
		Batch= [select Id, Total_Number__c, Total_Amount__c from npsp__Batch__c where Id=:Batch.Id]; 
        system.assertEquals(121 ,Batch.Total_Amount__c);
        system.assertEquals(1, Batch.Total_Number__c);
        
		// Add one more opportunity
        upsert Opa;
        Batch= [select Id, Total_Number__c, Total_Amount__c from npsp__Batch__c where Id=:Batch.Id]; 
        system.assertEquals(132.11, Batch.Total_Amount__c);
        system.assertEquals(2, Batch.Total_Number__c);
        
        // Change second opportunity amount
//        Opa.Amount=22.22;
//        update Opa;
//		Batch= [select Id, Total_Number__c, Total_Amount__c from npsp__Batch__c where Id=:Batch.Id]; 
//        system.assertEquals(143.22, Batch.Total_Amount__c);
//        system.assertEquals(2, Batch.Total_Number__c);
        
		// Delete opportunity
//        delete Opa;
//        Batch= [select Id, Total_Number__c, Total_Amount__c from npsp__Batch__c where Id=:Batch.Id]; 
//        system.assertEquals(121, Batch.Total_Amount__c);
//        system.assertEquals(1, Batch.Total_Number__c);
        
		// Upload opportunity without any batch.
//        upsert Opz;
//        Batch= [select Id, Total_Number__c, Total_Amount__c from npsp__Batch__c where Id=:Batch.Id]; 
//        system.assertEquals(121, Batch.Total_Amount__c);
//        system.assertEquals(1, Batch.Total_Number__c);
        
        Test.stopTest();
    }
}