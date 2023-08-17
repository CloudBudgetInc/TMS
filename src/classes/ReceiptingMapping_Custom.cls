global with sharing class ReceiptingMapping_Custom extends kell6_core.Configuration implements kell6_core.Configuration.IConfiguration, kell6_core.Configuration.IConfiguration2 {

    private static final ReceiptableObject OPPORTUNITY = new ReceiptableObject(
        'Opportunity',                                                                     // objectName 
        'Opportunity',                                                                     // objectLabel 
        new Field('kell6_core__Opportunity__c'),                                           // receiptField 
        new Field('kell6_core__Opportunity__r.kell6_core__Receipt_Contact__c'),            // contactField 
        new Field('kell6_core__Opportunity__r.kell6_core__Receipt_Contact__r.AccountId'),  // accountField 
        new Field('kell6_core__Opportunity__r.CampaignId'),                                // campaignField 
        new List<Field>{new Field('kell6_core__Opportunity__r.CnP_PaaS__C_P_Recurring__c'), new Field('kell6_core__Opportunity__r.CnP_PaaS__CnP_OrderNumber__c')}, // recurringDonationFields 
        new Field('kell6_core__Opportunity__r.CloseDate'),                                 // closeDateField 
        new Field('kell6_core__Opportunity__r.Type'),                                      // typeField 
        new Field('kell6_core__Opportunity__r.kell6_core__Legacy_Receipt_Number__c'),      // legacyReceiptField 
        new Field('kell6_core__Opportunity__r.Amount'),                                    // receiptableAmountField
        new Field('kell6_core__Opportunity__r.kell6_core__Benefit_Value__c'),              // benefitValueField
        new Field('kell6_core__Opportunity__r.kell6_core__Ready_To_Print_Single__c'),      // readyToPrintField
        new Field('kell6_core__Opportunity__r.kell6_core__No_Receipt__c'),                 // noReceiptField
        new Field('kell6_core__Opportunity__r.kell6_core__Receipted__c'),                  // receiptedField
        new Field('kell6_core__Opportunity__r.kell6_core__Receipt_Date__c'),               // receiptDateField
        new Field('kell6_core__Opportunity__r.kell6_core__Receipt_Acknowledgement__c'),    // receiptAcknowledgementField 
        null,                                                                              // installmentObjectName 
        null,                                                                              // installmentRelationshipName 
        null,                                                                                // installmentConditions 
        'kell6_core__Receipts__r',                                                         // receiptRelationshipName 
        new List<Mapping>{
            new Mapping('kell6_core__Donation_Date__c'          , 'kell6_core__Opportunity__r.CloseDate'),
            new Mapping('kell6_core__Receipted_Amount__c'       , 'kell6_core__Opportunity__r.Amount'),
            new Mapping('kell6_core__Benefit_Value__c'          , 'kell6_core__Opportunity__r.kell6_core__Benefit_Value__c'),
            new Mapping('Gift_in_Kind_Description__c'          , 'kell6_core__Opportunity__r.npsp__In_Kind_Description__c'),
            new Mapping('kell6_core__Tax_Deductible_Amount__c'  , 'kell6_core__Opportunity__r.kell6_core__Receiptable_Amount__c', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.In_Kind_Verified_Value__c', 'true', true)}),
            new Mapping('kell6_core__Tax_Deductible_Amount__c'  , 'kell6_core__Opportunity__r.kell6_core__Receiptable_Amount__c', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.Type', 'Cash', true)}),
            new Mapping('kell6_core__Tax_Deductible_Amount__c'  , 'kell6_core__Opportunity__r.kell6_core__Receiptable_Amount__c', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.Type', 'Recurring Gift', true)}),
            new Mapping('kell6_core__Tax_Deductible_Amount__c'  , 'kell6_core__Opportunity__r.kell6_core__Receiptable_Amount__c', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.Type', 'Stock/Property', true)}),
            new Mapping('kell6_core__Tax_Deductible_Amount__c'  , 'kell6_core__Opportunity__r.kell6_core__Receiptable_Amount__c', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.Type', 'Payroll', true)}),
            new Mapping('kell6_core__Tax_Deductible_Amount__c'  , 'kell6_core__Opportunity__r.kell6_core__Receiptable_Amount__c', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.Type', 'Other Revenue', true)}),
            
            new Mapping('kell6_core__Campaign_Name__c'          , 'kell6_core__Opportunity__r.Campaign.Name'),
            new Mapping('kell6_core__Appraiser_Details__c'      , 'kell6_core__Opportunity__r.kell6_core__Appraiser_Details__c'),
            new Mapping('kell6_core__Description__c'            , 'kell6_core__Opportunity__r.kell6_core__Tax_Receipt_Description__c'),
            new Mapping('kell6_core__Donor_s_Household_Name__c' , 'kell6_core__Opportunity__r.Account.Name'),
            new Mapping('kell6_core__Receipt_Contact__c'		, 'kell6_core__Opportunity__r.kell6_core__Receipt_Contact__c'),
            new Mapping('kell6_core__Billing_Address__c'         , 'kell6_core__Opportunity__r.Account.BillingStreet'),
            new Mapping('kell6_core__Billing_City__c'           , 'kell6_core__Opportunity__r.Account.BillingCity'),
            new Mapping('kell6_core__Billing_State__c'          , 'kell6_core__Opportunity__r.Account.BillingState'),
            new Mapping('kell6_core__Billing_Postal_Code__c'    , 'kell6_core__Opportunity__r.Account.BillingPostalCode'),
            new Mapping('kell6_core__Billing_Country__c'        , 'kell6_core__Opportunity__r.Account.BillingCountry'),
           // new Mapping('kell6_core__Donor_s_Household_Name__c' , 'kell6_core__Opportunity__r.Campaign.Name'),
//  ****** Name for Letter                
            new Mapping('Preferred_Greeting__c'                 , 'kell6_core__Opportunity__r.kell6_core__Receipt_Contact__r.Preferred_Greeting__c'),
//          new Mapping('Preferred_Greeting__c' 				, 'kell6_core__Opportunity__r.kell6_core__Receipt_Contact__r.Name', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_core__Opportunity__r.Account.RecordTypeId', false)}),
//          new Mapping('Preferred_Greeting__c' 				, 'kell6_core__Opportunity__r.kell6_core__Receipt_Contact__r.Account.Name', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_core__Opportunity__r.Account.RecordTypeId', false)}),
//  ****** Name for Receipt        
            new Mapping('kell6_core__Donor_s_Name__c'           , 'kell6_core__Opportunity__r.kell6_core__Receipt_Contact__r.Name'),
            new Mapping('kell6_core__Donor_s_Name__c' 			, 'kell6_core__Opportunity__r.kell6_core__Receipt_Contact__r.Account.Name', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_core__Opportunity__r.Account.RecordTypeId', false)}),
//          new Mapping('kell6_core__Donor_s_Name__c'      		, 'kell6_core__Opportunity__r.kell6_core__Receipt_Contact__r.Account.Name', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.Account.RecordTypeId', '01236000000fv3pAAA', true)}),
            new Mapping('kell6_core__Donor_s_Household_Name__c' , 'kell6_core__Opportunity__r.kell6_core__Receipt_Contact__r.Account.Name', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_core__Opportunity__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Billing_Address__c'         , 'kell6_core__Opportunity__r.kell6_core__Receipt_Contact__r.MailingStreet', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_core__Opportunity__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Billing_City__c'           , 'kell6_core__Opportunity__r.kell6_core__Receipt_Contact__r.MailingCity', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_core__Opportunity__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Billing_State__c'          , 'kell6_core__Opportunity__r.kell6_core__Receipt_Contact__r.MailingState', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_core__Opportunity__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Billing_Postal_Code__c'    , 'kell6_core__Opportunity__r.kell6_core__Receipt_Contact__r.MailingPostalCode', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_core__Opportunity__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Billing_Country__c'        , 'kell6_core__Opportunity__r.kell6_core__Receipt_Contact__r.MailingCountry', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_core__Opportunity__r.Account.RecordTypeId', true)}),
            new Mapping('Text_for_Receipt__c'            		, 'kell6_core__Opportunity__r.Campaign.Text_for_Receipt_Calgary__c'),
            new Mapping('Text_for_Receipt__c'            		, 'kell6_core__Opportunity__r.Campaign.Text_for_Receipt_Edmonton__c', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.TMS_City__c', 'Edmonton', true)}),
            new Mapping('Text_for_Receipt__c'            		, 'kell6_core__Opportunity__r.Campaign.Text_for_Receipt_Red_Deer__c', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.TMS_City__c', 'Red Deer', true)}),
            new Mapping('Text_for_Receipt__c'            		, 'kell6_core__Opportunity__r.Campaign.Text_for_Receipt_Kamloops__c', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.TMS_City__c', 'Kamloops', true)}),
            new Mapping('Text_for_Receipt__c'            		, 'kell6_core__Opportunity__r.Campaign.Text_for_Receipt_Medicine_Hat__c', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.TMS_City__c', 'Medicine Hat', true)}),
            new Mapping('Text_for_Letter__c'            		, 'kell6_core__Opportunity__r.Campaign.Text_for_Letter_Calgary__c'),
            new Mapping('Text_for_Letter__c'            		, 'kell6_core__Opportunity__r.Campaign.Text_for_Letter_Edmonton__c', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.TMS_City__c', 'Edmonton', true)}),
            new Mapping('Text_for_Letter__c'            		, 'kell6_core__Opportunity__r.Campaign.Text_for_Letter_Red_Deer__c', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.TMS_City__c', 'Red Deer', true)}),
            new Mapping('Text_for_Letter__c'            		, 'kell6_core__Opportunity__r.Campaign.Text_for_Letter_Kamloops__c', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.TMS_City__c', 'Kamloops', true)}),
            new Mapping('Text_for_Letter__c'            		, 'kell6_core__Opportunity__r.Campaign.Text_for_Letter_Medicine_Hat__c', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__r.TMS_City__c', 'Medicine Hat', true)}),
            new Mapping('Service_Code__c'                       , 'kell6_core__Opportunity__r.Service_Code__c'),
            new Mapping('Donations_List__c'                     , 'kell6_core__Opportunity__r.Name'),
            new Mapping('Gift_City__c'                     , 'kell6_core__Opportunity__r.TMS_City__c'),
            new Mapping('Use_Email_Template__c'                 , 'kell6_core__Opportunity__r.Email_Receipt__c'),
            new Mapping('Gift_Batch__c'             		    , 'kell6_core__Opportunity__r.npsp__Batch__c'),  
            new Mapping('Batch_Date__c'                 		, 'kell6_core__Opportunity__r.npsp__Batch__r.Date__c')
        },
        new List<UnchangeableField>{
            new UnchangeableField('RecordTypeId'),
            new UnchangeableField('AccountId'),
            new UnchangeableField('kell6_core__Receipt_Contact__c', null),
            new UnchangeableField('CloseDate'),
            new UnchangeableField('StageName'),
            new UnchangeableField('IsClosed', false),
            new UnchangeableField('IsWon', false),
            new UnchangeableField('Amount'),
            new UnchangeableField('kell6_core__Benefit_Value__c')
        }
    );
  
    private static final ReceiptableObject CP_RECURRING = new ReceiptableObject(
        'CnP_PaaS__CnPRecurring__c',                                                     // objectName 
        'C&P Recurring',                                                                 // objectLabel 
        new Field('kell6_cp__Recurring__c'),                                             // receiptField 
        new Field('kell6_cp__Recurring__r.CnP_PaaS__Contact__c'),                        // contactField
        new Field('kell6_cp__Recurring__r.CnP_PaaS__Account__c'),                        // accountField 
        new Field(''),                                                                   // campaignField 
        new List<Field>(),                                                               // recurringDonationFields 
        new Field('kell6_cp__Recurring__r.CnP_PaaS__Date_Established__c'),               // closeDateField 
        new Field('kell6_cp__Recurring__r.CnP_PaaS__Periodicity__c'),                    // typeField 
        new Field('kell6_cp__Recurring__r.kell6_cp__Legacy_Receipt_Number__c'),          // legacyReceiptField 
        new Field('kell6_cp__Recurring__r.CnP_PaaS__Total__c'),                          // receiptableAmountField
        new Field(''),                                                                   // benefitValueField
        new Field('kell6_cp__Recurring__r.kell6_cp__Ready_To_Print__c'),                 // readyToPrintField
        new Field('kell6_cp__Recurring__r.kell6_cp__No_Receipt__c'),                     // noReceiptField
        new Field('kell6_cp__Recurring__r.kell6_cp__Receipted__c'),                      // receiptedField
        new Field('kell6_cp__Recurring__r.kell6_cp__Receipt_Date__c'),                   // receiptDateField
        new Field('kell6_cp__Recurring__r.kell6_cp__Receipt_Acknowledgement__c'),        // receiptAcknowledgementField 
        'Opportunity',                                                    // installmentObjectName 
        'CnP_PaaS__Opportunities__r',                                                    // installmentRelationshipName 
        ' WHERE CloseDate >= :receiptablePeriodStart AND CloseDate < :receiptablePeriodEnd AND IsClosed = true AND IsWon = true AND Amount >= :minimumReceiptableAmount AND (NOT RecordTypeId IN :excludedRecordTypes) AND (NOT Type IN :excludedTypes) ORDER BY CloseDate ASC', // installmentConditions 
//         ' WHERE CloseDate >= :receiptablePeriodStart AND CloseDate < :receiptablePeriodEnd AND IsClosed = true AND IsWon = true AND Amount >= :minimumReceiptableAmount AND kell6_core__Receipted__c != :receiptedValue AND (NOT RecordTypeId IN :excludedRecordTypes) AND (NOT Type IN :excludedTypes) ORDER BY CloseDate ASC', // installmentConditions 
       'kell6_cp__Receipts__r',                                                         // receiptRelationshipName  
        new List<Mapping>{
            new Mapping('kell6_core__Appraiser_Details__c'             , 'kell6_cp__Recurring__r.kell6_cp__Appraiser_Details__c'),
            new Mapping('kell6_core__Description__c'                   , 'kell6_cp__Recurring__r.kell6_cp__Tax_Receipt_Description__c'),
            new Mapping('kell6_core__Donor_s_Name__c'                  , 'kell6_cp__Recurring__r.CnP_PaaS__Account__r.Name'),
            new Mapping('kell6_core__Donor_s_Household_Name__c'        , 'kell6_cp__Recurring__r.CnP_PaaS__Account__r.Name'),
            new Mapping('kell6_core__Donor_s_Email__c'                 , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Email'),
            new Mapping('kell6_core__Billing_Address__c'               , 'kell6_cp__Recurring__r.CnP_PaaS__Account__r.BillingStreet'),
            new Mapping('kell6_core__Billing_City__c'                  , 'kell6_cp__Recurring__r.CnP_PaaS__Account__r.BillingCity'),
            new Mapping('kell6_core__Billing_State__c'                 , 'kell6_cp__Recurring__r.CnP_PaaS__Account__r.BillingState'),
            new Mapping('kell6_core__Billing_Postal_Code__c'           , 'kell6_cp__Recurring__r.CnP_PaaS__Account__r.BillingPostalCode'),
            new Mapping('kell6_core__Billing_Country__c'               , 'kell6_cp__Recurring__r.CnP_PaaS__Account__r.BillingCountry'),
            new Mapping('kell6_core__Donor_s_Name__c'                  , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.Name', new List<MappingCondition>{new FieldCondition('kell6_cp__Recurring__r.CnP_PaaS__Account__c', '', true)}),
            new Mapping('kell6_core__Donor_s_Household_Name__c'        , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.Name', new List<MappingCondition>{new FieldCondition('kell6_cp__Recurring__r.CnP_PaaS__Account__c', '', true)}),
            new Mapping('kell6_core__Billing_Address__c'               , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.BillingStreet', new List<MappingCondition>{new FieldCondition('kell6_cp__Recurring__r.CnP_PaaS__Account__c', '', true)}),
            new Mapping('kell6_core__Billing_City__c'                  , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.BillingCity', new List<MappingCondition>{new FieldCondition('kell6_cp__Recurring__r.CnP_PaaS__Account__c', '', true)}),
            new Mapping('kell6_core__Billing_State__c'                 , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.BillingState', new List<MappingCondition>{new FieldCondition('kell6_cp__Recurring__r.CnP_PaaS__Account__c', '', true)}),
            new Mapping('kell6_core__Billing_Postal_Code__c'           , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.BillingPostalCode', new List<MappingCondition>{new FieldCondition('kell6_cp__Recurring__r.CnP_PaaS__Account__c', '', true)}),
            new Mapping('kell6_core__Billing_Country__c'               , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.BillingCountry', new List<MappingCondition>{new FieldCondition('kell6_cp__Recurring__r.CnP_PaaS__Account__c', '', true)}),
            new Mapping('kell6_core__Donor_s_Name__c'                  , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Name', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_cp__Recurring__r.CnP_PaaS__Account__r.RecordTypeId', true), new AccountRecordTypeCheck('kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Donor_s_Household_Name__c'        , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.Name', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_cp__Recurring__r.CnP_PaaS__Account__r.RecordTypeId', true), new AccountRecordTypeCheck('kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Receipt_Contact__c'			   , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__c'),
            new Mapping('kell6_core__Billing_Street__c'                , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.MailingStreet', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_cp__Recurring__r.CnP_PaaS__Account__r.RecordTypeId', true), new AccountRecordTypeCheck('kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Billing_City__c'                  , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.MailingCity', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_cp__Recurring__r.CnP_PaaS__Account__r.RecordTypeId', true), new AccountRecordTypeCheck('kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Billing_State__c'                 , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.MailingState', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_cp__Recurring__r.CnP_PaaS__Account__r.RecordTypeId', true), new AccountRecordTypeCheck('kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Billing_Postal_Code__c'           , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.MailingPostalCode', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_cp__Recurring__r.CnP_PaaS__Account__r.RecordTypeId', true), new AccountRecordTypeCheck('kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Billing_Country__c'               , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.MailingCountry', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_cp__Recurring__r.CnP_PaaS__Account__r.RecordTypeId', true), new AccountRecordTypeCheck('kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Account.RecordTypeId', true)}),
            new Mapping('Preferred_Greeting__c'                        , 'kell6_cp__Recurring__r.CnP_PaaS__Contact__r.Preferred_Greeting__c'),
            new Mapping('Donations_List__c'                            , 'kell6_cp__Recurring__r.Donations_List__c'),
            new Mapping('Gift_City__c'                            	   , 'kell6_cp__Recurring__r.TMS_City__c'),
            new Mapping('Use_Email_Template__c'              		   , 'kell6_cp__Recurring__r.Email_Receipt__c')
        },
        new List<UnchangeableField>{
        }
    );
    
    private static final ReceiptableObject CP_TRANSACTION = new ReceiptableObject(
        'CnP_PaaS__CnP_Transaction__c',                                                  // objectName 
        'C&P Transaction',                                                               // objectLabel 
        new Field('kell6_cp__Transaction__c'),                                           // receiptField 
        new Field('kell6_cp__Transaction__r.CnP_PaaS__Contact__c'),                      // contactField
        new Field('kell6_cp__Transaction__r.CnP_PaaS__Account__c'),                      // accountField 
        new Field('kell6_cp__Transaction__r.CnP_PaaS__sf_Campaign__c'),                  // campaignField 
        new List<Field>(),                                                               // recurringDonationFields 
        new Field('kell6_cp__Transaction__r.CnP_PaaS__TransactionDate__c'),              // closeDateField 
        new Field('kell6_cp__Transaction__r.CnP_PaaS__Transaction_Type__c'),             // typeField 
        new Field('kell6_cp__Transaction__r.kell6_cp__Legacy_Receipt_Number__c'),        // legacyReceiptField 
        new Field('kell6_cp__Transaction__r.CnP_PaaS__Amount__c'),                       // receiptableAmountField
        new Field('kell6_cp__Transaction__r.CnP_PaaS__Deductible_Charge__c'),            // benefitValueField
        new Field('kell6_cp__Transaction__r.kell6_cp__Ready_To_Print__c'),               // readyToPrintField
        new Field('kell6_cp__Transaction__r.kell6_cp__No_Receipt__c'),                   // noReceiptField
        new Field('kell6_cp__Transaction__r.kell6_cp__Receipted__c'),                    // receiptedField
        new Field('kell6_cp__Transaction__r.kell6_cp__Receipt_Date__c'),                 // receiptDateField
        new Field('kell6_cp__Transaction__r.kell6_cp__Receipt_Acknowledgement__c'),      // receiptAcknowledgementField 
        'Opportunity',                                                                   // installmentObjectName 
        'CnP_PaaS__Opportunities__r',                                                    // installmentRelationshipName 
        ' WHERE IsClosed = true AND IsWon = true AND Amount >= :minimumReceiptableAmount AND kell6_core__Receipted__c != :receiptedValue AND (NOT RecordTypeId IN :excludedRecordTypes) AND (NOT Type IN :excludedTypes) ORDER BY CloseDate ASC', // installmentConditions 
        'kell6_cp__Receipts__r',                                                         // receiptRelationshipName  
        new List<Mapping>{
            new Mapping('kell6_core__Donation_Date__c'                 , 'kell6_cp__Transaction__r.kell6_cp__Transaction_Date__c'),
            new Mapping('kell6_core__Receipted_Amount__c'              , 'kell6_cp__Transaction__r.CnP_PaaS__Amount__c'),
            new Mapping('kell6_core__Benefit_Value__c'                 , 'kell6_cp__Transaction__r.CnP_PaaS__Deductible_Charge__c'),
            new Mapping('kell6_core__Tax_Deductible_Amount__c'         , 'kell6_cp__Transaction__r.CnP_PaaS__Amount__c'),
            new Mapping('kell6_core__Campaign_Name__c'                 , 'kell6_cp__Transaction__r.CnP_PaaS__sf_Campaign__r.Name'),
            new Mapping('kell6_core__Appraiser_Details__c'             , 'kell6_cp__Transaction__r.kell6_cp__Appraiser_Details__c'),
            new Mapping('kell6_core__Description__c'                   , 'kell6_cp__Transaction__r.kell6_cp__Tax_Receipt_Description__c'),
            new Mapping('kell6_core__Donor_s_Name__c'                  , 'kell6_cp__Transaction__r.CnP_PaaS__Account__r.Name'),
            new Mapping('kell6_core__Donor_s_Household_Name__c'        , 'kell6_cp__Transaction__r.CnP_PaaS__Account__r.Name'),
            new Mapping('kell6_core__Receipt_Contact__c'               , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__c'),
            new Mapping('kell6_core__Billing_Address__c'               , 'kell6_cp__Transaction__r.CnP_PaaS__Account__r.BillingStreet'),
            new Mapping('kell6_core__Billing_City__c'                  , 'kell6_cp__Transaction__r.CnP_PaaS__Account__r.BillingCity'),
            new Mapping('kell6_core__Billing_State__c'                 , 'kell6_cp__Transaction__r.CnP_PaaS__Account__r.BillingState'),
            new Mapping('kell6_core__Billing_Postal_Code__c'           , 'kell6_cp__Transaction__r.CnP_PaaS__Account__r.BillingPostalCode'),
            new Mapping('kell6_core__Billing_Country__c'               , 'kell6_cp__Transaction__r.CnP_PaaS__Account__r.BillingCountry'),
            new Mapping('kell6_core__Donor_s_Name__c'                  , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.Name', new List<MappingCondition>{new FieldCondition('kell6_cp__Transaction__r.CnP_PaaS__Account__c', '', true)}),
            new Mapping('kell6_core__Donor_s_Household_Name__c'        , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.Name', new List<MappingCondition>{new FieldCondition('kell6_cp__Transaction__r.CnP_PaaS__Account__c', '', true)}),
            new Mapping('kell6_core__Billing_Address__c'               , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.BillingStreet', new List<MappingCondition>{new FieldCondition('kell6_cp__Transaction__r.CnP_PaaS__Account__c', '', true)}),
            new Mapping('kell6_core__Billing_City__c'                  , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.BillingCity', new List<MappingCondition>{new FieldCondition('kell6_cp__Transaction__r.CnP_PaaS__Account__c', '', true)}),
            new Mapping('kell6_core__Billing_State__c'                 , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.BillingState', new List<MappingCondition>{new FieldCondition('kell6_cp__Transaction__r.CnP_PaaS__Account__c', '', true)}),
            new Mapping('kell6_core__Billing_Postal_Code__c'           , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.BillingPostalCode', new List<MappingCondition>{new FieldCondition('kell6_cp__Transaction__r.CnP_PaaS__Account__c', '', true)}),
            new Mapping('kell6_core__Billing_Country__c'               , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.BillingCountry', new List<MappingCondition>{new FieldCondition('kell6_cp__Transaction__r.CnP_PaaS__Account__c', '', true)}),
            new Mapping('kell6_core__Donor_s_Name__c'                  , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Name', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_cp__Transaction__r.CnP_PaaS__Account__r.RecordTypeId', true), new AccountRecordTypeCheck('kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Donor_s_Household_Name__c'        , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.Name', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_cp__Transaction__r.CnP_PaaS__Account__r.RecordTypeId', true), new AccountRecordTypeCheck('kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Billing_Street__c'                , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.MailingStreet', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_cp__Transaction__r.CnP_PaaS__Account__r.RecordTypeId', true), new AccountRecordTypeCheck('kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Billing_City__c'                  , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.MailingCity', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_cp__Transaction__r.CnP_PaaS__Account__r.RecordTypeId', true), new AccountRecordTypeCheck('kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Billing_State__c'                 , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.MailingState', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_cp__Transaction__r.CnP_PaaS__Account__r.RecordTypeId', true), new AccountRecordTypeCheck('kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Billing_Postal_Code__c'           , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.MailingPostalCode', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_cp__Transaction__r.CnP_PaaS__Account__r.RecordTypeId', true), new AccountRecordTypeCheck('kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.RecordTypeId', true)}),
            new Mapping('kell6_core__Billing_Country__c'               , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.MailingCountry', new List<MappingCondition>{new AccountRecordTypeCheck('kell6_cp__Transaction__r.CnP_PaaS__Account__r.RecordTypeId', true), new AccountRecordTypeCheck('kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Account.RecordTypeId', true)}),
            new Mapping('Preferred_Greeting__c'                        , 'kell6_cp__Transaction__r.CnP_PaaS__Contact__r.Preferred_Greeting__c')
        },
        new List<UnchangeableField>{
        }
    );

    global Map<String, ReceiptableObject> getObjects() {
        return new Map<String, ReceiptableObject>{'Opportunity' => OPPORTUNITY, 'CnP_PaaS__CnPRecurring__c' => CP_RECURRING, 'CnP_PaaS__CnP_Transaction__c' => CP_TRANSACTION};
    }
    
    global Map<String, ReceiptableObject> getSingleReceiptableObjects() {
        return new Map<String, ReceiptableObject>{'Opportunity' => OPPORTUNITY};
    }
    
    global Map<String, ReceiptableObject> getRecurringReceiptableObjects() {
        return new Map<String, ReceiptableObject>{'CnP_PaaS__CnPRecurring__c' => CP_RECURRING};
    }
    
    global Map<String, ReceiptableObject> getEventReceiptableObjects() {
        return new Map<String, ReceiptableObject>{'Opportunity' => OPPORTUNITY, 'CnP_PaaS__CnP_Transaction__c' => CP_TRANSACTION};
    }
    
    global Map<String, String> getAccompanyingLetterPlaceholders() {
        return new Map<String, String>{
            '[[CONTACT_NAME]]'          => 'kell6_core__Donor_s_Name__c',
            '[[CAMPAIGN_NAME]]'         => 'kell6_core__Campaign_Name__c',
            '[[TAX_DEDUCTIBLE_AMOUNT]]' => 'kell6_core__Tax_Deductible_Amount__c',
            '[[BENEFIT_VALUE]]'         => 'kell6_core__Benefit_Value__c',
            '[[DONATION_DATE]]'         => 'kell6_core__Donation_Date__c',
            '[[DESCRIPTION]]'           => 'kell6_core__Description__c',
            '[[GIK_DESCRIPTION]]'       => 'Gift_in_Kind_Description__c',
            '[[APPRAISER_DETAILS]]'     => 'kell6_core__Appraiser_Details__c',
            '[[LETTER]]'       			=> 'Text_for_Letter__c',
            '[[RECEIPT]]'       		=> 'Text_for_Receipt__c',
            '[[SERVICE_CODE]]'          => 'Service_Code__c',
            '[[PREFERRED_GREETING]]'    => 'Preferred_Greeting__c',
            '[[DONATIONS_LIST]]'        => 'Donations_List__c',
            '[[RECEIPT_YEAR]]'          => 'kell6_core__Receipted_Year__c',
            '[[EMAIL_TEMPLATE]]'        => 'Use_Email_Template__c'
        };
    }
    
    global List<Mapping> getAccompanyingLetterInstallmentPlaceholders() {
        return new List<Mapping>{
            new Mapping('Amount', 'kell6_core__Opportunity__r.Amount', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__c', '', true, true)}),
            new Mapping('Close Date', 'kell6_core__Opportunity__r.CloseDate', new List<MappingCondition>{new FieldCondition('kell6_core__Opportunity__c', '', true, true)})
        };
    }
}