public class EngagementScore Implements Schedulable{
    
    public void execute(SchedulableContext sc){
	
		System.debug('jamoytest');        
        List<Account> myAccount = new List<Account>();
        myAccount = [SELECT ID,Officer_Rating__c,Engagement_Score__c,Recency__c,Frequency__c,Monetary__c,npo02__Informal_Greeting__c FROM Account WHERE npo02__Informal_Greeting__c='jamoy'];
        
        for(Account acc : myAccount){
            integer frequencyNum = integer.valueOf(acc.Frequency__c);
            integer recencyNum = integer.valueOf(acc.Recency__c);
            integer monetaryNum = integer.valueOf(acc.Monetary__c);
            integer OfficerRating = integer.valueOf(acc.Officer_Rating__c);
            integer tempEngagementScore = ((recencyNum*6)+(frequencyNum*6)+(monetaryNum*8)) * 5;
            // acc.Engagement_Score__c = (frequencyNum + recencyNum + monetaryNum);
            
            IF(OfficerRating==null){
                acc.Engagement_Score__c = tempEngagementScore;
                
            }else{
                acc.Engagement_Score__c = tempEngagementScore * OfficerRating;
            }                                
		System.debug('Engagement Score is: ' + acc.Engagement_Score__c); 
        }
        
        update myAccount;
        
    }
}