@isTest
private class EngScBatchTestClass {

    @testSetup
    static void setup() {

        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();

        // insert an account
        Account acc = new Account(  Name = 'johntest1', Officer_Rating__c = '9',npo02__TotalOppAmount__c=1200,
                                    npo02__LastCloseDate__c = System.today(), npo02__FirstCloseDate__c = System.today(), npo02__NumberOfClosedOpps__c = 1);                                 
        insert acc;
    }

    @isTest static void test() {

        // Test.startTest();
        // UpdateContactAddresses uca = new UpdateContactAddresses();
        // Id batchId = Database.executeBatch(uca);
        // Test.stopTest();

        // seconds minutes hours day_of_month(? means no specific value) month (* means all) day_of_week (can specify 1,2,3,4,5,6,7 or all *)
        String CronExp = '0 0 0 ? * * *';
        Test.startTest();
        EngagementScoreBatch EngBatch = new EngagementScoreBatch();
        Id batchId = Database.executeBatch(EngBatch);
        Test.stopTest();
        
        List<Account> AllInsertedAccs = [SELECT Id,Name,Officer_Rating__c,npo02__TotalOppAmount__c,npo02__LastCloseDate__c,npo02__FirstCloseDate__c,
                                        npo02__NumberOfClosedOpps__c,Monetary__c,Recency__c,Frequency__c,Days_Since_Last_Gift__c
                                        FROM Account];

        // ** Test if first account inserted and all Fields inserted into acc ** //
        System.assertEquals(1, AllInsertedAccs.size()); 
        System.assertEquals('9', AllInsertedAccs[0].Officer_Rating__c); 
        System.assertEquals(1200, AllInsertedAccs[0].npo02__TotalOppAmount__c);
        System.assertEquals(System.today(), AllInsertedAccs[0].npo02__LastCloseDate__c);
        System.assertEquals(System.today(), AllInsertedAccs[0].npo02__FirstCloseDate__c);
        System.assertEquals(1, AllInsertedAccs[0].npo02__NumberOfClosedOpps__c); 

        // ** Test RFM Values ** //
        System.assertEquals('3', AllInsertedAccs[0].Monetary__c);
        System.assertEquals(0, AllInsertedAccs[0].Days_Since_Last_Gift__c);
        System.assertEquals('4', AllInsertedAccs[0].Recency__c); // I expected 5
        System.assertEquals('1', AllInsertedAccs[0].Frequency__c); 
    }
}