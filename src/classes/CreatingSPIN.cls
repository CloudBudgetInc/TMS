// When test this class don't forget to 'Disable' process 'SPIN Account Information' in process builder!!!!!
public class CreatingSPIN {
    public class NException extends Exception {}
    
    @invocableMethod
    public static void AccountReferencesToSPINDescriptions(List<Id> SPINid) {
        Decimal RndGST=0;
        Decimal RndAmt=0;
        
        If(!SPINid.isEmpty()) {
            Id GetId=SPINid.get(0);
            
            Scanned_Payable_Invoice__c record = [Select Id, Name, Invoice_Number__c, Invoice_Date__c, Account_Name__c, Department_Name__c, Total_Amount__c, GST__c From Scanned_Payable_Invoice__c Where Id = :getId];
            
            if(record.Account_Name__c!=null) { 
                Id AccId=record.Account_Name__c;
                
                Account acc = [Select Id, Approval_Department__c, Reference__c From Account Where Id = :AccId];
                
                // Update SPIN with Approval department
                if (acc.Approval_Department__c!=null) {
                    record.Department_Name__c=acc.Approval_Department__c;
                    try {
                        update record;
                    } catch (DmlException e) {
                        throw new NException('Unable to update Approval Department in Scanned Payable Invoice!',e); 
                    }
                }
                
                // If it is not a reference, populate it into SPIN...
                if (!acc.Reference__c) {
                    
                    List<Account_references__c> accrs = [Select Id, Name, Payable_Control_GL__c, Description__c, Dimension_1__c, Dimension_2__c, Dimension_3__c, Dimension_4__c, Percentage_of_Net_Amount__c From Account_references__c Where Account__c = :AccId];
                    List<SPIN_Descriptions__c> SPINs = new List<SPIN_Descriptions__c>();
                    
                    // Calculates recoverable GST...
                    If (record.GST__c!=null) {
                        RndGST=(record.GST__c/2).setScale(2,System.RoundingMode.HALF_UP);
                    }
                    // Calculates amount without GST...
                    RndAmt=record.Total_Amount__c-RndGST;
                    
                    Decimal Tp =0; // Total percent
                    Decimal Ta =0; // Total amount
                    
                    for (Account_references__c accr: accrs) {
                        SPIN_Descriptions__c SPIN = new SPIN_Descriptions__c();
                        
                        SPIN.SPIN__c=record.Id;
                        SPIN.Payable_Control_GL__c=accr.Payable_Control_GL__c;
                        SPIN.Dimension_1__c=accr.Dimension_1__c;
                        SPIN.Dimension_2__c=accr.Dimension_2__c;
                        SPIN.Dimension_3__c=accr.Dimension_3__c;
                        SPIN.Dimension_4__c=accr.Dimension_4__c;
                        SPIN.Description__c=accr.Description__c;
                        if (accr.Percentage_of_Net_Amount__c!=null) {
                            SPIN.Net_Amount__c = (RndAmt/100*accr.Percentage_of_Net_Amount__c).setScale(2);
                            Tp+=accr.Percentage_of_Net_Amount__c;
                            Ta+=SPIN.Net_Amount__c;
                        }
                        SPINs.add(SPIN);
                    }
                    // Verify if we don't have couple extra cents because of roundings.
                    If (Tp>0) {
                        Decimal AmtDiff=(RndAmt/100*Tp).setScale(2);
                        If (AmtDiff!=Ta) {
                            SPINs[0].Net_Amount__c+=AmtDiff-Ta;
                        }
                    }
                    // If we have recoverable GST - add a line.            
                    If (RndGST>0) {
                        SPIN_Descriptions__c SPIN = new SPIN_Descriptions__c();
                        
                        SPIN.SPIN__c=record.Id;
                        SPIN.Payable_Control_GL__c=[SELECT Id, name FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c='1250' LIMIT 1].Id;
                        SPIN.Description__c='Recoverable GST';
                        SPIN.Net_Amount__c = RndGST;
                        SPINs.add(SPIN);
                    }
                    
                    try {
                        insert SPINs;
                    } catch (DmlException e) {
                        throw new NException('Unable to create Description lines for Scanned Payable Invoice!',e); 
                    }
                }
            } else {
                throw new NException('Account field of Scanned Payable Invoice is empty!');
            }
        } else {
                throw new NException('No record on enter!');
        }
    }
}