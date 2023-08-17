public with sharing class ScannedInvoicePreview {
    
    public List<Scanned_Payable_Invoice__c> Records {get; set;} // All selected records...
    public List<SPIN_Descriptions__c> Records_Desc {get; set;} // All selected record's descriptions...
    
    public Scanned_Payable_Invoice__c Record {get; set;} // Current record...
    public List<SPIN_Descriptions__c> Record_Desc {get; set;} // Descriptions of the current record...
    public Id GST_GL {get; set;} // General Ledger Account for GST
    
    public Integer RecordNum {get; set;}
    public Decimal DescTotAmount {get; set;}
    
    public Integer Edit_Id {get; set;}
    public String retURL {get; set;}
    
    public Metadata.Layout ILayoutI {get; set;}
    
    // Returns true if all fields are populated. If something is wrong returns false & additional information in MissedData
    private String verifyForMissedData(Scanned_Payable_Invoice__c Rec) {

        String MissedData='';
        if (Rec.Department_Name__c==null) {
            MissedData='Approval Department is missed!';
        } else if  (Rec.Account_Name__c==null) {
            MissedData='Account is missed!';
        } else if (Rec.Invoice_Date__c==null) {
            MissedData='Invoice Date is missed!';
        } else if (Rec.Total_Amount__c==null) {
            MissedData='Total Amount is missed!';
        } else if (Rec.Invoice_Number__c==null) {
            MissedData='Invoice Number is missed!';
        } else if (DescTotAmount!=Rec.Total_Amount__c) {
             DescTotAmount=LinesTotal(Record_Desc);
            MissedData='"Total Amount" and "Total Lines Net Amount" are different!';
        }
        return MissedData;
    }
    
    // Move GST to the bottom of the List...
    private List<SPIN_descriptions__c> SortDescriptionLines(List<SPIN_descriptions__c> RDs, ID GST) {
        
        // If Descriptions have only line it doesn't make sense to sort it...
        if (RDs.size()>1) {
            Integer i=RDs.Size()-2;
            While(i>-1) {
                SPIN_descriptions__c sp=RDs.get(i);
                if(sp.Payable_Control_GL__c==GST) {
                    RDs.remove(i);
                    RDs.add(sp);
                }
                i--;
            }
        }
        return RDs;
    }
    
    // returns Total Line's Amount
    private Decimal LinesTotal(List<SPIN_descriptions__c> RDesc) {
        Decimal DTA=0;
        // Count Total lines amount & check position of GST line...
        if (RDesc!=null) {
            for (SPIN_descriptions__c sp: RDesc) {
                if(sp.Net_Amount__c!=null) {
                    DTA+=sp.Net_Amount__c;
                }
            }
        }
        return DTA;
    }
    
    // Get clones of current record and descriptions
    private void Get_Record() {
        
        Record = Records[RecordNum].clone(true, true, true, true);
        
       	Record_Desc= new List<SPIN_Descriptions__c>();
        for (SPIN_Descriptions__c sp: Records_Desc) {
            if (sp.SPIN__c==Record.id) {
                Record_Desc.add(sp.clone(true, true, true, true));
            }
        }
        Record_Desc = SortDescriptionLines(Record_Desc, GST_GL);
        DescTotAmount=LinesTotal(Record_Desc);
    }

    public ScannedInvoicePreview(ApexPages.StandardSetController ctrl){
        // Determinate Recoverable GST GL Account...
        GST_GL = [SELECT Id, name FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c='1250' LIMIT 1].Id;
		// Get URL for returning...        
        retURL=ApexPages.currentPage().getParameters().get('retURL');
        
        If (!ctrl.getSelected().isEmpty()) {
            List<Scanned_Payable_Invoice__c> SelRecs= ctrl.getSelected();
            Records = [SELECT Id, Name, Department_Name__c, GST__c, Account_Name__c, Invoice_Date__c, Invoice_Number__c, Total_Amount__c, Status__c, Descriptions_Total_Amount__c, CreatedById, CreatedDate, LastModifiedById, LastModifiedDate FROM Scanned_Payable_Invoice__c WHERE Id IN :SelRecs];
            Records_Desc= [SELECT SPIN__c, Payable_Control_GL__c, Dimension_1__c, Dimension_2__c, Dimension_3__c, Dimension_4__c, Description__c, Net_Amount__c FROM SPIN_Descriptions__c WHERE SPIN__c IN :SelRecs];
            Edit_Id=-1;
            RecordNum=0;
        } else {
   			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No records selected for preview!'));
        }
    }
    
    // ***************************************
    //  Preview page functions
    // *************************************** 
     
    public PageReference StartPreview() {
        if (Records!=null) {
            Get_Record();
            List<Metadata.Metadata> mm= Metadata.Operations.retrieve(Metadata.MetadataType.Layout , new List<String> {'Scanned_Payable_Invoice__c-Scanned Payable Invoice Preview Layout'});
            ILayoutI = (Metadata.Layout) mm.get(0);
        }
        return null;
    }
    
    public PageReference GoFirstRecord() {
        RecordNum =0;
        Get_Record();        
        return null;
    }
    public PageReference GoPrevRecord() {
        if (RecordNum>0) {
            RecordNum --;
            Get_Record();
        }
        return null;
    }
    public PageReference GoLastRecord() {
        RecordNum=Records.size()-1;
        Get_Record();
        return null;
    }        
    public PageReference GoNextRecord() {
        if (RecordNum<(Records.size()-1)) {  
            RecordNum ++;
        }
        Get_Record();
        return null;
    }        

    public PageReference Confirm() {
        Scanned_Payable_Invoice__c Rec = Records[RecordNum];
        String MissedData=verifyForMissedData(Rec);
        if (String.isEmpty(MissedData)) {
            Rec.Status__c= 'Confirmed';
            try {
                update(Rec);
            } catch(System.DMLException e) {
                ApexPages.addMessages(e);
            }
            Approval.LockResult lr0 = Approval.lock(Rec,false);
            
            List<SPIN_Descriptions__c> Rec_D = new List<SPIN_Descriptions__c>();
            for (SPIN_Descriptions__c sp: Records_Desc) {
                if (sp.SPIN__c==Rec.id) {
                    Approval.LockResult lrL = Approval.lock(sp,false);
                }
            }
             GoNextRecord();
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to confirm current record! ' + MissedData));
        }
        return null;
    }
    
    public PageReference EditIt() {

        Get_Record();
        
        PageReference np = new PageReference('/apex/ScannedInvoiceEdit');
        np.setRedirect(false);
        return np;
    }
    
    // ***************************************
    //  Edit page functions
    // *************************************** 
    public PageReference EEmpty() {
        DescTotAmount=LinesTotal(Record_Desc);
        return null;
    }
    
    public PageReference EChangeGST() {
        
        Integer i=0;
        Integer CurLoc=-1;
        
        // Find line with GST
        for (SPIN_descriptions__c sp:Record_Desc) {
            if(sp.Payable_Control_GL__c==GST_GL) {
                CurLoc=i;
                Break;
            }
            i++;
        }
        
        // If GST equal 0 - we need to delete GST line
        if (Record.GST__c==0 && CurLoc!=-1)  {
            Record_Desc.remove(CurLoc);          
        } else {
            // If no GST present - create new line
            if (CurLoc==-1) {
                Record_Desc.add(new SPIN_descriptions__c(SPIN__c=Record.Id));              
                CurLoc=Record_Desc.size()-1;
            }
            
            SPIN_descriptions__c spn = Record_Desc[CurLoc];
            spn.Payable_Control_GL__c=GST_GL;
            Decimal g=Record.GST__c/2;
            spn.Net_Amount__c= g.setScale(2,System.RoundingMode.HALF_UP);
            Edit_Id=-1;
            DescTotAmount=LinesTotal(Record_Desc);        }
        
        return null;
    }
    
    public PageReference EAddDescriptionLine() {
        SPIN_descriptions__c New_sp = new SPIN_descriptions__c();
        New_sp.SPIN__c = Record.Id;
        
        Edit_Id =Record_Desc.size();
        
        While(Edit_Id>0) {
            SPIN_descriptions__c sp=Record_Desc.get(Edit_Id-1);
            if(sp.Payable_Control_GL__c!=GST_GL) {
                break;
            }
            Edit_Id--;
        }
        if (Edit_Id==Record_Desc.size()) {
            Record_Desc.add(New_sp);
        } else {
            Record_Desc.add(Edit_Id,New_sp);
        }
        Edit_Id++;
        
        return null;
    }
    
    public PageReference EDelDescriptionLine() {
        
        Record_Desc.remove(Edit_Id-1);
        DescTotAmount=LinesTotal(Record_Desc);
        Edit_Id=-1;        
        
        return null;
    }
    
    // Recalculate Lines amount    
    public PageReference EChangeLinesAmount() {
		DescTotAmount=LinesTotal(Record_Desc);
        return null;
    }

    public PageReference ESaveEdit() {
        
        PageReference np = new PageReference('/apex/ScannedInvoicePreview');
        np.setRedirect(false);
        // *******************************************************************************
        // * Update Records & Records_Desc lists
        // *******************************************************************************        
        
        // 1. Delete all Descriptions relateted to current Scanned invoice from Records_Desc 
        Integer ii=Records_Desc.Size()-1;
        While(ii>-1) {
            SPIN_descriptions__c sp=Records_Desc.get(ii);
            if(sp.SPIN__c==Record.Id) {
                Records_Desc.remove(ii);
            }
            ii--;
        } 
        // 2. Add modified records for current Scanned Invoice Descriptions
        for (SPIN_Descriptions__c sp: Record_Desc) {
            Records_Desc.add(sp);   
        }
        // 3. Change Scanned Invoice Records information
        Records.set(RecordNum,Record);
        
        // *******************************************************************************
        // * Update actual Invoice & Descriptions in the database
        // *******************************************************************************        
        
        // 4. Update Scanned Invoice in database
        try {
            update(Record);
        } catch(System.DMLException e) {
            ApexPages.addMessages(e);
        }        
        // 5. Delete all Descriptions what were deleted during editing from database
        List<SPIN_Descriptions__c> DelList=[SELECT Id, Name FROM SPIN_Descriptions__c WHERE SPIN__c = :Record.Id AND Id NOT IN :Record_Desc];
        if (DelList.size()>0) {
            try {
                delete DelList;
            } catch(System.DMLException e) {
                ApexPages.addMessages(e);
            }
        }
        
        // 6. Push all Descriptions for current Invoice into Database
        try {
            upsert(Record_Desc);
        } catch(System.DMLException e) {
            ApexPages.addMessages(e);
        }
        
        Edit_Id=-1;
        return np;
    }  
    
    public PageReference ECancelEdit() {
        
        Get_Record();
        PageReference np = new PageReference('/apex/ScannedInvoicePreview');
        np.setRedirect(false);
        Edit_Id=-1;
        
        return np;
    }
 }