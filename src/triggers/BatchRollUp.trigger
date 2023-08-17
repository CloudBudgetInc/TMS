// Trigger Rolls-Up 'Total Amount' and 'Number of Items' fields in parent batch if it exists.

trigger BatchRollUp on Opportunity (after update, after insert, after delete, after undelete) {
    List<Opportunity> tr = new List<Opportunity>();

    Decimal OA;
    Decimal FA;
    Decimal PA;
    Decimal NR;
    
    Set<Id> BatchSet = new Set<Id>();
    
    if (Trigger.isDelete) {
        tr = Trigger.old;
    } else {
        tr = Trigger.new;
    }
    for (Opportunity Opp : tr) {
        if (Opp.npsp__Batch__c!=null) {
            BatchSet.add(Opp.npsp__Batch__c);
        }    
    }
    if (!BatchSet.IsEmpty()) {
        List<npsp__Batch__c> Batches= [SELECT Id, Total_Number__c, Total_Amount__c, Fees_Amount__c, Payroll_Amount__c FROM npsp__Batch__c WHERE Id IN :BatchSet];
        List<AggregateResult> Qcount=[SELECT npsp__Batch__c, StageName, COUNT(Id) OppNumber, SUM(Amount) OppAmount, SUM(Processing_Fees__c) FeeAmount, SUM(Amount_Payroll__c) PayrollAmount FROM Opportunity WHERE npsp__Batch__c IN : BatchSet GROUP BY npsp__Batch__c, StageName];
        
        for (npsp__Batch__c Batch: Batches) {
            Batch.Total_Amount__c=0; // Total Amount
            Batch.Total_Number__c=0; // Number of Approved Gifts
            Batch.Declined_Items__c=0; // Number of Declined Gifts
            Batch.Approved_Amount__c=0; // Approved Amount
            Batch.Declined_Amount__c=0; // Declined Amount
            Batch.Fees_Amount__c=0; // Fees Amount
            Batch.Payroll_Amount__c=0; // Payroll Amount
            
            for(AggregateResult aggResult : Qcount) {
                
                OA = aggResult.get('OppAmount')==null?0:(Decimal)aggResult.get('OppAmount');
                FA = aggResult.get('FeeAmount')==null?0:(Decimal)aggResult.get('FeeAmount');
                NR = aggResult.get('OppNumber')==null?0:(Decimal)aggResult.get('OppNumber');
                PA = aggResult.get('PayrollAmount')==null?0:(Decimal)aggResult.get('PayrollAmount'); 
                
                
                if ((Id)aggResult.get('npsp__Batch__c')==Batch.Id) {
                    Batch.Total_Amount__c+=OA;
                    Batch.Fees_Amount__c+=FA;
                    if ((String)aggResult.get('StageName')=='Received') {
                       Batch.Approved_Amount__c+=OA;
                       Batch.Payroll_Amount__c+=PA;
                       Batch.Total_Number__c+=NR;
                    } else {    
                        Batch.Declined_Amount__c+=OA;
                        Batch.Declined_Items__c+=NR;
                    }
                }
            }
        }
        try {
            update Batches;
        } catch (Exception e) {
            ApexPages.AddMessage(new ApexPages.message(ApexPages.severity.WARNING,'Error occurs during batch updating!'));
        }
    }
}