trigger CompleteOpportunityChangeTask on Opportunity (after update, after insert, before delete, after undelete) {
    
    // Users for whom tasks should be assigne have to have field AccountReceivable Checked...
    List<User> UsersID=[select id from user where AccountsReceivable__c=true];
    List<Opportunity> MainStream = new List<Opportunity>();
    List<Opportunity> trNew = new List<Opportunity>();
    List<Opportunity> trOld = new List<Opportunity>();
    list<Task> tskl = new List<Task>();
    String v;
    
    trOld=Trigger.Old;
    trNew=Trigger.New;
    
    if (trOld==null) {
        // for new created opportunity
        v='New';
        MainStream=trNew;
    } else if (trNew==null) {
        // for deleted opportunity
        v='Old';
        MainStream=trOld;
    } else{
        // for changed opportunity
        v='Update';
        MainStream=trNew;
    }
    
    if (MainStream!=null) {
        
        List<Opportunity> Opz=[SELECT id, npsp__Batch__r.npsp__Batch_Status__c, Journal_Header__r.Name FROM Opportunity WHERE id IN :MainStream];
        
        Integer i=0;
        for (Opportunity Opp: MainStream) {
            if (Opp.npsp__Batch__c!=null) {
                String Bs=''; String Jn='';
                for (Opportunity o: Opz) {
                    if (Opp.Id==o.Id) {
                        Bs=o.npsp__Batch__r.npsp__Batch_Status__c;
                        Jn=o.Journal_Header__r.Name;
                        break;
                    }
                }
                if (Bs=='Posted') {
                    String Des='';
                    
                    dateTime dt=opp.Journal_Header_Posted_Date__c;
                    
                    If (v=='New') {
                        Des='Opportunity ' + Opp.Name + ' has been added to Journal ' + Jn + ' ' + dt.format('dd/mm/yyyy') + '!';
                    } else if (v=='Old') {
                        Des='Opportunity ' + Opp.Name + ' has been deleted from Journal ' + Jn + ' ' + dt.format('dd/mm/yyyy') + '!';
                    } else if (trOld[i].Amount!=trNew[i].Amount) {
                        Des='Journal ' + Jn + ' ' + dt.format('dd/mm/yyyy') + '. Opportunity ' + Opp.Name + ' amount been changed from '+trOld[i].Amount+' to '+trNew[i].Amount;
                    }
                    
                    If (Des!='') {
                        for (User UserID: UsersID) {
                            Task tsk = new Task();
                            tsk.OwnerId = UserID.Id;
                            tsk.Status = 'In Progress';
                            tsk.Description = Des;
                            if (v!='Old') {
                                tsk.WhoId = Opp.npsp__Primary_Contact__c;
                                tsk.WhatId = Opp.Id;
                            }
                            tsk.Category__c = 'Finance';
                            tsk.Action__c = 'Review Account/GL Requirements';
                            tsk.Priority = 'Normal';
                            tsk.Contact_Method__c= 'Task/Other';
                            tsk.ActivityDate = system.today();
                            
                            tskl.add(tsk);  
                        }
                    }
                }
            }
            i++;
        }
        if (tskl.size()>0) {
            try {
                insert tskl;
            } catch (Exception e) {
                
            }    
        }
    }
}