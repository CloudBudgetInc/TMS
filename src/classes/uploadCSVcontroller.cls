public class uploadCSVcontroller {
    public Blob contentFile { get; set; }
    public String nameFile { get; set; }
    public List<List<String>> parsedCSVH { get; set; } // CSV with the header
    public List<List<String>> parsedCSV { get; set; } // CSV without the header
    public List<String> parsedH { get; set; } // Header
    
    public Boolean DisableReportCreating { get; set; }
    public Boolean Twist {get; set; }
    
    public String DateFormat { get; set; }
    public String CSDate { get; set; }
    public String CSReference { get; set; }
    public String CSDebit { get; set; }
    public String CSCredit { get; set; }
    public String CSDesc { get; set; }
    
    
    public Integer CDate { get; set; }
    public Integer CReference { get; set; }
    public Integer CDebit { get; set; }
    public Integer CCredit { get; set; }
    public Integer CText { get; set; }
    
    private String MissedData;
    public Date ReportDate { get; set; }
    
    private void SendEmail(Account acc, String ExpRep, Id RepId) {
        
        if (acc.Email__c!=null) {
            Messaging.reserveSingleEmailCapacity(2);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> toAddress = new List<String>();
            toAddress.add(acc.Email__c);
            mail.setToAddresses(toAddress);
            mail.setReplyTo('support@theseed.ca');
            mail.setSenderDisplayName('Salesforce');
            mail.setSubject('Your Expense report has been created!');
            mail.setPlaintextBody('Your Expense report - '+ ExpRep +' has been created! Please ');
            
            mail.setHtmlBody('Hello '+acc.Name+',<br/>Your Expense report:<b> ' + ExpRep +' </b>has been created.<p>'+
                             'To view your report <a href='+URL.getSalesforceBaseUrl().toExternalForm()+'/'+RepId+'>click here.</a> <br/><br/>Thank you');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        } else {
            MissedData='Unable to send email for Expense Report '+ ExpRep +' to '+ acc.Name +'. No email address for this Account!';
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, MissedData);
            ApexPages.addMessage(myMsg);
        }
        
    }
    
    //Get repord date and verify all dates if they are correct...    
    private Date GetReportDate() {
        if (CDate!=null) { 
            Date RD = date.newInstance(2001,1 ,1);
            for (List<String> row : parsedCSV){
                Date cd=ConvertStringToDate(row[CDate], DateFormat);
                If (cd!=null) {
                    If (RD<cd) {RD=cd;}    
                } else {
                    return null;                
                }
            }
            return date.newInstance(RD.year(), RD.month(), date.daysInMonth(RD.year(), RD.month()));
        } else {
            return null;                
        }
    }
    
    // Function converts String to Date - if it is impossible - returns null...
    private Date ConvertStringToDate(String CD, String form) {
        
        form=form.toUpperCase();
        CD=CD.replaceAll('[^0-9^/]', '');
        List<String> el = CD.split('/');
        
        if (el.size()==3) {
            Integer i1=form.indexOf('M');
            Integer i2=form.indexOf('D');
            Integer i3=form.indexOf('Y');
            If ((i1>=0)&&(i1<=2)&&(i2>=0)&&(i2<=2)&&(i3>=0)&&(i3<=2)) {
                Integer m=Integer.valueOf(el[i1]);
                Integer d=Integer.valueOf(el[i2]);
                Integer y=Integer.valueOf(el[i3]);
                if ((m>0)&&(m<13)&&(d>0)&&(d<32)&&(y>2000)&&(y<2020)) {
                    return date.newInstance(y, m, d);
                } else {
                    return null;
                }
            } else {
                return null;
            }
        } else {
            return null;
        }
    }
    
    // Function converts String to Decimal - if it is impossible - returns null...
    private Decimal ConvertStringToDecimal(String CD) {
        Decimal num;
        
        CD=CD.replaceAll('[^0-9^.]', '');
        try {
            num= Decimal.valueOf(CD);
        } catch(Exception e) {
            return 0;
        }
        return num;
    }
    
    
    public uploadCSVcontroller(ApexPages.StandardSetController ctrl) {
        
        // Default values...
        DisableReportCreating= true;
        
        // Read settings for uploading CSV file.
        Expense_Report_CSV_Upload_Settings__c eset = Expense_Report_CSV_Upload_Settings__c.getInstance();
        
        Twist = true;
        DateFormat= eset.Date_Format__c;
        CSDate=eset.Transaction_Date__c;
        CSReference=eset.Customer_Reference_Number__c;
        CSDebit=eset.Debit_Amount__c;
        CSCredit=eset.Credit_Amount__c;
        CSDesc=eset.Description__c;
        
        // Gets Master Record ID
        //        MasterRec=(ID) ApexPages.currentPage().getParameters().get('id');
        
    }
    
    public pageReference saveSettings() {
        
        Expense_Report_CSV_Upload_Settings__c eset = Expense_Report_CSV_Upload_Settings__c.getInstance();
        
        eset.Date_Format__c=DateFormat;
        eset.Transaction_Date__c=CSDate;
        eset.Customer_Reference_Number__c=CSReference;
        eset.Debit_Amount__c=CSDebit;
        eset.Credit_Amount__c=CSCredit;
        eset.Description__c=CSDesc;
        
        try {
            upsert eset;
        } catch (exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in saving Settings!'));
        }
        Twist=false;
        return null;
    }
    
    private void CatchColumnsByKeyWords(List<String> HeaderList) {
        CDate=null; CReference=null; CDebit=null; CCredit=null; CText=null;
        System.debug('HeaderList: ' + HeaderList);
        Integer i=0;
        for (String col: HeaderList) {
           if (col.contains(CSDate)) {  CDate=i;}
            if (col.contains(CSReference)) {CReference=i;}
            if (col.contains(CSDebit)) {CDebit=i;}
            if (col.contains(CSCredit)) {CCredit=i;}
            if (col.contains(CSDesc)) {CText=i;}
            
            i++;
        }
        
        MissedData='';
        
        if (CDate==null) {MissedData+=' Transaction Date: '+ CSDate+';';}
        if (CReference==null) {MissedData+=' Customer Reference Number: '+CSReference+';';}
        if (CDebit==null) {MissedData+=' Debit Amount: '+CSDebit+';';}
        if (CCredit==null) {MissedData+=' Credit Amount: '+CSCredit+';';}
        if (CText==null) {MissedData+=' Description: '+CSDesc+';';}
        if (MissedData!='') {
            MissedData='System is unable to detect following Headers in uploaded file: '+ MissedData + '!';
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, MissedData);
            ApexPages.addMessage(myMsg);
            Twist=false;
            DisableReportCreating= true;
        } else {
            Twist=true;
            DisableReportCreating= false;
        }
        
        ReportDate=GetReportDate();
        If (ReportDate==null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Wrong date format! Please correct the date or enter correct date format in "Upload Settings"!'));
            Twist=false;
            DisableReportCreating= true;
        }
    }
    
    public pageReference updateSettingsChanges() {
        if (contentFile != null){
            CatchColumnsByKeyWords(parsedH);
        } else {
            Twist=false;
        }
        return null;
    }
    
    public pageReference uploadFile() {
        
        if (contentFile != null){
            String fileString = contentFile.toString();
            
            parsedCSVH = parseCSV(fileString); // With header
            parsedCSV =  parsedCSVH.clone(); // Without header
            parsedCSV.remove(0);
            parsedH=parsedCSVH[0]; // The only header
            
            // Catch every column by keyword...
            CatchColumnsByKeyWords(parsedH);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No CSV file chosen for upload!'));
            Twist=true;
            DisableReportCreating= true;
        }
        return null;
    }    
    
    public pageReference createReports() {
        
        if ((contentFile != null) && (MissedData=='')){
            
            // Get the list of MCs we have in CSV...
            Set<String> mc = new Set<String>();
            for (List<String> row : parsedCSV){
                String iStr=row[CReference].right(4);
                if (iStr.isNumeric()) {
                    mc.add(iStr);
                }
            }
            
            // Get from Accounts all the persons with MC codes from CSV
            List<Account> accs=[SELECT Id, Name, Approval_Department__c, Email__c, MC__c FROM account WHERE MC__c IN :mc];
            
            System.debug(accs);
            
            // Something not found...
            if (mc.size()<>accs.size()) {
                for (String m :mc) {
                    Boolean i=false;
                    for(Account acc: accs) {
                        if (m==acc.MC__c) {
                            i=true;
                            break;
                        }
                    }
                    if (i==false) {
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Account related to CSV Customer reference number: ' + m + ' not found!');
                        ApexPages.addMessage(myMsg);
                    }
                }
                // Error need to interrupt execution....
                return null;
            } else {
                
                List<Expense_Report__c> ers = new List<Expense_Report__c>();
                
                for (Account acc: accs) {
                    
                    Expense_Report__c er = new Expense_Report__c();
                    er.Payee__c='Mustard Seed';
                    er.Date__c = ReportDate;
                    er.Status__c='Draft';
                    er.Vendor_Account__c=acc.id;
                    er.Approval_Department__c=acc.Approval_Department__c;
                    er.Description__c=acc.MC__c;
                    
                    ers.add(er);
                }
                
                try {
                    insert ers;
                } catch (exception e) {
                    system.assert(false, 'Error in saving Expense Report files!');
                }
                
                List<Expense_Report_Line_Item__c> erls = new List<Expense_Report_Line_Item__c>();
                
                for (List<String> row : parsedCSV){
                    Expense_Report__c Exr = new Expense_Report__c();
                    
                    for (Expense_Report__c er: ers) {
                        String iStr=row[CReference].right(4);
                        if (iStr.isNumeric()) {
                            if (er.Description__c==iStr) {
                                Exr=er;                        
                                break;    
                            }
                        }
                        
                    }
                    if (Exr!=new Expense_Report__c()) {
                        
                        Expense_Report_Line_Item__c erl = new Expense_Report_Line_Item__c();
                        
                        erl.Expense_Report__c=Exr.id;
                        erl.Description__c=row[CText];
                        Decimal cdp=0; Decimal ccp=0;
                        
                        cdp= ConvertStringToDecimal(row[CDebit]);
                        ccp=-ConvertStringToDecimal(row[CCredit]);
                        
                        erl.Amount__c=cdp+ccp;
                        erl.Date__c=ConvertStringToDate(row[CDate],DateFormat);
                        
                        erls.add(erl);
                        
                    } 
                }
                if (erls!=null) {
                    try {
                        insert erls;
                    } catch (exception e) {
                        system.assert(false,'Error in data saving!');
                    }
                }
                
                List<Expense_Report__c> ers2=[select Id, Name, Vendor_Account__c from Expense_Report__c where id IN :ers];
                String ExpRepNum;
                for (Account acc: accs) {
                    ExpRepNum='';
                    for (Expense_Report__c er: ers2) {
                        if (er.Vendor_Account__c==acc.id) {
                            ExpRepNum = er.Name;
                            SendEmail(acc, ExpRepNum, er.ID);
                            break;
                        }
                    }
                }
            }
            
            if (String.isEmpty(MissedData)) {
                PageReference np = new PageReference('/a0s?fcf=00B36000007cxaO');
                np.setRedirect(false);
                
                return np;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No CSV file uploaded!'));
            Twist=true;
            DisableReportCreating= true;
        }    
        return null;
    }
    
    public static List<List<String>> parseCSV(String contents) {
        List<List<String>> allFields = new List<List<String>>();
        
        contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
        contents = contents.replaceAll('""','DBLQT');
        List<String> lines = new List<String>();
        try {
            lines = contents.split('\r');
        } catch (System.ListException e) {
            System.debug('Limits exceeded?' + e.getMessage());
        }
        Integer num = 0;
        for(String line: lines) {
            // check for blank CSV lines (only commas)
            if (line.replaceAll(',','').trim().length() == 0) break;
            List<String> fields = line.split(',');  
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for(String field: fields) {
                if (field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                } else if (field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field;
                } else if (field.endsWith('"')) {
                    compositeField += ',' + field;
                    cleanFields.add(compositeField.replaceAll('DBLQT','"'));
                    makeCompositeField = false;
                } else if (makeCompositeField) {
                    compositeField +=  ',' + field;
                } else {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                }
            }
            allFields.add(cleanFields);
        }
        return allFields;       
    }
    
}