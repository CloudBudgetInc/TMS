public class StaffPayrollDonations {

    public Blob contentFile { get; set; }
    public String nameFile { get; set; }
    public List<List<String>> parsedCSVH { get; set; } // CSV with the header
    public List<List<String>> parsedCSV { get; set; } // CSV without the header
    public List<String> parsedH { get; set; } // Header
    
    public Boolean DisableReportCreating { get; set; }
    public Boolean Twist {get; set; }
    
    public String  CSAccount { get; set; }
    public String  CSContact { get; set; }
    public String  CSTMSCity { get; set; }
    public Decimal CSRow { get; set; }
    public String  CS15 { get; set; }
    public String  CS31 { get; set; }
 
    public Integer  CAccount { get; set; }
    public Integer  CContact { get; set; }
    public Integer  CTMSCity { get; set; }
    public Integer  C15 { get; set; }
    public Integer  C31 { get; set; }

    public Integer  StartRow { get; set; }
    
    private String MissedData;
    private String retURL;
    public Date ReportDate { get; set; }
    
  
    //Get repord date and verify all dates if they are correct...    
    private Date GetReportDate() {
        Date d=Date.today();
        d = d.addMonths(-1);
        return d;
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
    
    public StaffPayrollDonations(ApexPages.StandardSetController ctrl) {
        
        retURL=System.currentPageReference().getParameters().get('retURL');
        // Default values...
        DisableReportCreating= true;
        Twist = true;
		readSettings('Staff_Payroll_Donations_CSV_Upload');       
        
        ReportDate=GetReportDate();
        
    }
    
    public void readSettings(String InstanceName) {
        // Read custom settings for uploading CSV file.
        Staff_Payroll_Donations_CSV_Upload__c eset = Staff_Payroll_Donations_CSV_Upload__c.getInstance(InstanceName);
        
        try {
            CSAccount= eset.Account_SF_ID__c;
            CSContact=eset.Contact_SF_ID__c;
            CSTMScity=eset.TMS__c;
            CSRow=eset.Data_Header_Row__c;
            StartRow=Integer.valueOf(CSRow);
            CS15=eset.Donation_15th__c;
            CS31=eset.Donation_31st__c;
        } catch (NullPointerException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in reading Payroll CSV Uploading Settings!'));
        }    
    }
    
    public pageReference saveSettings() {
        
        Staff_Payroll_Donations_CSV_Upload__c eset = Staff_Payroll_Donations_CSV_Upload__c.getInstance('Staff_Payroll_Donations_CSV_Upload');
        
        eset.Name='Staff_Payroll_Donations_CSV_Upload';
        eset.Account_SF_ID__c=CSAccount;
        eset.Contact_SF_ID__c=CSContact;
        eset.TMS__c=CSTMSCity;
        CSRow=Decimal.valueof(StartRow);
        eset.Data_Header_Row__c=CSRow;
        eset.Donation_15th__c=CS15;
        eset.Donation_31st__c=CS31;
         
        try {
            upsert eset;
        } catch (exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in saving Payroll CSV Uploading Settings!'));
        }
        Twist=false;
        return null;
    }
    
    private void UpdateHeader(List<List<String>> Src, Integer Strt) {
        If (Strt==Null) {Strt=0;}
        
        if (Src.Size()<Strt||Strt<0) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Wrong data header row ' + String.valueOf(Strt) + '!');
            ApexPages.addMessage(myMsg);
            Twist=false;
            DisableReportCreating= true;
        } else {
            parsedCSV = Src.clone(); // Without header
            For (Integer i=0; i<=Strt; i++) {
            	parsedCSV.remove(0);    
            }
            parsedH=Src[Strt]; // The only header
            Twist=true;
            DisableReportCreating= false;
        }
    }
    
    private void CatchColumnsByKeyWords(List<String> HeaderList) {
        CAccount=-1; CContact=-1; C15=-1; C31=-1; CTMSCity=-1;
        System.debug('HeaderList: ' + HeaderList);
        Integer i=0;
        for (String col: HeaderList) {
           if (col.contains(CSAccount)) {CAccount=i;}
           if (col.contains(CSContact)) {CContact=i;}
           if (col.contains(CSTMSCity)) {CTMSCity=i;}
           if (col.contains(CS15)) {C15=i;}
           if (col.contains(CS31)) {C31=i;}
            
            i++;
        }
        
        MissedData='';
        
        if (CAccount<0) {MissedData+=' Account SF ID: "'+ CSAccount+'";';}
        if (CContact<0) {MissedData+=' Contact SF ID: "'+CSContact+'";';}
        if (CTMSCity<0) {MissedData+=' TMS City: "'+CSTMSCity+'";';}
        if (C15<0) {MissedData+=' Donation 15th: "'+CS15+'";';}
        if (C31<0) {MissedData+=' Donation 31st: "'+CS31+'";';}
        if (MissedData!=''||ReportDate==null) {
            if (MissedData!='') {
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'System is unable to detect following Headers in uploaded file: '+ MissedData + '!'));
            }
            If (ReportDate==null) {
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Wrong report date! Please choose any date of the month report belongs to!'));
            }
            Twist=false;
            DisableReportCreating= true;
        } else {
            Twist=true;
            DisableReportCreating= false;
        }
    }
    
    public pageReference updateSettingsChanges() {
        if (parsedCSVH != null){
            UpdateHeader(parsedCSVH, StartRow);
            CatchColumnsByKeyWords(parsedH);
        } else {
            Twist=false;
        }
        return null;
    }
    
    public pageReference uploadFile() {
        
        Integer StartRow =Integer.ValueOf(CSRow); 
        
        if (contentFile != null){
            
            parsedCSVH = new List<List<String>>();
        	CSVFileIterator x = new CSVFileIterator(contentFile,'\r');
            while(x.hasNext()){
                List<String> PLine = new List<String>();
                CSVParser y= new CSVParser(x.Next());
                while(y.hasNext()){
                    PLine.add(y.Next());
                }    
                parsedCSVH.add(PLine);
   			}
           
            UpdateHeader(parsedCSVH, StartRow);

            // Catch every column by keyword...
            CatchColumnsByKeyWords(parsedH);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No CSV file chosen for upload!'));
            Twist=true;
            DisableReportCreating= true;
        }
        return null;
    }
    
    private String GetBatchName(Date dt) {
        
        String Y = String.ValueOf(dt.year()).Right(2);
        String M = String.ValueOf('00' + String.ValueOf(dt.Month())).Right(2);
        String D = String.ValueOf('00' + String.ValueOf(dt.Day())).Right(2);
        
        Return 'P-'+Y + M +D +'-0001';
    }

    public pageReference createReports() {
        
        Staff_Payroll_Donations_CSV_Upload__c eset = Staff_Payroll_Donations_CSV_Upload__c.getInstance('Staff_Payroll_Donations_CSV_Upload');
        
        
        if ((contentFile != null) && (MissedData=='')){
            
            Savepoint sp = database.setSavepoint();
            
            
            Date FirstDay = ReportDate.toStartOfMonth();
            Date LastDay = FirstDay+Date.daysInMonth(FirstDay.year(),FirstDay.month())-1;
            Date MidDay =FirstDay +14; 
            
            npsp__Batch__c Batch15 = new npsp__Batch__c();
            Batch15.Name=getBatchName(MidDay);
            Batch15.npsp__Object_Name__c='Opportunity';
            Batch15.Date__c=MidDay;
            Batch15.npsp__Batch_Status__c='In Progress';
            Batch15.Type__c='Monthly Donor';
            
            try {
                insert Batch15;
            } catch (exception e) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Error creating Batch file for 15th!');
                ApexPages.addMessage(myMsg);
                database.rollback(sp);
                return null;
            }
            
            npsp__Batch__c Batch31 = new npsp__Batch__c();
            Batch31.Name=getBatchName(LastDay);
            Batch31.npsp__Object_Name__c='Opportunity';
            Batch31.Date__c= LastDay;
            Batch31.npsp__Batch_Status__c='In Progress';
            Batch31.Type__c='Monthly Donor';
            
            try {
                insert Batch31;
            } catch (exception e) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Error creating Batch file for 31st!');
                ApexPages.addMessage(myMsg);
                database.rollback(sp);
                return null;
            }
            
            List<Opportunity> LOp = new List<Opportunity>();
            
            /* get list of all existing in the CSV Contact IDs*/
            Set<String> ContactIDsFromCSV = new Set<String>();
            for (List<String> row : parsedCSV){
                if (row.size()>CContact) {
                    String CsvID=String.valueOf(row[CContact]).trim();
                    if (CSvID.length()>14) {
                        ContactIDsFromCSV.add(CsvID.left(15));
                    }
                }
            }
            
            /* Get from Contacts all the Contacts from the CSV list identified by ID*/
            Map<Id,Contact> CMap = new Map<Id,Contact>([SELECT Id, AccountId, TMS_City__c FROM Contact WHERE Id IN :ContactIDsFromCSV]);
            List<Contact> ContactsFoundById = CMap.values();
            
            List<Id> Ma=new List<Id>();
            for (Contact cs: ContactsFoundById) {
                Ma.Add(cs.AccountID);
            }
            
            Map<Id,Account> AMap = new Map<Id,Account>([SELECT Id FROM Account WHERE Id IN :Ma]);
            Set<id> ContactsId = CMap.keySet();
            
            Integer CMapSize=ContactsFoundById.size();
            
            /* If Something has not been found */
            if (ContactIDsFromCSV.size()<>CMapSize) {
                for (String m :ContactIDsFromCSV) {
                    String CsvID=m.trim();
                    
                    if (!CMap.containsKey(CsvID)) {
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Contact related to CSV Salesforce ID: ' + CsvID + ' not found!');
                        ApexPages.addMessage(myMsg);
                    }
                }
                If(ApexPages.hasMessages()) {
                    database.rollback(sp);
                }
            } else {
                for (List<String> row : parsedCSV){
                    if (row.size()>=Math.Max(Math.Max(CContact,C15),C31)) {
                        if (row[CContact].length()>14) {
                            if(CMap.containsKey(row[CContact])) {
                                Contact ccc=CMap.get(row[CContact]);
                                
                                Decimal C15A = ConvertStringToDecimal(row[C15]);
                                Decimal C31A = ConvertStringToDecimal(row[C31]);
                                
                                
                                if(ccc!=Null && (C15A+C31A)>0) {
                                    
                                    Opportunity Op = new Opportunity();
                                    
                                    Op.Name='Name';
                                    Op.Account=AMap.get(ccc.AccountId);
                                    Op.npsp__Primary_Contact__c=ccc.Id;
                                    Op.TMS_City__c=ccc.TMS_City__c;
                                    Op.StageName=eset.Stage__c;
                                    Op.Type=eset.Type__c;
                                    Op.Gift_Channel__c=eset.Gift_Channel__c;
                                    Op.CampaignId=eset.Campaign_ID__c;
                                    Op.Package__c=eset.Package_ID__c;
                                    Op.Payment_Method__c=eset.Payment_Method__c;
                                    Op.kell6_core__No_Receipt__c=eset.Do_Not_Mail__c;
                                    
                                    
                                    If (C15A>0) {
                                        Op.Amount=C15A;
                                        Op.CloseDate= MidDay;
                                        Op.npsp__Batch__c=batch15.Id;
                                        
                                    } else {
                                        Op.Amount=C31A;
                                        Op.CloseDate= lastDay;
                                        Op.npsp__Batch__c=batch31.Id;
                                    }
                                    
                                    LOp.add(Op);
                                }
                            }
                        }
                    } 
                }
                
                if (LOp!=null) {
                    StaffPayrollDonationsBatch batch =  new StaffPayrollDonationsBatch(LOp, batch15, batch31);
                    database.executeBatch(batch);
                }
            }
        }
        
        if ((!String.isEmpty(retURL))&&(ApexPages.getMessages().size()==0)) {
            PageReference np = new PageReference(retURL);
            np.setRedirect(false);
            
            return np;
        } else {
            return null;
        }
    }
}