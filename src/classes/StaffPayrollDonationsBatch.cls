/* Batching  process for Staff Payroll Donations {Enter Parameter is the list of opportunities to be created}										*/
/* To call this class please use following structure 																								*/
/*			StaffPayrollDonationsBatch batch =  new StaffPayrollDonationsBatch({List of Opportunities},{Batch for 15th}, {Batch for 31st}); 		*/
/*          database.executeBatch(batch); 																											*/

global with sharing class StaffPayrollDonationsBatch implements Database.Batchable<Opportunity>, Database.Stateful {
    
    global final List<Opportunity> OppList;
    global final npsp__Batch__c Batch15;
    global final npsp__Batch__c Batch30;
    
    global StaffPayrollDonationsBatch (List<Opportunity> scope, npsp__Batch__c B15, npsp__Batch__c B30) {
        this.OppList = scope;
        this.Batch15=B15;
        this.Batch30=B30;
    }
    
    global Iterable<Opportunity> start(Database.BatchableContext BC){
        return this.OppList;
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope){
        try {
            insert scope;
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
        // Send an email to the Apex job's submitter notifying of job completion.  
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Name from AsyncApexJob where Id =:BC.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Payroll Donations import ' + a.Status);
        mail.setHTMLBody('Dear '+ a.CreatedBy.Name +',  <br/> <br/> Your Payroll Donations import has finished.<br/> During the porcess there were ' + a.NumberOfErrors + ' errors.<br/><br/> '+'Following batches have been created:<br/><br/>'+
			+ 'Batch for Payroll Donations on 15th: <a href="' + system.URL.getSalesforceBaseUrl().toExternalForm() +'/'+Batch15.Id + '">' + system.URL.getSalesforceBaseUrl().toExternalForm() +'/'+Batch15.Id + '</a><br/>'+
            + 'Batch for Payroll Donations on 30th: <a href="' + system.URL.getSalesforceBaseUrl().toExternalForm() +'/'+Batch30.Id + '">' + system.URL.getSalesforceBaseUrl().toExternalForm() +'/'+Batch30.Id + '</a><br/>'+
            + '<br/><br/>Sincerely,<br/>Salesforce');
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });        
    }
}