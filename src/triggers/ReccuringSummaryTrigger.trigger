trigger ReccuringSummaryTrigger on kell6_core__Receipt__c (before update, before insert) {
       List<kell6_core__Receipt__c> tr = new List<kell6_core__Receipt__c>();
    
        tr = Trigger.new;
        String MergedText;
        List<Opportunity> OppList;
        String receiptStartDateText;
        Date receiptStartDate;
        String receiptEndDateText;
        Date receiptEndDate;
        String receiptName;
        String receiptDateText;
        String taxReceiptable;
        Decimal totalValueOfGifts;
        Boolean j;
    
    for (kell6_core__Receipt__c Rc : tr) {


            // Separate donations into This Receipt and Previously Receipted
            if ((Rc.id !=null) && (Rc.RecordTypeId == '01236000001HqN1')) {
                
        receiptStartDateText = '01/01/' + Rc.kell6_core__Receipted_Year__c;
        receiptStartDate = Date.parse(receiptStartDateText);
        receiptEndDateText ='31/12/' + Rc.kell6_core__Receipted_Year__c;
        receiptEndDate = Date.parse(receiptEndDateText);

                OppList = [select kell6_core__Receipted__c, Closedate, kell6_core__Receipt_Date__c, kell6_core__Receipt_Acknowledgement__c, kell6_core__Receipt_Acknowledgement__r.Name, kell6_core__Receipt_Acknowledgement__r.kell6_core__Receipted_Amount__c, CnP_PaaS__C_P_Recurring__c, kell6_core__Receiptable_Amount__c, Tax_Receiptable__c, kell6_core__Legacy_Receipt_Number__c FROM Opportunity WHERE Closedate >= :receiptStartDate AND Closedate <= :receiptEndDate AND npsp__Primary_Contact__c = :Rc.kell6_core__Receipt_Contact__c AND kell6_core__Receiptable_Amount__c > 0.00 AND StageName = 'Received' ORDER BY Closedate, kell6_core__Receipt_Date__c, kell6_core__Receipt_Acknowledgement__r.Name];
//              OppList= [select kell6_core__Receipted__c, Closedate, kell6_core__Receipt_Date__c, kell6_core__Receipt_Acknowledgement__c, kell6_core__Receipt_Acknowledgement__r.Name, kell6_core__Receipt_Acknowledgement__r.kell6_core__Receipted_Amount__c, CnP_PaaS__C_P_Recurring__c, kell6_core__Receiptable_Amount__c, kell6_core__Receipt_Contact__c FROM Opportunity WHERE kell6_core__Receipt_Acknowledgement__c=:Rc.Id ORDER BY kell6_core__Receipt_Date__c, kell6_core__Receipt_Acknowledgement__r.Name, Closedate];

                MergedText='<tr><td colspan="4">Gifts Included on this Receipt</td></tr>';
                MergedText +='<tr><td style="font-weight: bold; font-size: 13px; text-decoration: underline;">Donation Date</td><td style="font-weight: bold; font-size: 13px; text-decoration: underline;">Amount</td>' +
                    '<td style="font-weight: bold; font-size: 13px; text-decoration: underline;">Receipt Number</td>' +
                    '<td style="font-weight: bold; font-size: 13px; text-decoration: underline;">Receipt Date</td></tr>';

                totalValueOfGifts = 0.00;        
                for (Opportunity OppX: OppList) {
                    If (OppX.kell6_core__Receipt_Acknowledgement__c == Rc.Id) {
                        MergedText+='<tr><td>' + String.ValueOf(OppX.CloseDate) +'</td><td>' + String.ValueOf(OppX.kell6_core__Receiptable_Amount__c)+'</td><td>'+ String.ValueOf(Rc.Name) + '</td><td>' + String.valueOf(OppX.kell6_core__Receipt_Date__c)+'</td></tr>';
                        totalValueOfGifts += OppX.kell6_core__Receiptable_Amount__c;
                    }
                }
                MergedText += '<tr><td><strong>Total</strong></td><td><strong>' + String.valueOf(totalValueOfGifts.setScale(2)) + '</strong></td><td></td></tr>';

                
                j = False;
                totalValueOfGifts = 0.00;        
                for (Opportunity OppX: OppList) {
                    If (OppX.kell6_core__Receipt_Acknowledgement__c != Rc.Id) {
                        If (!j) {
                            MergedText+='<tr><td colspan="4"><br/></td></tr>';
                            MergedText+='<tr><td colspan="4">Gifts Not Included on this Receipt</td></tr>';
                            MergedText +='<tr><td style="font-weight: bold; font-size: 13px; text-decoration: underline;">Donation Date</td><td style="font-weight: bold; font-size: 13px; text-decoration: underline;">Amount</td>' +
                                '<td style="font-weight: bold; font-size: 13px; text-decoration: underline;">Receipt Number</td>' +
                                '<td style="font-weight: bold; font-size: 13px; text-decoration: underline;">Receipt Date</td></tr>';
                            j= True;
                        }
                        
                    if (OppX.kell6_core__Receipt_Acknowledgement__c!=null) {
                        receiptName = OppX.kell6_core__Receipt_Acknowledgement__r.Name;
                        receiptDateText = String.valueOf(OppX.kell6_core__Receipt_Date__c);
                    } else {
                        if (OppX.kell6_core__Legacy_Receipt_Number__c != null) {
                            receiptName = OppX.kell6_core__Legacy_Receipt_Number__c;
                        } else {
                            receiptName = '---';
                        }
                        receiptDateText = 'Information not available';
                    }    
                        
                        MergedText+='<tr><td>' + String.ValueOf(OppX.CloseDate) +'</td><td>' + String.ValueOf(OppX.kell6_core__Receiptable_Amount__c)+'</td><td>'+ receiptName + '</td><td>' + receiptDateText +'</td></tr>';
                        totalValueOfGifts += OppX.kell6_core__Receiptable_Amount__c;
                    }
                }
                If (j) {
                    MergedText += '<tr><td><strong>Total</strong></td><td><strong>' + String.valueOf(totalValueOfGifts.setScale(2)) + '</strong></td><td></td></tr>';
                }
                Rc.Donations_List__c=MergedText;
            }
            
            
            /*
            
            
            // All receipts summarized together
            if ((Rc.id !=null) && (Rc.RecordTypeId == '01236000001HqN1') && (Rc.kell6_core__Receipt_Contact__c!=null)) 
            {
                receiptStartDateText = '01/01/' + Rc.kell6_core__Receipted_Year__c;
                receiptStartDate = Date.parse(receiptStartDateText);
                receiptEndDateText ='31/12/' + Rc.kell6_core__Receipted_Year__c;
                receiptEndDate = Date.parse(receiptEndDateText);
                totalValueOfGifts = 0.00;
                
                OppList = [select kell6_core__Receipted__c, Closedate, kell6_core__Receipt_Date__c, kell6_core__Receipt_Acknowledgement__c, kell6_core__Receipt_Acknowledgement__r.Name, kell6_core__Receipt_Acknowledgement__r.kell6_core__Receipted_Amount__c, CnP_PaaS__C_P_Recurring__c, kell6_core__Receiptable_Amount__c, Tax_Receiptable__c, kell6_core__Legacy_Receipt_Number__c FROM Opportunity WHERE Closedate >= :receiptStartDate AND Closedate <= :receiptEndDate AND npsp__Primary_Contact__c = :Rc.kell6_core__Receipt_Contact__c AND kell6_core__Receiptable_Amount__c > 0.00 AND StageName = 'Received' ORDER BY Closedate, kell6_core__Receipt_Date__c, kell6_core__Receipt_Acknowledgement__r.Name];
                MergedText ='<tr><td style="font-weight: bold; font-size: 13px; text-decoration: underline;">Donation Date</td><td style="font-weight: bold; font-size: 13px; text-decoration: underline;">Amount</td>' +
                    '<td style="font-weight: bold; font-size: 13px; text-decoration: underline;">Receipt Number</td>' +
                    '<td style="font-weight: bold; font-size: 13px; text-decoration: underline;">Receipted Date</td></tr>';
                for (Opportunity OppX: OppList) {
                    
                    if (OppX.kell6_core__Receipt_Acknowledgement__c!=null) {
                        receiptName = OppX.kell6_core__Receipt_Acknowledgement__r.Name;
                        receiptDateText = String.valueOf(OppX.kell6_core__Receipt_Date__c);
                    } else {
                        if (OppX.kell6_core__Legacy_Receipt_Number__c != null)
                        {
                            receiptName = OppX.kell6_core__Legacy_Receipt_Number__c;
                        }
                        else
                        {
                            receiptName = '---';
                        }
                        receiptDateText = 'Information not available';
                    }    
                    taxReceiptable = OppX.Tax_Receiptable__c;
                    if (taxReceiptable.indexOf('Acknowledge') < 0)
                    {
                        if (receiptName.indexOf('Trigger') != -1)
                        {
                            receiptName = Rc.Name;
                            //opportunitiesIncludedOnReceipt += '<tr><td>' + String.ValueOf(OppX.CloseDate) + '</td><td>' + String.ValueOf(OppX.kell6_core__Receiptable_Amount__c) + '</td></tr>';
                        }
                        MergedText+='<tr><td>' + String.ValueOf(OppX.CloseDate) +'</td><td>' + String.ValueOf(OppX.kell6_core__Receiptable_Amount__c)+'</td><td>'+ receiptName + '</td><td>' + receiptDateText +'</td></tr>';
                        totalValueOfGifts += OppX.kell6_core__Receiptable_Amount__c;
                    }
                }
                Rc.Donations_List__c=MergedText;
                Rc.Donations_List__c += '<tr><td><strong>Total</strong></td><td><strong>' + String.valueOf(totalValueOfGifts.setScale(2)) + '</strong></td><td></td></tr>';
                //Rc.Text_for_Receipt__c = opportunitiesIncludedOnReceipt;
            }

*/
    }
}