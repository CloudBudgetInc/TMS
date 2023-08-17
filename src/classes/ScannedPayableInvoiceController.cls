public class ScannedPayableInvoiceController {
    
    private List<Scanned_Payable_Invoice__c> SelectedSPINs;
    private static c2g__codaPurchaseInvoice__c PayInv;
    private static List<c2g__codaPurchaseInvoiceExpenseLineItem__c> RecS;
    
    private Boolean MissedData;
    
    private static void requestApproval(Id PayId) {
        // Create an approval request
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for review.');
        req1.setObjectId(PayId);
        // Submit the approval request
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    private Boolean createPayable(Scanned_Payable_Invoice__c Rec) {
        
        Savepoint sp = database.setSavepoint(); 
        
        // Creates & populates Payable Invoice
        PayInv = new c2g__codaPurchaseInvoice__c(c2g__Account__c= Rec.Account_Name__c,
                                                 c2g__AccountInvoiceNumber__c=Rec.Invoice_Number__c,
                                                 c2g__InvoiceDate__c = Rec.Invoice_Date__c,
                                                 Department__c= Rec.Department_Name__c);
        try {
            insert PayInv;
            
        } catch(System.DMLException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Rec.Name+ ' ' + e.getMessage()));
            MissedData=true;
            database.rollback(sp);
            return false;
        }
        // Creates & populates Line items
        RecS= new List<c2g__codaPurchaseInvoiceExpenseLineItem__c>();
        
        Integer j=1;
        for(SPIN_Descriptions__c R: Rec.SPIN_Descriptions__r) {
            c2g__codaPurchaseInvoiceExpenseLineItem__c PayInvLines = new c2g__codaPurchaseInvoiceExpenseLineItem__c(c2g__PurchaseInvoice__c=PayInv.id,
                                                                                                                    c2g__LineNumber__c=j,
                                                                                                                    c2g__GeneralLedgerAccount__c= R.Payable_Control_GL__c,
                                                                                                                    c2g__Dimension1__c=R.Dimension_1__c,
                                                                                                                    c2g__Dimension2__c=R.Dimension_2__c,
                                                                                                                    c2g__Dimension3__c=R.Dimension_3__c,
                                                                                                                    c2g__Dimension4__c=R.Dimension_4__c,
                                                                                                                    c2g__LineDescription__c=R.Description__c,
                                                                                                                    c2g__NetValue__c=R.Net_Amount__c);
            RecS.add(PayInvLines);
            j++;
        }   
        try {
            insert RecS;
        } catch(System.DMLException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Rec.Name+ ' ' + e.getMessage()));
            MissedData=true;
            database.rollback(sp);
            return false;
        }
        
        // Sends request for approval of new created Payable Invoice 
        requestApproval(PayInv.Id);
        return true;
    }    
    
    public ScannedPayableInvoiceController(ApexPages.StandardSetController ctrl) {	
        SelectedSPINs = ctrl.getSelected();
    }
    
    public pageReference CreatePayableInvoices() {
        
        // Get selected records with their 'status' and 'payable invoice' fields
        List<Scanned_Payable_Invoice__c> Rec_s = [SELECT Id, Name, Department_Name__c, GST__c, Account_Name__c, Invoice_Date__c, Invoice_Number__c, Total_Amount__c, Status__c, Descriptions_Total_Amount__c,  
                                                  (SELECT Payable_Control_GL__c, Dimension_1__c, Dimension_2__c, Dimension_3__c, Dimension_4__c, Description__c, Net_Amount__c FROM SPIN_Descriptions__r)
                                                  FROM Scanned_Payable_Invoice__c WHERE Id IN :SelectedSPINs];
        
        MissedData=false;
        for (Scanned_Payable_Invoice__c SPIN : Rec_s) {
            if (SPIN.Status__c=='Confirmed') {
                if (createPayable(SPIN)) {
                    SPIN.Status__c='FF PIN Generated';
                    SPIN.Payable_Invoice__c=PayInv.Id;
                    try {
                        update SPIN;
                    } catch(System.DMLException e) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, SPIN.Name + ' ' + e.getMessage()));
                        MissedData=true;
                        return null;
                    }
                }      
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Scanned payable invoice '+SPIN.Name + ' has wrong for creating Payable Invoices status:'+ SPIN.Status__c));
                MissedData=true;
            }
            
        }
        // Load Payable Invoice list View if there were not been the errors.
        if (MissedData) {
            return null;
        } else {
            PageReference np = new PageReference('/a3l/o');
            np.setRedirect(true);
            return np;
        }    
    }
}