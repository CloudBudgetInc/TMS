public class ExpenseReportController {
    
    private List<c2g__codaPurchaseInvoiceExpenseLineItem__c> RecS;
    private static c2g__codaPurchaseInvoice__c PayInv;
    private static Expense_Report__c Record;
    
    private static void requestApproval(Id PayId) {
        // Create an approval request
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(PayId);
        // Submit the approval request
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    private Boolean createPayable(Id MyId) {
        
        Savepoint sp = database.setSavepoint(); 
        
        // Creates & populates Payable Invoice
        PayInv = new c2g__codaPurchaseInvoice__c(c2g__Account__c= Record.Vendor_Account__c,
                                                 c2g__AccountInvoiceNumber__c = Record.Name,
                                                 c2g__InvoiceDate__c = Record.Date__c,
                                                 Department__c= Record.Approval_Department__c);
        try {
            insert PayInv;
            
        } catch(System.DMLException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Record.Name+ ' ' + e.getMessage()));
            database.rollback(sp);
            return false;
        }
        
        
        // Creates & populates Line items
        RecS= new List<c2g__codaPurchaseInvoiceExpenseLineItem__c>();
        
        Integer j=1;
        Decimal rec_GST = 0;
        for(Expense_Report_Line_Item__c R: Record.Expense_Report_Line_Items__r) {
            c2g__codaPurchaseInvoiceExpenseLineItem__c PayInvLines = new c2g__codaPurchaseInvoiceExpenseLineItem__c(c2g__PurchaseInvoice__c=PayInv.id,
                                                                                                                    c2g__LineNumber__c=j,
                                                                                                                    c2g__GeneralLedgerAccount__c= R.GLA__c,
                                                                                                                    c2g__Dimension1__c=R.Dimension_1__c,
                                                                                                                    c2g__Dimension2__c=R.Dimension_2__c,
                                                                                                                    c2g__Dimension3__c=R.Dimension_3__c,
                                                                                                                    c2g__Dimension4__c=R.Dimension_4__c,
                                                                                                                    c2g__LineDescription__c=R.Description__c,
                                                                                                                    c2g__NetValue__c=R.Expense_Amount__c);
            rec_GST+=R.Recoverable_GST__c;
            RecS.add(PayInvLines);
            j++;
        }
        // if we have recoverable GST - write it's sum in the last line...
        if (rec_GST>0) {
            c2g__codaGeneralLedgerAccount__c g=[SELECT Id, name FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c='1250' LIMIT 1];
            
            c2g__codaPurchaseInvoiceExpenseLineItem__c PayInvLines = new c2g__codaPurchaseInvoiceExpenseLineItem__c(c2g__PurchaseInvoice__c=PayInv.id,
                                                                                                                    c2g__LineNumber__c=j,
                                                                                                                    c2g__GeneralLedgerAccount__c= g.Id,
                                                                                                                    c2g__LineDescription__c='Recoverable GST',
                                                                                                                    c2g__NetValue__c=rec_GST);
            RecS.add(PayInvLines);
        }
        
        try {
            insert RecS;
        } catch(System.DMLException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Record.Name+ ' ' + e.getMessage()));
            database.rollback(sp);
            return false;
        }
        
        // Sends request for approval of new created Payable Invoice 
        requestApproval(PayInv.Id);
        return true;
    }
    
    public ExpenseReportController(ApexPages.StandardController ctrl) {
        sObject CurrentRec= ctrl.getRecord();
        // Gets data from Expense report & Lines
        Record=[SELECT Id, Name, Vendor_Account__c, Date__c, Status__c, Approval_Department__c, Payable_Invoice__c,
                (SELECT GLA__c, Dimension_1__c, Dimension_2__c, Dimension_3__c, Dimension_4__c, Description__c, Recoverable_GST__c, Expense_Amount__c FROM Expense_Report_Line_Items__r) FROM Expense_Report__c WHERE Id=:CurrentRec.Id];
    }
    
    public pageReference CreatePayableInvoices() {
        
        // Get selected records with their 'status' and 'payable invoice' fields
        if (Record.Status__c=='Draft') {
            if (Record.Payable_Invoice__c==null) {
                if (createPayable(Record.id)) {
                    Record.Payable_Invoice__c=PayInv.Id;
                    Record.Status__c='Submitted';
                    try {
                        update Record;
                    } catch(System.DMLException e) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Record.Name+ ' ' + e.getMessage()));
                        return null;
                    }
                    Approval.Lock(Record);
                } else {
                    return null;    
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Payable Invoice already was created using current Expence Report!' ));
                return null;
            }    
        } else {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Expense Report '+Record.Name + ' has wrong status for creating Payable Invoices:'+ Record.Status__c);
            ApexPages.addMessage(myMsg);
            return null;
        }
        PageReference np = new PageReference('/a3l/o');
        np.setRedirect(true);
        return np;
    }
}