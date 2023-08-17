global class PayableInvoicePendingApprovals implements Schedulable {
     
    global static void schedule(){
        PayableInvoicePendingApprovals m = new PayableInvoicePendingApprovals();
        String sch = '0 0 6 * * ?';
        String jobID = system.schedule('Payable Invoice Pending Approvals', sch, m);
    }
     
    global void execute(SchedulableContext SC) {
        map<Id,list<ProcessInstanceWorkitem>> uIdWithPIW = new map<Id,list<ProcessInstanceWorkitem>>(); 
        
        for(ProcessInstanceWorkitem piw : [Select Id, ActorId, OriginalActorId,OriginalActor.Name, ProcessInstance.TargetObjectId from ProcessInstanceWorkitem where ProcessInstance.Status = 'Pending']){
            if(!uIdWithPIW.containskey(piw.ActorId)){
                uIdWithPIW.put(piw.ActorId, new list<ProcessInstanceWorkitem>());
            }       
            list<ProcessInstanceWorkitem> l = uIdWithPIW.get(piw.ActorId);
            l.add(piw);
        }
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE Name='Pending Payable Invoices Approval Email'];
        list<Messaging.SingleEmailMessage> emailsToSend = new list<Messaging.SingleEmailMessage>();
        list<OrgWideEmailAddress> owe = [Select Id from OrgWideEmailAddress where DisplayName = : system.label.PayableInvoicePendingApprovals_Org_Wide];
        for(Id uId : uIdWithPIW.keyset()){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(uId);
            mail.setTemplateId(et.Id);
            mail.saveAsActivity = false;
            if(owe.size()==1){
                mail.setOrgWideEmailAddressId(owe[0].Id);
            }
            emailsToSend.add(mail);
        }
        if(emailsToSend.size()>0){
            Messaging.sendEmail(emailsToSend);
        }       
   }   
}