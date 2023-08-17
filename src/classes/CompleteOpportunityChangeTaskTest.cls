@isTest
private class CompleteOpportunityChangeTaskTest {

   @isTest(SeeAllData=true)
 static void OppNo() {
       
        npsp__Batch__c Batch = new npsp__Batch__c();
        Batch.Name='TestBatch';
        Batch.Type__c='Cash';
        Batch.npsp__Batch_Status__c='In Progress';
        Batch.npsp__Object_Name__c='testObject';
        upsert Batch;
       
       c2g__codaJournal__c Jnl = new c2g__codaJournal__c();
       Jnl.c2g__JournalDate__c=system.today();
       insert Jnl;
     
        Opportunity Opw = new Opportunity();
        Opw.Name='GoodTestOpportunityW';
        Opw.Amount=121;
        Opw.CloseDate=system.today();
        Opw.StageName='Received';
        Opw.Type='Cash';
        Opw.Payment_Method__c='Cash';
        Opw.npsp__Batch__c=Batch.Id;
        Opw.Journal_Header__c=Jnl.Id;
        Opw.Journal_Header_Posted_Date__c=Jnl.c2g__JournalDate__c;
        Opw.GL_Post_Status__c='Posted';
       
       
        Opportunity Opp = new Opportunity();
        Opp.Name='GoodTestOpportunity';
        Opp.Amount=121;
        Opp.CloseDate=system.today();
        Opp.StageName='Received';
        Opp.Type='Cash';
        Opp.Payment_Method__c='Cash';
        Opp.npsp__Batch__c=Batch.Id;
       
     system.Test.startTest();
       // create an opportunity for not posted batch
      	insert Opp;
     
       	List<Task> taskRecords = [Select Id, WhatId, Subject from Task where WhatId = :opp.Id];
     	system.assertEquals(0, taskRecords.size());
       
 		// post the batch and update the opportunity       
       Batch.npsp__Batch_Status__c='Posted';
       update Batch;
     
       opp.Journal_Header__c=Jnl.Id;
       Opp.Journal_Header_Posted_Date__c=Jnl.c2g__JournalDate__c;
       Opp.GL_Post_Status__c='Posted';
       update Opp;
     
       taskRecords = [Select Id, WhatId, Subject from Task where WhatId = :opp.Id];
     system.assertEquals(0, taskRecords.size());
       // change the opportunity amount
		Opp.Amount=212;
       	update Opp;
     
    	taskRecords = [Select Id, WhatId, Subject from Task where WhatId = :opp.Id];
     
     system.assertEquals(1, taskRecords.size());
       // add new opportunity to the batch
       insert opw;
    	taskRecords = [Select Id, WhatId, Subject from Task where WhatId = :opw.Id];
        system.assertEquals(1, taskRecords.size());
		// delete the opportunity from the batch
       	delete opw;
    	taskRecords = [Select Id, WhatId, Subject from Task where WhatId = :opw.Id];
        system.assertEquals(0, taskRecords.size());

     system.Test.stopTest();
   }
}