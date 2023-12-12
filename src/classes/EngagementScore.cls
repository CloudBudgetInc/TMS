/**
 * RFM (Engagement) Score Project for TMS Development. Created by John Dagsa August 24, 2023
 * To do: to overcome SOQL DML restriction - done via converting to batch apex
 */

public class EngagementScore Implements Schedulable{
    
    public void execute(SchedulableContext sc){

        System.debug('jamoytest');        
        List<Account> myAccount = new List<Account>();
        // condense this by selecting all fields
        myAccount =[SELECT ID,Officer_Rating__c,Engagement_Score__c,Recency__c,Frequency__c,Monetary__c,npo02__Informal_Greeting__c,
                            Largest_Gift_For_Engagement__c,MonetaryAndRecencyForEngagement__c,Largest_Soft_Credit_Score__c, EngagementScore_Updated__c
                    FROM Account 
                    WHERE EngagementScore_Updated__c=false
                    ORDER BY ID LIMIT 100];
        
        If(myAccount.size() != 0){
            for(Account acc : myAccount){
                
                // how to deal with null values? Use Ternary Operators
                integer OfficerRating = !String.isBlank(acc.Officer_Rating__c) ? integer.valueOf(acc.Officer_Rating__c) : null;
                Integer tempEngagementScore = 0;

                integer frequencyNum = integer.valueOf(acc.Frequency__c);
                //integer recencyNum = integer.valueOf(acc.Recency__c);
                //integer monetaryNum = integer.valueOf(acc.Monetary__c);
                integer MonetaryAndRecency = integer.valueOf(acc.MonetaryAndRecencyForEngagement__c);
                integer LargestGiftEngagement = integer.valueOf(acc.Largest_Gift_For_Engagement__c);  
                integer LargestSoftCredScore = integer.valueOf(acc.Largest_Soft_Credit_Score__c);

                // Calculate temporary engagement score
                tempEngagementScore = ((MonetaryAndRecency + (frequencyNum*20) + LargestGiftEngagement) * 4) + LargestSoftCredScore;
                System.debug('Temp Engagement Score is: ' + tempEngagementScore + ' and Officer Rating is: ' + OfficerRating); 
                
                If(OfficerRating==null){
                    acc.Engagement_Score__c = tempEngagementScore;
                }else{
                    //acc.Engagement_Score__c = Math.round(tempEngagementScore * (OfficerRating / 10));
                    acc.Engagement_Score__c = Math.round((tempEngagementScore * OfficerRating) / 10);
                }

                // set the last EngagementScore last updated date field on account to today
                acc.Engagement_Score_Last_Update__c = system.today();

            System.debug('Engagement Score is: ' + acc.Engagement_Score__c); 
            }
        }    
        If(!myAccount.isEmpty()){
            update myAccount;
        }
    }  
}