/**
 * @author Kevin Waites -> kevinwaites.com
 * @date 2022
 * @description API Rest Resource to be used with RemitSQL
 * Accepts input from scanned documents and creates a relevant Chargent Order or Opportunity
 */
@RestResource(urlMapping='/DonationProcessing/*')
//@RestResource(urlMapping='/ScanStationInput/*')
global with sharing class ScanStationInputService {

  public static String completeMessage {
    get { return completeMessage; }
    set{ completeMessage += value; }
  }

  public static String resultMessage {
    get { return resultMessage; }
    set{ resultMessage = value; }
  }


  /**
   * Receive Input
   * @description Accepts and validates scanned input, processes the fields and creates
   * a Chargent Order or Opportunity
   * @param   Inputs    transactionInfo                         class variable of inputs. See below
   * @return  Result(resultMessage, completeMessage, oppId)     class variable of Result. See below
   */
  @HttpPost
  global static Result receiveInput(Inputs transactionInfo){
    // Initialize variables for the return Result messages
    Id oppId;
    
    // Check if the there is input information
    if(transactionInfo != null){

      // Validate the inputs and convert from a series of Strings
      TypedInputs typedTransactionInfo = validateInputs(transactionInfo);

      Opportunity newOpp = new Opportunity();
      
      completeMessage = '';

      /**
       * Create Opportunity or Chargent Order depending on the Payment method 
       * Credit Card -> Create a Chargent Order to be processed which will then create an Opportunity through a triggered flow
       * Check, Cash -> Create an Opportunity directly
       * Money order, Google checkout, Bank Account -> Not currently supported
       */
      switch on typedTransactionInfo.paymentMethod {
        when 'Credit Card' {
          ChargentOrders__ChargentOrder__c newCo = createChargentOrder(transactionInfo, typedTransactionInfo);

          // TODO: wait for Transaction to complete
          // Currently there is a while loop below that looks for the Transaction every second for 8 seconds
          // this is NOT best practice
          
          // ChargentOrders__Transaction__c newTr = new ChargentOrders__Transaction__c();
          // newTr = [SELECT Id FROM ChargentOrders__Transaction__c WHERE ChargentOrders__Order__c = :newCo.Id LIMIT 1];

          // Confirm that the new ChargentOrder was created
          If(String.isNotBlank(newCo.Id)){
            // Chargent will charge the Credit Card in this order and when complete will create a Chargent Transaction
            // Get the new Chargent Transaction for this Order
            ChargentOrders__Transaction__c[] newTrs = [SELECT Id FROM ChargentOrders__Transaction__c WHERE ChargentOrders__Order__c = :newCo.Id LIMIT 1];

            // Confirm that the Transaction was found and populate the complete message appropriately 
            if(newTrs.size() > 0){
              completeMessage = 'Transaction Created | ';
              resultMessage = 'Success';
            } else {
              
              // If the Transaction is not found there could have been a delay in processing and returning the data
              // Wait 1 second and try again. Do this only 8 times
              Integer count = 0;
              while((newTrs.size() == 0) && (count < 8)) { //TODO combine steps to find Opportunities with Transactions that match the Order
                datetime start = System.Now();
                while(system.Now() < start.addSeconds(1)){}
                newTrs = [SELECT Id, Opportunity__c FROM ChargentOrders__Transaction__c WHERE ChargentOrders__Order__c = :newCo.Id LIMIT 1];
                // newTrs = [SELECT Id FROM ChargentOrders__Transaction__c LIMIT 1];
                count ++;
              }
              
              // If a Transaction is found, update the completeMessage and find the related Opportunity
              if(newTrs.size() > 0) {
                completeMessage = 'Transaction Created | ';
                resultMessage = 'Success';
                Opportunity newOppty = [SELECT Id FROM Opportunity WHERE Id = :newTrs[0].Opportunity__c LIMIT 1];
                oppId = newOppty.Id;
              }else {
                // If a Transaction is still not found, update the message appropriately
                completeMessage = 'Delay in processing transaction, no Opportunity created yet. | ';
                resultMessage = 'Success';
                oppId = newCo.Id;
              }
            }
          }
          // TODO: wait for Opportunity to be created
          // if(newTr == null){
          //   completeMessage = 'Delay in processing transaction, no Opportunity created yet. ';
          //   resultMessage = '';
          // }
        }
        when 'Check' { 
          newOpp = createOpportunityNoTransaction(typedTransactionInfo); 
          oppId = newOpp.Id;
          resultMessage = resultMessage == 'error' ? 'error' : 'Success';
        }
        when 'Cash' { 
          newOpp = createOpportunityNoTransaction(typedTransactionInfo); 
          oppId = newOpp.Id;
          resultMessage = resultMessage == 'error' ? 'error' : 'Success';
        }
        when 'Money Order' { 
          completeMessage = 'The Payment Method \'Money Order\' is not supported at this time. Unable to process transaction/donation. | ';
          resultMessage = 'error';
        }
        when 'Google Checkout' { 
          completeMessage = 'The Payment Method \'Google Checkout\' is not supported at this time. Unable to process transaction/donation. | ';
          resultMessage = 'error';
        }
        when 'Bank Account' { 
          completeMessage = 'The Payment Method \'Bank Account\' is not supported at this time. Unable to process transaction/donation. ';
          resultMessage = 'error';
        }
        when else {
          completeMessage = 'The Payment Method is not valid. Unable to process transaction/donation. The current payment method is: ' + typedTransactionInfo.paymentMethod + ' | ';
          resultMessage = 'error';
        }
      }

    }else{ // no input information -> set the return messages
      completeMessage = 'There was an error receiving information. No inputs found. | ';
      resultMessage = 'error';

    }

    // if complete message is blank we can assume success. Set Return messages accordingly
    if(string.isBlank(completeMessage) || completeMessage == null || completeMessage == ''){
      resultMessage = 'Success';
    }

    //return transactionInfo;
    return new Result(resultMessage, completeMessage, oppId);
  }

  /**
   * Validate Inputs
   * @description Receives the REST inputs as a series of Strings and converts them to the appropriate data type
   * @param   transactionInfo       Class variable (see below)
   * @return                        TypedInputs class variable (see below)
   */
  private static TypedInputs validateInputs(Inputs transactionInfo){
    TypedInputs ti = new TypedInputs();

    final Type batchType = npsp__Batch__c.class; // type for batchId
    final Type campaignType = Campaign.class; // type for campaignId
    final Type designationType = donation_split__Designation__c.class; // type for fundId
    final Type packageType = Package__c.class; // type for packageId
    final Type opportunityType = Opportunity.class; // type for opportunityId
    final Type contactType = Contact.class; // type for contactId & honoreeContactId
    final Type accountType = Account.class; // type for accountId
    final Type appealType = Campaign.class; // type for appealId

    final String accountPrefix='001';
    final String contactPrefix='003';
    final String batchPrefix = 'a0M';
    final String campaignPrefix = '701';
    final String designationPrefix = 'a79';
    final String packagePrefix = 'a0i';
    final String opportunityPrefix = '006';

    final Schema.sObjectField gc = ChargentOrders__ChargentOrder__c.TMS_Gift_Channel__c; // for gift channel picklist
    final Schema.sObjectField pm = ChargentOrders__ChargentOrder__c.ChargentOrders__Payment_Method__c; // for payment method picklist
    final Schema.sObjectField ty = ChargentOrders__ChargentOrder__c.TMS_Opportunity_Type__c; // for type picklist
    final Schema.sObjectField tt = ChargentOrders__ChargentOrder__c.TMS_Tribute_Type__c; // for tribute type picklist
    final Schema.sObjectField ikt = ChargentOrders__ChargentOrder__c.TMS_In_Kind_Type__c; // for in-kind type picklist
    final Schema.sObjectField ikst = ChargentOrders__ChargentOrder__c.TMS_In_Kind_Sub_Type__c; // for in-kind sub-type picklist

    ti.anonymous = validateBooleanInput(transactionInfo.anonymous);
    ti.bankAccountNumber = validateStringInput(transactionInfo.bankAccountNumber);
    ti.bankRoutingNumber = validateStringInput(transactionInfo.bankRoutingNumber);
    
    string batchvalidate = validateSalesforceId(transactionInfo.batchId, batchType, batchPrefix, 'batchId');
    if(batchvalidate == 'error') {
      completeMessage = 'The BatchId is not valid or there is no record with that Id in the database. Unable to process transaction/donation. BatchId provided: ' + transactionInfo.batchId + ' | ';
      resultMessage = 'error';

    } else {
      ti.batchId = batchvalidate;
    }
    ti.billingName = validateStringInput(transactionInfo.billingName);

    if(transactionInfo.cardExpirationMonth != null){
      ti.cardExpirationMonth = myDecrypter(transactionInfo.cardExpirationMonth, transactionInfo.tmsTransactInfo);
    }
    if(transactionInfo.cardExpirationYear != null) {
      ti.cardExpirationYear = myDecrypter(transactionInfo.cardExpirationYear, transactionInfo.tmsTransactInfo);
    }
    
    // completeMessage = 'cardNumber: ' + transactionInfo.cardNumber + ' | ';
    if(transactionInfo.cardNumber != null) {
      ti.cardNumber = myDecrypter(transactionInfo.cardNumber, transactionInfo.tmsTransactInfo).replace('-', '');
      // completeMessage = 'myDecrypter ran on the cardnumber. transactionInfo| ' + transactionInfo.cardNumber + ' | ti| ' + ti.cardNumber + '| ';
      // resultMessage = 'decrypt';

    }
    if(transactionInfo.cvc != null) {
      ti.cvc = myDecrypter(transactionInfo.cvc, transactionInfo.tmsTransactInfo);
    }
    // ti.campaignId = validateSalesforceId(transactionInfo.campaignId, campaignType, campaignPrefix);
    ti.chargeAmount = validateCurrencyInput(transactionInfo.chargeAmount); 
    ti.chargeDate = validateDateInput(transactionInfo.chargeDate);
      if(ti.chargeDate == null){
        ti.chargeDate = date.Today();
      }
    ti.exceptionBatchFlags = validateStringInput(transactionInfo.exceptionBatchFlags);
    
    String fundIdValidate = validateSalesforceId(transactionInfo.fundId, designationType, designationPrefix, 'fundId');
    if(fundIdValidate == 'error') {
      completeMessage = 'The FundId is not valid or there is no record with that Id in the database. Unable to process transaction/donation. FundId provided: ' + transactionInfo.fundId + ' | ';
      resultMessage = 'error';

    } else {
      ti.fundId = fundIdValidate;
    }
    ti.furtherAttentionNotes = validateStringInput(transactionInfo.furtherAttentionNotes);
    ti.giftChannel = validatePicklistValue(transactionInfo.giftChannel, gc) ? transactionInfo.giftChannel : 'Mail';
    ti.giftReference = validateStringInput(transactionInfo.giftReference);
    ti.noReceipt = validateBooleanInput(transactionInfo.noReceipt);

    ti.appealId = validateSalesforceId(transactionInfo.appealId, appealType, campaignPrefix, 'appealId');
    ti.packageId = validateSalesforceId(transactionInfo.packageId, packageType, packagePrefix, 'packageId');
    ti.appealTMSid = validateTMSid(transactionInfo.appealTMSid) ? transactionInfo.appealTMSid : ''; 

    ti.packageTMSid = validateTMSid(transactionInfo.packageTMSid) ? transactionInfo.packageTMSid : ''; 

    ti.parentOpportunity = validateSalesforceId(transactionInfo.parentOpportunity, opportunityType, '006', 'parentOpportunity');
    // ti.paymentMethod = (transactionInfo.paymentMethod == 'Cheque') ? 'Check' : transactionInfo.paymentMethod;
    if(transactionInfo.paymentMethod == 'Cheque'){
      transactionInfo.paymentMethod = 'Check';
    }
    ti.paymentMethod = validatePicklistValue(transactionInfo.paymentMethod, pm) ? transactionInfo.paymentMethod : '';
    ti.recurringDonation = validateBooleanInput(transactionInfo.recurringDonation);
    ti.TMScity = validateStringInput(transactionInfo.TMScity); 
    ti.type = validatePicklistValue(transactionInfo.type, ty) ? transactionInfo.type : '';
    ti.contactId = validateSalesforceId(transactionInfo.contactId, contactType, contactPrefix, 'contactId');
    ti.accountId = validateSalesforceId(transactionInfo.accountId, accountType, accountPrefix, 'accountId');
    ti.tributeType = validatePicklistValue(transactionInfo.tributeType, tt) ? transactionInfo.tributeType : '';
    ti.tributeDescription = validateStringInput(transactionInfo.tributeDescription);
    ti.honoreeName = validateStringInput(transactionInfo.honoreeName);
    ti.honoreeContactId = validateSalesforceId(transactionInfo.honoreeContactId, contactType, contactPrefix, 'honoreeContactId');
    ti.benefitValue = validateCurrencyInput(transactionInfo.benefitValue);
    ti.inKindType = validatePicklistValue(transactionInfo.inKindType, ikt) ? transactionInfo.inKindType: '';
    ti.inKindSubtype = validatePicklistValue(transactionInfo.inKindSubtype, ikt) ?  transactionInfo.inKindSubtype : '';
    ti.inKindDeclaredValue = validateBooleanInput(transactionInfo.inKindDeclaredValue);
    ti.inKindVerifiedValue = validateBooleanInput(transactionInfo.inKindVerifiedValue);
    ti.inKindDescription = validateStringInput(transactionInfo.inKindDescription);
    ti.inKindValuationNote = validateStringInput(transactionInfo.inKindValuationNote);  
    ti.scannedImage = validateStringInput(transactionInfo.scannedImage);// TODO: how to validate image file?
    ti.checkImage = validateStringInput(transactionInfo.checkImage);
    ti.slipImage = validateStringInput(transactionInfo.slipImage);

    if(String.isBlank(ti.appealId) && !String.isBlank(ti.appealTMSid)){
      List<Campaign> cList = [SELECT Id FROM Campaign WHERE Campaign_Appeal_ID__c = :ti.appealTMSid LIMIT 1];
      if(cLIst.size() > 0) {
        ti.appealId = cList[0].id;
      }
    }

    if(String.isBlank(ti.packageId) && !String.isBlank(ti.packageTMSid)){
      List<Package__c> pList = [SELECT Id FROM Package__c WHERE Package_ID__c = :ti.packageTMSid AND Campaign_Appeal__c = :ti.appealId LIMIT 1];
      if(pList.size() > 0) {
        ti.packageId = pList[0].id;
      }
    }

    return ti;
  }
  
  /**
   * Create an Opportunity from the details of a Chargent Order
   * @param co      Chargent Order record
   * @return        the Opportunity that is created
   */
  private static Opportunity createOpportunityNoTransaction(TypedInputs transactionInfo){
    Opportunity op = new Opportunity();
    op.Name = 'a';
    op.AccountId = transactionInfo.accountId;
    op.Amount = transactionInfo.chargeAmount;
    op.Anonymous__c = transactionInfo.anonymous;
    op.CampaignId = transactionInfo.appealId;
    op.Package__c = transactionInfo.packageId;
    // op.CampaignId = transactionInfo.campaignId;
    // op.Cheque_Number__c = '';
    op.CloseDate = transactionInfo.chargeDate;
    // op.Description = transactionInfo.;
    //op.Designation__c = transactionInfo.TMS_Designation__c; //TODO handle no designation
    // op.Fund__c = transactionInfo.; // TODO: assign FUND - and assign fund in co
    op.Gift_Channel__c = transactionInfo.giftChannel;
    // op.Gift_Designation__c = transactionInfo.; // TODO: should we use Designation or Gift_Designation?
    op.Gift_in_Kind_Sub_Type__c = transactionInfo.inKindSubtype;
    if(string.isNotBlank(transactionInfo.furtherAttentionNotes)){
      op.Gift_Needs_Further_Attention__c = true;
    } else {
      op.Gift_Needs_Further_Attention__c = false;
    }
    op.Gift_Needs_Further_Attention_Notes__c = transactionInfo.furtherAttentionNotes;
    op.Gift_Reference__c = transactionInfo.giftReference;
    op.In_Kind_Valuation_Notes__c = transactionInfo.inKindValuationNote;
    op.In_Kind_Verified_Value__c = transactionInfo.inKindVerifiedValue;
    //op.Invoice_Number__c = transactionInfo.ChargentOrders__Invoice_Number__c;
    // op.LeadSource = transactionInfo.; // TODO: see if this can be completed
    op.npsp__Batch__c = transactionInfo.batchId;
    //op.npsp__Batch_Number__c = transactionInfo.; // TODO: can this be completed?
    op.npsp__In_Kind_Description__c = transactionInfo.inKindDescription;
    op.npsp__In_Kind_Donor_Declared_Value__c = transactionInfo.inKindDeclaredValue;
    op.npsp__In_Kind_Type__c = transactionInfo.inKindType;
    op.npsp__Primary_Contact__c = transactionInfo.contactId;
    op.npsp__Tribute_Type__c = transactionInfo.tributeType;
    op.Tribute_Description__c = transactionInfo.tributeDescription;
    op.Payment_Method__c = transactionInfo.paymentMethod;
    op.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
    op.Site__c = transactionInfo.tmsCity;
    op.StageName = 'Received';
    op.TMS_City__c = transactionInfo.tmsCity;
    op.Type = 'Cash';

    try{
      insert op;
    } catch ( Exception e ) {
        // StringException, TypeException
        completeMessage = 'There was an error creating the Opportunity Record. Salesforce provided the following error: ' + e + '. Unable to process transaction/donation. | ' + 
        ' Opportunity Details: ' +
        ' AccountId:' + op.AccountId +
        ' Amount:' + op.Amount +
        ' Anonymous__c:' + op.Anonymous__c +
        ' CampaignId:' + op.CampaignId +
        ' Package__c:' + op.Package__c +
        ' CloseDate:' + op.CloseDate +
        ' Gift_Channel__c:' + op.Gift_Channel__c +
        ' Gift_in_Kind_Sub_Type__c:' + op.Gift_in_Kind_Sub_Type__c +
        ' Gift_Needs_Further_Attention__c:' + op.Gift_Needs_Further_Attention__c +
        ' Gift_Reference__c:' + op.Gift_Reference__c +
        ' In_Kind_Valuation_Notes__c:' + op.In_Kind_Valuation_Notes__c +
        ' In_Kind_Verified_Value__c:' + op.In_Kind_Verified_Value__c +
        ' npsp__Batch__c:' + op.npsp__Batch__c +
        ' npsp__In_Kind_Description__c:' + op.npsp__In_Kind_Description__c +
        ' npsp__In_Kind_Donor_Declared_Value__c:' + op.npsp__In_Kind_Donor_Declared_Value__c +
        ' npsp__In_Kind_Type__c:' + op.npsp__In_Kind_Type__c +
        ' npsp__Primary_Contact__c:' + op.npsp__Primary_Contact__c +
        ' npsp__Tribute_Type__c:' + op.npsp__Tribute_Type__c +
        ' Payment_Method__c:' + op.Payment_Method__c +
        ' RecordTypeId:' + op.RecordTypeId +
        ' Site__c:' + op.Site__c +
        ' StageName:' + op.StageName +
        ' TMS_City__c:' + op.TMS_City__c +
        ' Type:' + op.Type;

        resultMessage = 'error';   
    }

    //saveImage(transactionInfo.scannedImage, op.Id, 'Scan');
    if(String.isNotBlank(transactionInfo.checkImage) && (resultMessage != 'error')){
      saveImage(transactionInfo.checkImage, op.Id, 'Cheque');
    }
    if(String.isNotBlank(transactionInfo.slipImage) && (resultMessage != 'error')){
      saveImage(transactionInfo.slipImage, op.Id, 'Slip');
    }

    return op;
  }

  /**
   * Create Chargent Order  
   * Create a Chargent_Order__c record based on the TypedInputs
   * @params    transactionInfo     typed variables from the REST inputs
   * @return                        Result class variable (see below)
   */
  private static ChargentOrders__ChargentOrder__c createChargentOrder(Inputs rawInputs, TypedInputs transactionInfo) {
    ChargentOrders__ChargentOrder__c co = new ChargentOrders__ChargentOrder__c();
    
    co.JSON_String__c = rawInputs.ToJSONString();
    co.TMS_Anonymous__c = transactionInfo.anonymous;
    co.ChargentOrders__Bank_Account_Number__c = transactionInfo.bankAccountNumber;
    co.ChargentOrders__Bank_Routing_Number__c = transactionInfo.bankRoutingNumber;
    co.TMS_Batch__c = transactionInfo.batchId;
    co.ChargentOrders__Billing_Last_Name__c = transactionInfo.billingName;
    co.ChargentOrders__Card_Expiration_Month__c = transactionInfo.cardExpirationMonth;
    co.ChargentOrders__Card_Expiration_Year__c = transactionInfo.cardExpirationYear;
    co.ChargentOrders__Card_Number__c = transactionInfo.cardNumber;
    co.Campaign_Appeal__c = transactionInfo.appealId;
    co.Package__c = transactionInfo.packageId;
    // co.Campaign_Appeal__c = transactionInfo.campaignId;
    co.ChargentOrders__Subtotal__c = transactionInfo.chargeAmount;
    co.ChargentOrders__Date__c = transactionInfo.chargeDate;
    co.TMS_Card_CVC__c = transactionInfo.cvc;
    co.TMS_exceptionBatchFlags__c = transactionInfo.exceptionBatchFlags;
    // co.TMS_Designation__c = transactionInfo.fundId; // TODO: deal with designations
    co.TMS_Further_Attention_Notes__c = transactionInfo.furtherAttentionNotes;
    co.TMS_Gift_Channel__c = transactionInfo.giftChannel;
    co.TMS_Gift_Reference__c = transactionInfo.giftReference;
    co.Do_Not_Receipt__c = transactionInfo.noReceipt;
    co.TMS_Parent_Opportunity__c = transactionInfo.parentOpportunity;
    co.ChargentOrders__Payment_Method__c = transactionInfo.paymentMethod;
    // co. = transactionInfo.recurringDonation; // TODO: handle recurring donations
    co.TMS_City__c = transactionInfo.tmsCity;
    co.TMS_Opportunity_Type__c = transactionInfo.type;

    co.Contact__c = transactionInfo.contactId;
    co.ChargentOrders__Account__c = transactionInfo.accountId;
    co.TMS_Tribute_Type__c = transactionInfo.tributeType;
    co.TMS_Tribute_Description__c = transactionInfo.tributeDescription;
    co.TMS_Honoree_Name__c = transactionInfo.honoreeName;
    co.TMS_Honoree__c = transactionInfo.honoreeContactId;
    co.TMS_Benefit_Value__c = transactionInfo.benefitValue;
    
    co.TMS_In_Kind_Type__c = transactionInfo.inKindType;
    co.TMS_In_Kind_Sub_Type__c = transactionInfo.inKindSubtype;
    co.TMS_In_Kind_Donor_Declared_Value__c = transactionInfo.inKindDeclaredValue;
    co.TMS_In_Kind_Verified_Value__c = transactionInfo.inKindVerifiedValue;
    co.TMS_In_Kind_Description__c = transactionInfo.inKindDescription;
    co.TMS_In_Kind_Valuation_Notes__c = transactionInfo.inKindValuationNote;

    co.ChargentOrders__Payment_Status__c = 'Automated Collection';
    try{
      co.ChargentOrders__Gateway__c = [SELECT Current_Payment_Processor_ID__c FROM ChargentCurrentPaymentProcessor__c LIMIT 1][0].Current_Payment_Processor_ID__c;
    }
    catch(Exception e){
      System.debug('Error--'+ e.getMessage());
    }

    // if(String.isBlank(co.Campaign_Appeal__c) && String.isNotBlank(co.Package__c)){
    //   co.Campaign_Appeal__c = [SELECT Campaign_Appeal__c FROM Package__c WHERE Id =:co.package__c LIMIT 1].Campaign_Appeal__c;
    // }

    if(co.contact__c != null){
      List <Contact> c = [SELECT FirstName, LastName FROM Contact WHERE Id= :co.Contact__c LIMIT 1];
      co.ChargentOrders__Billing_First_Name__c = c[0].FirstName;
      co.ChargentOrders__Billing_Last_Name__c = c[0].LastName;
    }

    try{
      insert co;
    } catch ( Exception e ) {
        // StringException, TypeException
        completeMessage = 'There was an error creating the Chargent Order Record. Salesforce provided the following error: ' + e + '. Unable to process transaction/donation. | ';
        resultMessage = 'error';   
    }



    // check if checkImage and slipImage are not empty and save the images
    //saveImage(transactionInfo.scannedImage, co.Id, 'Scan');
    if(String.isNotBlank(transactionInfo.checkImage) && resultMessage != 'error'){
      saveImage(transactionInfo.checkImage, co.Id, 'Cheque');
    }
    if(String.isNotBlank(transactionInfo.slipImage) && resultMessage != 'error'){
      saveImage(transactionInfo.slipImage, co.Id, 'Slip');
    }

    return co;
  }


  /** 
   * Save Image
   * Receive an image in Base64 save it as a Content Document and Create a Content Link to either an Opportunity or Chargent Order
   * @param     base64String        image file as a base64 string
   */
  @TestVisible private static void saveImage(String base64String, Id linkId, String title){
    
    ContentVersion conVer = new ContentVersion();
    conVer.ContentLocation = 'S'; // to use S specify this document is in Salesforce, use E for external files
    conVer.PathOnClient = title + '.tiff'; // The files name, extension is important here to help with preview
    conVer.Title = 'Scanned Image'; // Display name of the file
    conVer.VersionData = EncodingUtil.base64Decode(base64String); // convert string to Blob
    
    try {
      insert conVer; // insert the ContentVersion
    } catch (Exception e) {
      completeMessage = 'There was an error Saving the scanned Image Content Version. Salesforce provided the following error:   ' + e + '. | ';
      resultMessage = 'error';   
    }

    // First get the Content Document Id from ContentVersion Object
    Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
    //create ContentDocumentLink  record 
    ContentDocumentLink conDocLink = New ContentDocumentLink();
    conDocLink.LinkedEntityId = linkId; // Specify RECORD ID here i.e Any Object ID (Standard Object/Custom Object)
    conDocLink.ContentDocumentId = conDoc;  //ContentDocumentId Id from ContentVersion
    conDocLink.shareType = 'V';
    try {
      insert conDocLink;
    } catch (Exception e) {
      completeMessage = 'There was an error Saving the scanned Image Content Link. Salesforce provided the following error:   ' + e + '. | ';
      resultMessage = 'error';   
    }
  }

  /**
   * Validate Boolean Input
   * Test a String to make sure it's not null and convert to Boolean
   * @param  inputVariable  String to be converted to boolean
   * @return                true, false, null
   */
  private static Boolean validateBooleanInput(String inputVariable){
    if(String.isNotBlank(inputVariable)){
      switch on inputVariable.toLowerCase(){
        when 'true', 'y', 't'{
          return true;
        }
        when else{
          return false;
        }
      }
    } else {
      return false;
    }
  }

  /**
   * Validate String Input
   * Test a String to make sure it's not null 
   * @param inputVariable   String to be validated
   * @return                String or ''
   */
  private static String validateStringInput(String inputVariable){
    if(String.isNotBlank(inputVariable)){
      return inputVariable;
    } else{
      return '';
    }
  }

  /** 
   * Test a String to see if it is a valid SFDC ID
   * @param sfdcId  the ID to test.
   * @param t       the Type of the sObject to compare against
   * @return        Returns true if the ID is valid, false if it is not.
   * 
   * source/credit: https://www.justinsilver.com/technology/salesforce/salesforce-sobject-id-validation-apex/
   */
  private static String validateSalesforceId(String sfdcId, System.type t, String prefix, String label) {
    if(String.isNotBlank(sfdcId)){
      if(sfdcId.left(3) == prefix){
        try{
          if(Pattern.compile( '[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}' ).matcher(sfdcId).matches()){
            // Try to assign it to an Id before checking the type
            Id id = sfdcId;

            // Use the Type to construct an instance of this sObject
            sObject sObj = (sObject) t.newInstance();

            // Set the ID of the new object to the value to test
            sObj.Id = id;

            // START HERE: figure out a soql query on a variable FROM 
            // https://salesforce.stackexchange.com/questions/149244/using-a-variable-after-from-in-soql-statement
            //sObject mytest = [SELECT Id from :sObj WHERE Id = :sfdcId LIMIT 1];
            // If the tests passed, it's valid
            return sfdcId;
          }
        } catch ( Exception e ) {
          // StringException, TypeException
          completeMessage = 'The ' + label + ' is not valid or there is no record with that Id in the database. Unable to process transaction/donation. ' + label + ' provided: ' + sfdcId + ' | ';
          resultMessage = 'error';   
          return '';
        }
      } else {
        try{
          if(Pattern.compile( 'A[0-9]{7}|C[0-9]{7}' ).matcher(sfdcId).matches()){
            switch on sfdcId.left(1) {
              when 'A'{ // TMS account Id
                List<Account> a = [SELECT Id FROM Account WHERE Account_ID__c = :sfdcId LIMIT 1];
                return a[0].Id;
              }
              when 'C'{ // TMS contact Id
                List<Contact> c = [SELECT Id FROM Contact WHERE Contact_ID__c = :sfdcId LIMIT 1];
                return c[0].Id;
              }
              when else{ // unknown/invalid
                completeMessage = 'The ' + label + ' is not valid or there is no record with that Id in the database. Unable to process transaction/donation. ' + label + ' provided: ' + sfdcId + ' | ';
                resultMessage = 'error';        
                return '';
              }
            }
          } else {
            completeMessage = 'The ' + label + ' is not valid or there is no record with that Id in the database. Unable to process transaction/donation. ' + label + ' provided: ' + sfdcId + ' | ';
            resultMessage = 'error';   
            return '';
            }
        } catch (Exception e) {
          completeMessage = 'The ' + label + ' is not valid or there is no record with that Id in the database. Unable to process transaction/donation. ' + label + ' provided: ' + sfdcId + ' | ';
          resultMessage = 'error';   
          return '';
        }
      }
    } else { //blank input
      return null;
    }
    return null;
  }

  /** 
   * Test a String to see if it is a valid TMS id
   * @param tmsID   the ID to test.
   * @return        Returns true if the ID is valid, false if it is not.
   * 
   * source/credit: https://www.justinsilver.com/technology/salesforce/salesforce-sobject-id-validation-apex/
   */
  private static Boolean validateTMSid(String tmsID) {
    if (tmsId != null){
      return tmsId.length() > 4;
    } else {
      return false;
    }
  }

  /**
   * Validate Currency Input
   * Test a String to make sure it's not null and convert to a currency
   * @param inputVariable   String to be converted 
   * @return                String or ''
   */
  private static Decimal validateCurrencyInput(String inputVariable){
    if(String.isNotBlank(inputVariable)){
      return decimal.valueOf(inputVariable);
    } else{
      return 0;
    }
  }

  /**
   * Validate Date Input
   * Test a String to make sure it's not null and convert to a date
   * @param inputVariable   String to be converted 
   * @return                String or ''
   */
  private static Date validateDateInput(String inputVariable){
    if(String.isNotBlank(inputVariable)){
      return date.valueOf(inputVariable);
    } else{
      return null;
    }
  }

  /**
   * Validate that a string is a valid picklist value
   * @param value   value to validate 
   * @param field   the field to find the picklist value in
   * @return        Return a list of the active values
   * 
   * source/credit: https://www.jamessimone.net/blog/joys-of-apex/picklist-validation/
   */
  private static Boolean validatePicklistValue(String value, SOBjectField field) {
    if(String.isNotBlank(value)) { 
      if(getPicklistValues(field).contains(value)) {
        return true;
      } else {
        return false;  
      }
    } else {
      return false;
    }
  }

  /**
   * Payment Method
   * Determines if the Payment Method input is a valid input
   * 
   * @param   inputPaymentMethod  the payment method input to test
   * @return                      Map<Payment Method, Error Message> 
   */
  private static Map<String, String> setPaymentMethod(String inputPaymentMethod){
      // Payment Method - REQUIRED
      // Cash | Cheque | Credit Card | Direct Debit | Stock Transfer | EFT | Other 
      // If the paymentMethod exists assign to Chargent Order 
      // else cardNumber is not null, use 'Credit Card'
      // else bankAccountNumber is not null, use 'Bank Account'
      Map<String, String> returnMap = new Map<String, String>();
      if(String.isNotBlank(inputPaymentMethod)){
        inputPaymentMethod = (inputPaymentMethod == 'Cheque')? 'Check' : inputPaymentMethod;
        Schema.sObjectField pm = ChargentOrders__ChargentOrder__c.ChargentOrders__Payment_Method__c;
        if(validatePicklistValue(inputPaymentMethod, pm)){
          returnMap.put(inputPaymentMethod, '');
          return returnMap;
        } else {
          returnMap.put('', 'Payment method is not a valid choice');
          return returnMap;
        }
      } else {
        returnmap.put('', 'missing required Payment Method');
        return returnMap;
      }
  }

  /**
   * Decrypter
   * Receives an AES 256 encrypted string and decodes it with a pre-stored key and Initialization Vector (IV)
   * 
   * @param inputString           an AES256 encrypted string
   * @return                      unencrypted string
   */
  private static String myDecrypter(String inputString, String myIV){

    List<remitSQL_REST_API_Settings__mdt> remitSettings = new List<remitSQL_REST_API_Settings__mdt>();
    remitSettings = [SELECT Encryption_Key__c FROM remitSQL_REST_API_Settings__mdt LIMIT 1];

    // Testing Settings
    // String inputString = 'Ljz9iMNGIPU3Xwg4uGHG0HQ1sEZk9Uuao3pI6gKb3ms=';
    // String myIV = 'bPmSgVkYp4s6v9t$';

    remitSQL_REST_API_settings__mdt remitSetting = remitSettings[0];
    String myKey = String.valueOf(remitSetting.Encryption_Key__c);
    System.Debug('myKey:  ' + myKey);
    System.Debug('inputString:  ' + inputString);
    System.Debug('myIV:  ' + myIV);
    
    Blob myEncryptionKey = EncodingUtil.base64Decode(myKey);
    
    Blob initVector = Blob.valueOf(myIV); 

    Blob myEncryptedInfo = EncodingUtil.base64Decode(inputString);


    System.Debug('myEncryptionKey:  ' + myEncryptionKey);
    System.Debug('initVector:  ' + initVector);
    System.Debug('myEncryptedInfo:  ' + myEncryptedInfo);

    // Decrypting the above encrypted data
    Blob decryptedData = Crypto.decrypt('AES256', myEncryptionKey, initVector, myEncryptedInfo);
    System.debug('Decrypted Data is: ' + decryptedData.toString());

    return decryptedData.toString();
  }

  private static String myEncrypter(String inputString){

    // Testing Settings
    // String inputString = '123';
    Blob initVector = Blob.valueOf('bPmSgVkYp4s6v9t$'); // Random 16-bit Init Vector
    Blob encryptionKey = crypto.generateAesKey(256);
    // System.debug('Generated Key: ' + EncodingUtil.base64Encode(encryptionKey));
    // System.debug('inputString:  ' + inputString);
    // System.debug('initVector:  ' + initVector);
    
    List<remitSQL_REST_API_settings__mdt> remitSettings = [SELECT encryption_key__c FROM remitSQL_REST_API_settings__mdt LIMIT 1];

    Blob myEncryptionKey = EncodingUtil.base64Decode(String.valueOf(remitSettings[0].encryption_key__c));

    // Data to encrypt is converted to Blob
    Blob data = Blob.valueOf(inputString);


    System.debug('data:  ' + data);
    System.debug('myEncryptionKey:  ' + myEncryptionKey);

    // Encrypt the dat using AES256 encryption rule
    Blob encryptedData = Crypto.encrypt('AES256', myEncryptionKey, initVector, data);
    System.debug('Encrypted Data is: ' + EncodingUtil.base64Encode(encryptedData));

    return encryptedData.toString();
  }


  /**
   * Get Picklist Values
   * Get the active values from a picklist
   * @param activefield   the picklist to retreive values from
   * @return              Return a list of the active values
   * 
   * source/credit: https://www.phoneiq.co/blog/how-to-check-picklist-values-with-apex-in-salesforce
   */
  private static List<String> getPicklistValues(sObjectField field){

    Schema.DescribeFieldResult fieldMetadata = field.getDescribe();
    List<Schema.PicklistEntry> picklistEntries = fieldMetadata.getPicklistValues();

    List<String> returnValues = new List<String>();
    for(Schema.PicklistEntry picklistEntry : picklistEntries) {
      returnValues.add(picklistEntry.getValue());
    }
    return returnValues;
  }


  global class Inputs {
    // Transaction Info
    public String anonymous;
    public String bankAccountNumber;
    public String bankRoutingNumber;
    public String batchId;
    public String billingName;
    public String cardExpirationMonth;
    public String cardExpirationYear;
    public String cardNumber;
    public String campaignId;
    public String chargeAmount;
    public String chargeDate;
    public String cvc;
    public String exceptionBatchFlags;
    public String fundId;
    public String furtherAttentionNotes;
    public String giftChannel;
    public String giftReference;
    public String noReceipt;
    public String appealId;
    public String packageId;
    public String appealTMSid;
    public String packageTMSid;
    public String parentOpportunity;
    public String paymentMethod;
    public String recurringDonation;
    public String TMScity;
    public String type;
    public String contactId;
    public String accountId;

    public String tributeType;
    public String tributeDescription;
    public String honoreeName;
    public String honoreeContactId;
    public String benefitValue;
    
    public String inKindType;
    public String inKindSubtype;
    public String inKindDeclaredValue;
    public String inKindVerifiedValue;
    public String inKindDescription;
    public String inKindValuationNote;

    public String scannedImage;
    public String checkImage;
    public String slipImage;    

    public String tmsTransactInfo;
    
    public String ToJSONString() {
        return '{\n' +
            '\"anonymous\": \"' + anonymous + '\",\n' +
            '\"bankAccountNumber\": \"' + bankAccountNumber + '\",\n' +
            '\"bankRoutingNumber\": \"' + bankRoutingNumber + '\",\n' +
            '\"batchId\": \"' + batchId + '\",\n' +
            '\"billingName\": \"' + billingName + '\",\n' +
            '\"cardExpirationMonth\": \"' + cardExpirationMonth + '\",\n' +
            '\"cardExpirationYear\": \"' + cardExpirationYear + '\",\n' +
            '\"cardNumber\": \"' + cardNumber + '\",\n' +
            '\"campaignId\": \"' + campaignId + '\",\n' +
            '\"chargeAmount\": \"' + chargeAmount + '\",\n' +
            '\"chargeDate\": \"' + chargeDate + '\",\n' +
            '\"cvc\": \"' + cvc + '\",\n' +
            '\"exceptionBatchFlags\": \"' + exceptionBatchFlags + '\",\n' +
            '\"fundId\": \"' + fundId + '\",\n' +
            '\"furtherAttentionNotes\": \"' + furtherAttentionNotes + '\",\n' +
            '\"giftChannel\": \"' + giftChannel + '\",\n' +
            '\"giftReference\": \"' + giftReference + '\",\n' +
            '\"noReceipt\": \"' + noReceipt + '\",\n' +
            '\"appealId\": \"' + appealId + '\",\n' +
            '\"packageId\": \"' + packageId + '\",\n' +
            '\"appealTMSid\": \"' + appealTMSid + '\",\n' +
            '\"packageTMSid\": \"' + packageTMSid + '\",\n' +
            '\"parentOpportunity\": \"' + parentOpportunity + '\",\n' +
            '\"paymentMethod\": \"' + paymentMethod + '\",\n' +
            '\"recurringDonation\": \"' + recurringDonation + '\",\n' +
            '\"TMScity\": \"' + TMScity + '\",\n' +
            '\"type\": \"' + type + '\",\n' +
            '\"contactId\": \"' + contactId + '\",\n' +
            '\"accountId\": \"' + accountId + '\",\n' +
            '\"tributeType\": \"' + tributeType + '\",\n' +
            '\"tributeDescription\": \"' + tributeDescription + '\",\n' +
            '\"honoreeName\": \"' + honoreeName + '\",\n' +
            '\"honoreeContactId\": \"' + honoreeContactId + '\",\n' +
            '\"benefitValue\": \"' + benefitValue + '\",\n' +
            '\"inKindType\": \"' + inKindType + '\",\n' +
            '\"inKindSubtype\": \"' + inKindSubtype + '\",\n' +
            '\"inKindDeclaredValue\": \"' + inKindDeclaredValue + '\",\n' +
            '\"inKindVerifiedValue\": \"' + inKindVerifiedValue + '\",\n' +
            '\"inKindDescription\": \"' + inKindDescription + '\",\n' +
            '\"inKindValuationNote\": \"' + inKindValuationNote + '\",\n' +
            '\"tmsTransactInfo\": \"' + tmsTransactInfo + '\"\n' +
            '}';
    }
  }

  private class TypedInputs{
    public Boolean anonymous;
    public String bankAccountNumber;
    public String bankRoutingNumber;
    public Id batchId;
    public String billingName;
    public String cardExpirationMonth;
    public String cardExpirationYear;
    public String cardNumber;
    // public Id campaignId;
    public Decimal chargeAmount;
    public Date chargeDate;
    public String cvc;
    public String exceptionBatchFlags;
    public Id fundId;
    public String furtherAttentionNotes;
    public String giftChannel;
    public String giftReference;
    public Boolean noReceipt;
    public Id appealId;
    public Id packageId;
    public String appealTMSid;
    public String packageTMSid;
    public Id parentOpportunity;
    public String paymentMethod;
    public Boolean recurringDonation;
    public String tmsCity;
    public String type;

    public Id contactId;
    public Id accountId;
    public String tributeType;
    public String tributeDescription;
    public String honoreeName;
    public Id honoreeContactId;
    public Decimal benefitValue;
    
    public String inKindType;
    public String inKindSubtype;
    public Boolean inKindDeclaredValue;
    public Boolean inKindVerifiedValue;
    public String inKindDescription;
    public String inKindValuationNote;

    public String scannedImage;
    public String checkImage;
    public String slipImage;

    public String tmsTransactInfo;

    public String completeMessage;
    public String resultMessage;
  }

  global class Result {
    public String TransactionResult;
    public String Errormsg;
    public String donationId;

    public Result(String myResult, String myMessage, Id myOpportunityId){
      TransactionResult = myResult;
      Errormsg = myMessage;
      donationId = myOpportunityId;
    }
  }
}