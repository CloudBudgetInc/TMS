global with sharing class ForecastUpdateBatch implements Database.Batchable<c2g__codaBudget__c>, Database.Stateful {
    
    
/* Batching  process for Staff Payroll Donations {Enter Parameter is the list of opportunities to be created}		*/
/* To call this class please use following structure 																*/
/*			ForecastUpdateBatch batch =  new ForecastUpdateBatch({List of Budget and Balances}); 					*/
/*          database.executeBatch(batch); 																			*/

    
    global final List<c2g__codaBudget__c> BBList;
    global final Boolean BBLast;
    
    global ForecastUpdateBatch (List<c2g__codaBudget__c> scope, Boolean IsLast) {
        this.BBList = scope;
        this.BBLast = IsLast;
    }
    
    global Iterable<c2g__codaBudget__c> start(Database.BatchableContext BC){
        return this.BBList;
    }
    
    global void execute(Database.BatchableContext BC, List<c2g__codaBudget__c> scope){
        try {
            update scope;
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
        // Send an email to the Apex job's submitter notifying of job completion.  
 //       system.debug(this.BBLast);
 //     if (this.BBLast) {
//        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Name from AsyncApexJob where Id =:BC.getJobId()];
//        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//        String[] toAddresses = new String[] {a.CreatedBy.Email};
//        mail.setToAddresses(toAddresses);
//        mail.setSubject('Payroll Donations import ' + a.Status);
//        mail.setHTMLBody('Dear ');
                         
//                         + a.CreatedBy.Name +',  <br/> <br/> Your Payroll Donations import has finished.<br/> During the porcess there were ' + a.NumberOfErrors + ' errors.<br/><br/> '+'Following batches have been created:<br/><br/>'+
//			+ 'Batch for Payroll Donations on 15th: <a href="' + system.URL.getSalesforceBaseUrl().toExternalForm() +'/'+Batch15.Id + '">' + system.URL.getSalesforceBaseUrl().toExternalForm() +'/'+Batch15.Id + '</a><br/>'+
//            + 'Batch for Payroll Donations on 30th: <a href="' + system.URL.getSalesforceBaseUrl().toExternalForm() +'/'+Batch30.Id + '">' + system.URL.getSalesforceBaseUrl().toExternalForm() +'/'+Batch30.Id + '</a><br/>'+
//            + '<br/><br/>Sincerely,<br/>Salesforce'); 
//                    
//        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });        
 //     }
    }
}