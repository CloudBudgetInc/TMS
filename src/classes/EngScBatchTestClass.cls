@isTest
private class EngScBatchTestClass {

    @testSetup
    static void setup() {

        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        Account acc;

        acc = new Account(  Name = 'nullTest');                                 
        insert acc;

        Integer[] monetaryTest = new Integer[]{25000, 10, 1000, 500, 250, 5000};
        String[] officerRatingTest = new String[]{'10','1','8','7','6','5','4','3','2','9'};
        String[] lGiftScore = new String[]{'100', '90', '80', '70', '60', '50', '40', '30', '20', '10', '0'};
        String[] lSoftCredit = new String[]{'1000', '900', '800', '700', '600', '500', '400', '300', '200', '100', '0'};
        String[] volScore = new String[]{'500', '450', '400', '350', '300', '250', '200', '150', '100', '50', '0'};

        Integer k;
        Integer d;

        for (Integer i = 0; i < 6; i++) {

            // k decides the index of the MonetaryTest array
            k = (i > 5) ? 5 : i;
            // d decides values for the close dates, beyond 3 will always result in 0.
            // Set this way to ensure variability in outputs
            d = (i > 3) ? 0 : i + 1;
                                                     
            acc = new Account(  Name = String.format('{0}{1}{2}{3}',new string[]{String.valueOf(i),String.valueOf(i),String.valueOf(i), '1'}), Officer_Rating__c = officerRatingTest[i],npo02__TotalOppAmount__c=monetaryTest[k],
                                    npo02__FirstCloseDate__c = System.today().addDays(-1*(365 * (d + 1)) - 1), npo02__LastCloseDate__c = System.today().addDays(-1*(365 * d) - 1), npo02__NumberOfClosedOpps__c = (6 - i) * 2);
            insert acc;

        }
    }

    // Joanne Was Here
    // Variables I can't change without stub
    // LargestGiftEngagement, LargestSoftCredScore, VolunteerScore
    @isTest static void nullAccountTest() { // Test on account with only name assigned

        // seconds minutes hours day_of_month(? means no specific value) month (* means all) day_of_week (can specify 1,2,3,4,5,6,7 or all *)
        String CronExp = '0 0 0 ? * * *';

        Test.startTest();
        EngagementScoreBatch EngBatch = new EngagementScoreBatch();
        Id batchId = Database.executeBatch(EngBatch);
        Test.stopTest();
        
        Account emptyAccount = [SELECT Id,Name,Officer_Rating__c,npo02__TotalOppAmount__c,npo02__LastCloseDate__c,npo02__FirstCloseDate__c,
                                        npo02__NumberOfClosedOpps__c,Monetary__c,Recency__c,Frequency__c,Days_Since_Last_Gift__c,Largest_Gift_For_Engagement__c,MonetaryAndRecencyForEngagement__c,Engagement_Score__c,
                                        EngagementScore_Updated__c
                                        FROM Account
                                        LIMIT 1 OFFSET 0];

        System.debug('Hello');

        System.assertEquals('0', emptyAccount.MonetaryAndRecencyForEngagement__c);
        System.assertEquals(10, emptyAccount.Largest_Gift_For_Engagement__c);
        System.assertEquals('0', emptyAccount.Monetary__c);
        System.assertEquals('4', emptyAccount.Recency__c);
        System.assertEquals('1', emptyAccount.Frequency__c);
        //System.assert(String.isBlank(emptyAccount.Officer_Rating__c));

        // Engagement score is 120
        System.assertEquals((((0 + (Integer.valueOf(emptyAccount.Frequency__c) * 20) + 10) * 4) + 0 + 0), emptyAccount.Engagement_Score__c);
        System.assertEquals(120, emptyAccount.Engagement_Score__c);
    }

    // Test max monetary frequency this year
    @isTest static void testTheoreticalMax() {
        // seconds minutes hours day_of_month(? means no specific value) month (* means all) day_of_week (can specify 1,2,3,4,5,6,7 or all *)
        String CronExp = '0 0 0 ? * * *';

        Test.startTest();
        EngagementScoreBatch EngBatch = new EngagementScoreBatch();
        Id batchId = Database.executeBatch(EngBatch);
        Test.stopTest();
        
        Account maxAccount = [SELECT Id,Name,Officer_Rating__c,npo02__TotalOppAmount__c,npo02__LastCloseDate__c,npo02__FirstCloseDate__c,
                                        npo02__NumberOfClosedOpps__c,Monetary__c,Recency__c,Frequency__c,Days_Since_Last_Gift__c,Largest_Gift_For_Engagement__c,MonetaryAndRecencyForEngagement__c,Engagement_Score__c,
                                        EngagementScore_Updated__c, Average_Number_of_Gifts_Per_Year__c, Number_of_Giving_Years__c
                                        FROM Account
                                        LIMIT 1 OFFSET 1];

        System.assertEquals('800', maxAccount.MonetaryAndRecencyForEngagement__c);
        System.assertEquals(10, maxAccount.Largest_Gift_For_Engagement__c);
        System.assertEquals('4', maxAccount.Recency__c);
        System.assertEquals('10', maxAccount.Officer_Rating__c);
        System.assertEquals('5', maxAccount.Frequency__c);

        System.assertEquals(3640, maxAccount.Engagement_Score__c);
        System.assertEquals(5500, (Math.round(maxAccount.Engagement_Score__c / 4) - 10 + 100) * 4 + 1000 + 500);
        System.assertEquals(true, maxAccount.EngagementScore_Updated__c);
    }

    // Minimum monetary, frequency 2 years ago
    @isTest static void testNormalInputTwiceUpdate() {
        // seconds minutes hours day_of_month(? means no specific value) month (* means all) day_of_week (can specify 1,2,3,4,5,6,7 or all *)
        String CronExp = '0 0 0 ? * * *';

        Account accountWillUpdate = [SELECT Id,Name,Officer_Rating__c,npo02__TotalOppAmount__c,npo02__LastCloseDate__c,npo02__FirstCloseDate__c,
                                        npo02__NumberOfClosedOpps__c,Monetary__c,Recency__c,Frequency__c,Days_Since_Last_Gift__c,Largest_Gift_For_Engagement__c,MonetaryAndRecencyForEngagement__c,Engagement_Score__c,
                                        EngagementScore_Updated__c
                                        FROM Account
                                        LIMIT 1 OFFSET 2];

        Id testedAccountId = accountWillUpdate.Id;
        Integer processedRecords;

        Test.startTest();
        EngagementScoreBatch EngBatch = new EngagementScoreBatch();
        Id batchId = Database.executeBatch(EngBatch);

        accountWillUpdate.npo02__TotalOppAmount__c = 25000;
        update accountWillUpdate;

        batchId = Database.executeBatch(EngBatch);
        processedRecords = EngBatch.recordsProcessed;

        Test.stopTest();

        // Discovery, when searching by id in where clause use =:
        accountWillUpdate = [SELECT Id, MonetaryAndRecencyForEngagement__c, Largest_Gift_For_Engagement__c, Engagement_Score__c
                                FROM Account
                                WHERE Id =: testedAccountId
                                LIMIT 1];

        System.assertEquals('600', accountWillUpdate.MonetaryAndRecencyForEngagement__c);
        System.assertEquals(10, accountWillUpdate.Largest_Gift_For_Engagement__c);
        System.assertEquals(284, accountWillUpdate.Engagement_Score__c);    
        
    }


    @isTest static void shouldNotUpdateTestNoChange() {
        // seconds minutes hours day_of_month(? means no specific value) month (* means all) day_of_week (can specify 1,2,3,4,5,6,7 or all *)
        String CronExp = '0 0 0 ? * * *';
        Id testedAccountId;

        Account noUpdate = [SELECT Id, Engagement_Score__c
                    FROM Account
                    LIMIT 1 OFFSET 3];

        testedAccountId = noUpdate.Id;

        Test.startTest();
        EngagementScoreBatch EngBatch = new EngagementScoreBatch();
        Id batchId = Database.executeBatch(EngBatch);

        Test.stopTest();

        noUpdate = [SELECT Id,Name,Officer_Rating__c,npo02__TotalOppAmount__c,npo02__LastCloseDate__c,npo02__FirstCloseDate__c,
                                        npo02__NumberOfClosedOpps__c,Monetary__c,Recency__c,Frequency__c,Days_Since_Last_Gift__c,Largest_Gift_For_Engagement__c,MonetaryAndRecencyForEngagement__c,Engagement_Score__c,
                                        EngagementScore_Updated__c
                                        FROM Account
                                        WHERE Id =: testedAccountId
                                        LIMIT 1];
        // M3, OR:8, R5, MR -> 100
        System.assertEquals('0', noUpdate.MonetaryAndRecencyForEngagement__c);
        System.assertEquals(10, noUpdate.Largest_Gift_For_Engagement__c);

        System.assertEquals(288, noUpdate.Engagement_Score__c); 

        System.assertEquals(0, EngBatch.recordsProcessed);
        // System.assertEquals(false, noUpdate.EngagementScore_Updated__c);
    }
    @isTest static void shouldNotUpdateTestUnrelatedChange() {
        // seconds minutes hours day_of_month(? means no specific value) month (* means all) day_of_week (can specify 1,2,3,4,5,6,7 or all *)
        String CronExp = '0 0 0 ? * * *';

        Account noUpdateAccount = [SELECT Id,Name,Officer_Rating__c,npo02__TotalOppAmount__c,npo02__LastCloseDate__c,npo02__FirstCloseDate__c,
                                        npo02__NumberOfClosedOpps__c,Monetary__c,Recency__c,Frequency__c,Days_Since_Last_Gift__c,Largest_Gift_For_Engagement__c,MonetaryAndRecencyForEngagement__c,Engagement_Score__c,
                                        EngagementScore_Updated__c, Engagement_Score_Last_Update__c
                                        FROM Account
                                        LIMIT 1 OFFSET 4];

        Id testId = noUpdateAccount.Id;

        Test.startTest();
        EngagementScoreBatch EngBatch = new EngagementScoreBatch();
        Id batchId = Database.executeBatch(EngBatch);

        noUpdateAccount.Name = 'Do not Process';

        update noUpdateAccount;

        batchId = Database.executeBatch(EngBatch);
        Test.stopTest();

        noUpdateAccount = [SELECT Id,Name,Officer_Rating__c,npo02__TotalOppAmount__c,npo02__LastCloseDate__c,npo02__FirstCloseDate__c,
                                        npo02__NumberOfClosedOpps__c,Monetary__c,Recency__c,Frequency__c,Days_Since_Last_Gift__c,Largest_Gift_For_Engagement__c,MonetaryAndRecencyForEngagement__c,Engagement_Score__c,
                                        EngagementScore_Updated__c, Engagement_Score_Last_Update__c
                                        FROM Account
                                        WHERE Id =: testId
                                        LIMIT 1];

        // Monetery 2, recency 2
        System.assertEquals(0, EngBatch.recordsProcessed);
        System.assertEquals('0', noUpdateAccount.MonetaryAndRecencyForEngagement__c);
        System.assertEquals(10, noUpdateAccount.Largest_Gift_For_Engagement__c);
        System.assertEquals(196, noUpdateAccount.Engagement_Score__c);
        // System.assertEquals(Math.round((((Integer.valueOf(AllInsertedAccs[0].MonetaryAndRecencyForEngagement__c) + (Integer.valueOf(AllInsertedAccs[0].Frequency__c) * 20) + 10) * 4) + 0 + 0) * Integer.valueOf(AllInsertedAccs[0].Officer_Rating__c) / 10), AllInsertedAccs[0].Engagement_Score__c);
    }

    @isTest static void testTechnicalMin() {
        // seconds minutes hours day_of_month(? means no specific value) month (* means all) day_of_week (can specify 1,2,3,4,5,6,7 or all *)
        String CronExp = '0 0 0 ? * * *';

        Test.startTest();
        EngagementScoreBatch EngBatch = new EngagementScoreBatch();
        Id batchId = Database.executeBatch(EngBatch);
        Test.stopTest();
        
        Account notEmptyMin = [SELECT Id,Name,Officer_Rating__c,npo02__TotalOppAmount__c,npo02__LastCloseDate__c,npo02__FirstCloseDate__c,
                                        npo02__NumberOfClosedOpps__c,Monetary__c,Recency__c,Frequency__c,Days_Since_Last_Gift__c,Largest_Gift_For_Engagement__c,MonetaryAndRecencyForEngagement__c,Engagement_Score__c,
                                        EngagementScore_Updated__c
                                        FROM Account
                                        LIMIT 1 OFFSET 5];

        System.assertEquals('0', notEmptyMin.MonetaryAndRecencyForEngagement__c);
        System.assertEquals(10, notEmptyMin.Largest_Gift_For_Engagement__c);

        System.assertEquals(120, notEmptyMin.Engagement_Score__c);
        // System.assert(true, notEmptyMin.EngagementScore_Updated__c);
    }

    @isTest static void testNormal() {
        // seconds minutes hours day_of_month(? means no specific value) month (* means all) day_of_week (can specify 1,2,3,4,5,6,7 or all *)
        String CronExp = '0 0 0 ? * * *';

        Test.startTest();
        EngagementScoreBatch EngBatch = new EngagementScoreBatch();
        Id batchId = Database.executeBatch(EngBatch);
        Test.stopTest();
        
        Account regularAccountTwo = [SELECT Id,Name,Officer_Rating__c,npo02__TotalOppAmount__c,npo02__LastCloseDate__c,npo02__FirstCloseDate__c,
                                        npo02__NumberOfClosedOpps__c,Monetary__c,Recency__c,Frequency__c,Days_Since_Last_Gift__c,Largest_Gift_For_Engagement__c,MonetaryAndRecencyForEngagement__c,Engagement_Score__c,
                                        EngagementScore_Updated__c
                                        FROM Account
                                        LIMIT 1 OFFSET 6];

        System.assertEquals('4', regularAccountTwo.Monetary__c);
        System.assertEquals('400', regularAccountTwo.MonetaryAndRecencyForEngagement__c);
        System.assertEquals(10, regularAccountTwo.Largest_Gift_For_Engagement__c);
        System.assertEquals(860, regularAccountTwo.Engagement_Score__c);
    }

}