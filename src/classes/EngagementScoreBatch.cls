public class EngagementScoreBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable { //Database.Stateful,

    // instance member to retain states across all transactions on all batch jobs

    public Integer recordsProcessed = 0;
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        // Query the records to be processed
        return Database.getQueryLocator([
            SELECT ID, Officer_Rating__c, Engagement_Score__c, Recency__c, Frequency__c, Monetary__c, npo02__Informal_Greeting__c,
                Largest_Gift_For_Engagement__c, MonetaryAndRecencyForEngagement__c, Largest_Soft_Credit_Score__c, EngagementScore_Updated__c,
                Account_Volunteering_Score__c
            FROM Account 
            // WHERE EngagementScore_Updated__c = false
            // WHERE ID = '0013g00000Aw06xAAB'
            ORDER BY ID
            // LIMIT 50
        ]);
    }

    public void execute(Database.BatchableContext context, List<Account> scope) {
        // Process each record in the batch
        for(Account acc : scope) {

            // how to deal with null values? Use Ternary Operators
            Integer OfficerRating = !String.isBlank(acc.Officer_Rating__c) ? Integer.valueOf(acc.Officer_Rating__c) : null;
            Integer tempEngagementScore = 0;
    
            Integer frequencyNum = Integer.valueOf(acc.Frequency__c);
            Integer MonetaryAndRecency = Integer.valueOf(acc.MonetaryAndRecencyForEngagement__c);
            Integer LargestGiftEngagement = Integer.valueOf(acc.Largest_Gift_For_Engagement__c);  
            Integer LargestSoftCredScore = Integer.valueOf(acc.Largest_Soft_Credit_Score__c);
            Integer VolunteerScore = Integer.valueOf(acc.Account_Volunteering_Score__c);
    
            // Calculate temporary engagement score
            tempEngagementScore = ((MonetaryAndRecency + (frequencyNum * 20) + LargestGiftEngagement) * 4) + LargestSoftCredScore + VolunteerScore;
            
            System.debug('Temp Engagement Score is: ' + tempEngagementScore + ' and Officer Rating is: ' + OfficerRating); 
                    
            if (OfficerRating == null) {
                acc.Engagement_Score__c = tempEngagementScore;
            } else {
                acc.Engagement_Score__c = Math.round((tempEngagementScore * OfficerRating) / 10);
            }

            recordsProcessed +=1;

            // Set the last EngagementScore last updated date field on account to today
            acc.Engagement_Score_Last_Update__c = Date.today();
            
            System.debug('Engagement Score is: ' + acc.Engagement_Score__c); 
        }
        // Update the processed records
        update scope;
    }

    // Sent out an email indicating that the job finished and if there are any errors
    public void finish(Database.BatchableContext context) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
        FROM AsyncApexJob
        WHERE Id = :context.getJobId()];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {job.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Apex Job Status: ' + job.Status);
        mail.setPlainTextBody('The Apex engagementScoreBatch job with ID ' + job.Id + ' has finished with status ' + job.Status + 
                             ' and ' + job.NumberOfErrors + ' errors. \n'+ recordsProcessed + ' records were processed.');
        // mail.setPlainTextBody('The Apex engagementScoreBatch job with ID ' + job.Id + ' has finished with status ' + job.Status + 
        //                      ' and ' + job.NumberOfErrors + ' errors.');       
                                                   
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    // Execute method for schedulable - override
    public void execute(SchedulableContext sc){

        EngagementScoreBatch myBatchObject = new EngagementScoreBatch();
        Database.executeBatch(myBatchObject);
    }

}