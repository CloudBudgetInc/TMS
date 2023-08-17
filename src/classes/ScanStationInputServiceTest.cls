@isTest
public with sharing class ScanStationInputServiceTest {

    @isTest(SeeAllData=True)
    static void testSaveImage() {
        Contact c = TestDataFactory.createContact();
        
        // Contact c = new Contact();
        // c.FirstName = 'k';
        // c.LastName = 'l';
        // insert c;

        Test.startTest();
        ScanStationInputService.saveImage('imageString', c.Id, 'scanned');
        Test.stopTest();

        List<ContentDocumentLink> cv = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :c.Id LIMIT 1];
        System.debug('cv size:  ' + cv.size() + ' cv:  ' + cv);
        System.assert(cv.size() > 0, 'didn\'t find any files');
    }

    // @isTest(SeeAllData=True)
    @isTest
    static void testPostPostmanCreditCard() {
        
        Contact con = TestDataFactory.createContact();
        // Contact con = [SELECT Id, Contact_ID__c, Account__r.Account_ID__c FROM Contact WHERE firstName='Test' LIMIT 1];

        Campaign cam = TestDataFactory.createCampaign('test1');
        ChargentBase__Gateway__c g = TestDataFactory.createGateway('g1');

        // setup test call
        ScanStationInputService.Inputs testInputs = new ScanStationInputService.Inputs();

        testInputs.accountId = con.Account.Account_ID__c;
        testInputs.anonymous = 'N';
        testInputs.bankAccountNumber = '';
        testInputs.bankRoutingNumber = '';
        testInputs.batchId = '';
        testInputs.billingName = '';
        testInputs.cardExpirationMonth = 'vFmZZKUuf99UA+0bUJ2GxA==';
        testInputs.cardExpirationYear = 'DYRYSmoxRCPqdp8aPL+39Q=='; 
        testInputs.cardNumber = 'Ljz9iMNGIPU3Xwg4uGHG0HQ1sEZk9Uuao3pI6gKb3ms'; 
        testInputs.campaignId = '';
        testInputs.chargeAmount = '14.50';
        testInputs.chargeDate = '2022-09-29';
        testInputs.contactId = con.Contact_ID__c;
        testInputs.cvc = 'LYkZOqxLEmd43MCeZxbKyw=='; // '123';
        testInputs.exceptionBatchFlags = '';
        testInputs.fundId = '';
        testInputs.furtherAttentionNotes = '';
        testInputs.giftChannel = 'mail';
        testInputs.giftReference = '';
        testInputs.noReceipt = 'N';
        testInputs.packageId = '';
        testInputs.parentOpportunity = '';
        testInputs.paymentMethod = 'Credit Card';
        testInputs.recurringDonation = 'N';
        testInputs.TMScity = 'Calgary';
        testInputs.type = 'Credit Card';
        testInputs.tributeType = '';
        testInputs.tributeDescription = '';
        testInputs.honoreeName = '';
        testInputs.honoreeContactId = '';
        testInputs.benefitValue = '';
        testInputs.inKindType = '';
        testInputs.inKindSubtype = '';
        testInputs.inKindDeclaredValue = 'N';
        testInputs.inKindVerifiedValue = '';
        testInputs.inKindDescription = '';
        testInputs.inKindValuationNote = '';
        testInputs.scannedImage = '';   
        testInputs.packageTMSid ='KZ0000';
        testInputs.appealTMSid = cam.Campaign_Appeal_ID__c;
        testInputs.tmsTransactInfo = 'bPmSgVkYp4s6v9t$';
        // testInputs.appealTMSid = '1806M3H';

        //instantiate the REST context
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/DonationProcessing/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(testInputs));
        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            ScanStationInputService.Result myResult = ScanStationInputService.receiveInput(testInputs);
            system.debug('KJW response:  ' + restContext.response);
            system.debug('Result Body:  ' + myResult.TransactionResult);
        Test.stopTest();

        System.assert(myResult.TransactionResult ==  'Success', 'Not a Success. Result is:  ' + myResult.TransactionResult + '  Message is:  ' + myResult.Errormsg + '  Id is:  ' + myResult.donationId);
        // Test.startTest();
        //     String actual = null; //HttpClass.updateCustomObject();
        // Test.stopTest();

        // System.assertEquals('expected value', actual, 'Value is incorrect');
    }

    @isTest
    static void testCheckValid() {

        Contact con = TestDataFactory.createContact();
        Campaign cam = TestDataFactory.createCampaign('test2');
        ChargentBase__Gateway__c g = TestDataFactory.createGateway('g2');

        // setup test call
        ScanStationInputService.Inputs testInputs = new ScanStationInputService.Inputs();

        testInputs.accountId = con.Account.Id;
        testInputs.anonymous = 'N';
        testInputs.appealId = cam.Id;
        testInputs.bankAccountNumber = '';
        testInputs.bankRoutingNumber = '';
        testInputs.batchId = '';
        testInputs.billingName = '';
        testInputs.cardExpirationMonth = '';
        testInputs.cardExpirationYear = ''; 
        testInputs.cardNumber = ''; 
        testInputs.campaignId = '';
        testInputs.chargeAmount = '14.50';
        testInputs.chargeDate = '2022-09-29';
        testInputs.contactId = '';
        testInputs.cvc = ''; // '123';
        testInputs.exceptionBatchFlags = '';
        testInputs.fundId = '';
        testInputs.furtherAttentionNotes = '';
        testInputs.giftChannel = '';
        testInputs.giftReference = '';
        testInputs.noReceipt = 'N';
        testInputs.packageId = '';
        testInputs.parentOpportunity = '';
        testInputs.paymentMethod = 'Check';
        testInputs.recurringDonation = 'N';
        testInputs.TMScity = 'Calgary';
        testInputs.type = 'Check';
        testInputs.tributeType = '';
        testInputs.tributeDescription = '';
        testInputs.honoreeName = '';
        testInputs.honoreeContactId = '';
        testInputs.benefitValue = '';
        testInputs.inKindType = '';
        testInputs.inKindSubtype = '';
        testInputs.inKindDeclaredValue = 'N';
        testInputs.inKindVerifiedValue = '';
        testInputs.inKindDescription = '';
        testInputs.inKindValuationNote = '';
        testInputs.scannedImage = '';   
        testInputs.packageTMSid ='CEV001';
        testInputs.tmsTransactInfo = '';
        // testInputs.appealTMSid = '1806M3H';

        //instantiate the REST context
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/DonationProcessing/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(testInputs));
        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            ScanStationInputService.Result myResult = ScanStationInputService.receiveInput(testInputs);
            system.debug('KJW response:  ' + restContext.response);
            system.debug('Result Body:  ' + myResult.TransactionResult);
        Test.stopTest();

        System.assert(myResult.TransactionResult ==  'Success', 'Not a Success. Result is:  ' + myResult.TransactionResult + '  Message is:  ' + myResult.Errormsg + '  Id is:  ' + myResult.donationId);
        // Test.startTest();
        //     String actual = null; //HttpClass.updateCustomObject();
        // Test.stopTest();

        // System.assertEquals('expected value', actual, 'Value is incorrect');
    }

    @isTest
    static void testCheckError() {
       
        Contact con = TestDataFactory.createContact();
        Campaign cam = TestDataFactory.createCampaign('test3');
        ChargentBase__Gateway__c g = TestDataFactory.createGateway('g3');

        // setup test call
        ScanStationInputService.Inputs testInputs = new ScanStationInputService.Inputs();

        testInputs.accountId = con.Account.Id;
        testInputs.anonymous = 'N';
        testInputs.appealId = '';
        testInputs.bankAccountNumber = '';
        testInputs.bankRoutingNumber = '';
        testInputs.batchId = '';
        testInputs.billingName = '';
        testInputs.cardExpirationMonth = '';
        testInputs.cardExpirationYear = ''; 
        testInputs.cardNumber = ''; 
        testInputs.campaignId = cam.Id;
        testInputs.chargeAmount = '14.50';
        testInputs.chargeDate = '2022-09-29';
        testInputs.contactId = '';
        testInputs.cvc = ''; // '123';
        testInputs.exceptionBatchFlags = '';
        testInputs.fundId = '';
        testInputs.furtherAttentionNotes = '';
        testInputs.giftChannel = '';
        testInputs.giftReference = '';
        testInputs.noReceipt = 'N';
        testInputs.packageId = '';
        testInputs.parentOpportunity = '';
        testInputs.paymentMethod = 'Check';
        testInputs.recurringDonation = 'N';
        testInputs.TMScity = 'Kalamazoo';
        testInputs.type = 'Check';
        testInputs.tributeType = '';
        testInputs.tributeDescription = '';
        testInputs.honoreeName = '';
        testInputs.honoreeContactId = '';
        testInputs.benefitValue = '';
        testInputs.inKindType = '';
        testInputs.inKindSubtype = '';
        testInputs.inKindDeclaredValue = 'N';
        testInputs.inKindVerifiedValue = '';
        testInputs.inKindDescription = '';
        testInputs.inKindValuationNote = '';
        testInputs.scannedImage = '';   
        testInputs.packageTMSid ='CEV001';
        testInputs.tmsTransactInfo = '';
        // testInputs.appealTMSid = '1806M3H';

        //instantiate the REST context
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/DonationProcessing/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(testInputs));
        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            ScanStationInputService.Result myResult = ScanStationInputService.receiveInput(testInputs);
            system.debug('KJW response:  ' + restContext.response);
            system.debug('Result Body:  ' + myResult.TransactionResult);
        Test.stopTest();

        System.assert(myResult.TransactionResult ==  'Error', 'Not an Error. Result is:  ' + myResult.TransactionResult + '  Message is:  ' + myResult.Errormsg + '  Id is:  ' + myResult.donationId);
    }

    @isTest
    static void testJohnTest1() {

        Contact con = TestDataFactory.createContact();
        Campaign cam = TestDataFactory.createCampaign('test4');
        ChargentBase__Gateway__c g = TestDataFactory.createGateway('g4');

        // setup test call
        ScanStationInputService.Inputs testInputs = new ScanStationInputService.Inputs();

        testInputs.accountId = con.Account.Id;
        testInputs.anonymous = 'N';
        testInputs.bankAccountNumber = '';
        testInputs.bankRoutingNumber = '';
        testInputs.batchId = '';
        testInputs.billingName = '';
        // testInputs.cardExpirationMonth = 'vFmZZKUuf99UA+0bUJ2GxA==';
        // testInputs.cardExpirationYear = 'DYRYSmoxRCPqdp8aPL+39Q=='; 
        // testInputs.cardNumber = 'Ljz9iMNGIPU3Xwg4uGHG0HQ1sEZk9Uuao3pI6gKb3ms'; 
        testInputs.campaignId = '';
        // testInputs.chargeAmount = '14.50';
        // testInputs.chargeDate = '2022-09-29';
        testInputs.contactId = con.Contact_ID__c;
        // testInputs.cvc = 'LYkZOqxLEmd43MCeZxbKyw=='; // '123';
        testInputs.exceptionBatchFlags = '';
        testInputs.fundId = '';
        testInputs.furtherAttentionNotes = '';
        testInputs.giftChannel = '';
        testInputs.giftReference = '';
        testInputs.noReceipt = 'N';
        testInputs.packageId = '';
        testInputs.parentOpportunity = '';
        testInputs.paymentMethod = 'Credit Card';
        testInputs.recurringDonation = 'N';
        testInputs.TMScity = 'Edmonton';
        // testInputs.type = 'Credit Card';
        testInputs.tributeType = 'Honour';
        testInputs.tributeDescription = '';
        testInputs.honoreeName = '';
        testInputs.honoreeContactId = '';
        testInputs.benefitValue = '';
        testInputs.inKindType = '';
        testInputs.inKindSubtype = '';
        // testInputs.inKindDeclaredValue = 'N';
        testInputs.inKindVerifiedValue = '';
        testInputs.inKindDescription = '';
        testInputs.inKindValuationNote = '';
        testInputs.scannedImage = '';   
        testInputs.packageTMSid ='UZARP0';
        testInputs.appealTMSid = cam.Campaign_Appeal_ID__c;
        // testInputs.tmsTransactInfo = 'bPmSgVkYp4s6v9t$';
        // testInputs.appealTMSid = '1806M3H';

        //instantiate the REST context
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/DonationProcessing/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(testInputs));
        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            ScanStationInputService.Result myResult = ScanStationInputService.receiveInput(testInputs);
            system.debug('KJW response:  ' + restContext.response);
            system.debug('Result Body:  ' + myResult.TransactionResult);
        Test.stopTest();

        System.assert(myResult.TransactionResult ==  'Success', 'Not a Success. Result is:  ' + myResult.TransactionResult + '  Message is:  ' + myResult.Errormsg + '  Id is:  ' + myResult.donationId);
        // Test.startTest();
        //     String actual = null; //HttpClass.updateCustomObject();
        // Test.stopTest();

        // System.assertEquals('expected value', actual, 'Value is incorrect');
    }

    @isTest
    static void testMoneyOrder() {

        Contact con = TestDataFactory.createContact();
        Campaign cam = TestDataFactory.createCampaign('test4');
        ChargentBase__Gateway__c g = TestDataFactory.createGateway('g4');

        // setup test call
        ScanStationInputService.Inputs testInputs = new ScanStationInputService.Inputs();

        testInputs.accountId = con.Account.Id;
        testInputs.anonymous = 'N';
        testInputs.bankAccountNumber = '';
        testInputs.bankRoutingNumber = '';
        testInputs.batchId = '';
        testInputs.billingName = '';
        // testInputs.cardExpirationMonth = 'vFmZZKUuf99UA+0bUJ2GxA==';
        // testInputs.cardExpirationYear = 'DYRYSmoxRCPqdp8aPL+39Q=='; 
        // testInputs.cardNumber = 'Ljz9iMNGIPU3Xwg4uGHG0HQ1sEZk9Uuao3pI6gKb3ms'; 
        testInputs.campaignId = '';
        // testInputs.chargeAmount = '14.50';
        // testInputs.chargeDate = '2022-09-29';
        testInputs.contactId = con.Contact_ID__c;
        // testInputs.cvc = 'LYkZOqxLEmd43MCeZxbKyw=='; // '123';
        testInputs.exceptionBatchFlags = '';
        testInputs.fundId = '';
        testInputs.furtherAttentionNotes = '';
        testInputs.giftChannel = '';
        testInputs.giftReference = '';
        testInputs.noReceipt = 'N';
        testInputs.packageId = '';
        testInputs.parentOpportunity = '';
        testInputs.paymentMethod = 'Money Order';
        testInputs.recurringDonation = 'N';
        testInputs.TMScity = 'Edmonton';
        // testInputs.type = 'Credit Card';
        testInputs.tributeType = 'Honour';
        testInputs.tributeDescription = '';
        testInputs.honoreeName = '';
        testInputs.honoreeContactId = '';
        testInputs.benefitValue = '';
        testInputs.inKindType = '';
        testInputs.inKindSubtype = '';
        // testInputs.inKindDeclaredValue = 'N';
        testInputs.inKindVerifiedValue = '';
        testInputs.inKindDescription = '';
        testInputs.inKindValuationNote = '';
        testInputs.scannedImage = '';   
        testInputs.packageTMSid ='UZARP0';
        testInputs.appealTMSid = cam.Campaign_Appeal_ID__c;
        // testInputs.tmsTransactInfo = 'bPmSgVkYp4s6v9t$';
        // testInputs.appealTMSid = '1806M3H';

        //instantiate the REST context
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/DonationProcessing/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(testInputs));
        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            ScanStationInputService.Result myResult = ScanStationInputService.receiveInput(testInputs);
            system.debug('KJW response:  ' + restContext.response);
            system.debug('Result Body:  ' + myResult.TransactionResult);
        Test.stopTest();

        System.assert(myResult.TransactionResult ==  'Error', 'Not an Error. Result is:  ' + myResult.TransactionResult + '  Message is:  ' + myResult.Errormsg + '  Id is:  ' + myResult.donationId);
        // Test.startTest();
        //     String actual = null; //HttpClass.updateCustomObject();
        // Test.stopTest();

        // System.assertEquals('expected value', actual, 'Value is incorrect');
    }

    @isTest
    static void testCash() {

        Contact con = TestDataFactory.createContact();
        Campaign cam = TestDataFactory.createCampaign('test4');
        ChargentBase__Gateway__c g = TestDataFactory.createGateway('g4');

        // setup test call
        ScanStationInputService.Inputs testInputs = new ScanStationInputService.Inputs();

        testInputs.accountId = con.Account.Id;
        testInputs.anonymous = 'N';
        testInputs.bankAccountNumber = '';
        testInputs.bankRoutingNumber = '';
        testInputs.batchId = '';
        testInputs.billingName = '';
        // testInputs.cardExpirationMonth = 'vFmZZKUuf99UA+0bUJ2GxA==';
        // testInputs.cardExpirationYear = 'DYRYSmoxRCPqdp8aPL+39Q=='; 
        // testInputs.cardNumber = 'Ljz9iMNGIPU3Xwg4uGHG0HQ1sEZk9Uuao3pI6gKb3ms'; 
        testInputs.campaignId = '';
        // testInputs.chargeAmount = '14.50';
        // testInputs.chargeDate = '2022-09-29';
        testInputs.contactId = con.Contact_ID__c;
        // testInputs.cvc = 'LYkZOqxLEmd43MCeZxbKyw=='; // '123';
        testInputs.exceptionBatchFlags = '';
        testInputs.fundId = '';
        testInputs.furtherAttentionNotes = '';
        testInputs.giftChannel = '';
        testInputs.giftReference = '';
        testInputs.noReceipt = 'N';
        testInputs.packageId = '';
        testInputs.parentOpportunity = '';
        testInputs.paymentMethod = 'Cash';
        testInputs.recurringDonation = 'N';
        testInputs.TMScity = 'Edmonton';
        // testInputs.type = 'Credit Card';
        testInputs.tributeType = 'Honour';
        testInputs.tributeDescription = '';
        testInputs.honoreeName = '';
        testInputs.honoreeContactId = '';
        testInputs.benefitValue = '';
        testInputs.inKindType = '';
        testInputs.inKindSubtype = '';
        // testInputs.inKindDeclaredValue = 'N';
        testInputs.inKindVerifiedValue = '';
        testInputs.inKindDescription = '';
        testInputs.inKindValuationNote = '';
        testInputs.scannedImage = '';   
        testInputs.packageTMSid ='UZARP0';
        testInputs.appealTMSid = cam.Campaign_Appeal_ID__c;
        // testInputs.tmsTransactInfo = 'bPmSgVkYp4s6v9t$';
        // testInputs.appealTMSid = '1806M3H';

        //instantiate the REST context
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/DonationProcessing/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(testInputs));
        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            ScanStationInputService.Result myResult = ScanStationInputService.receiveInput(testInputs);
            system.debug('KJW response:  ' + restContext.response);
            system.debug('Result Body:  ' + myResult.TransactionResult);
        Test.stopTest();

        System.assert(myResult.TransactionResult ==  'Success', 'Not a Success. Result is:  ' + myResult.TransactionResult + '  Message is:  ' + myResult.Errormsg + '  Id is:  ' + myResult.donationId);
        // Test.startTest();
        //     String actual = null; //HttpClass.updateCustomObject();
        // Test.stopTest();

        // System.assertEquals('expected value', actual, 'Value is incorrect');
    }

    @isTest
    static void testGoogleCheckout() {

        Contact con = TestDataFactory.createContact();
        Campaign cam = TestDataFactory.createCampaign('test4');
        ChargentBase__Gateway__c g = TestDataFactory.createGateway('g4');

        // setup test call
        ScanStationInputService.Inputs testInputs = new ScanStationInputService.Inputs();

        testInputs.accountId = con.Account.Id;
        testInputs.anonymous = 'N';
        testInputs.bankAccountNumber = '';
        testInputs.bankRoutingNumber = '';
        testInputs.batchId = '';
        testInputs.billingName = '';
        // testInputs.cardExpirationMonth = 'vFmZZKUuf99UA+0bUJ2GxA==';
        // testInputs.cardExpirationYear = 'DYRYSmoxRCPqdp8aPL+39Q=='; 
        // testInputs.cardNumber = 'Ljz9iMNGIPU3Xwg4uGHG0HQ1sEZk9Uuao3pI6gKb3ms'; 
        testInputs.campaignId = '';
        // testInputs.chargeAmount = '14.50';
        // testInputs.chargeDate = '2022-09-29';
        testInputs.contactId = con.Contact_ID__c;
        // testInputs.cvc = 'LYkZOqxLEmd43MCeZxbKyw=='; // '123';
        testInputs.exceptionBatchFlags = '';
        testInputs.fundId = '';
        testInputs.furtherAttentionNotes = '';
        testInputs.giftChannel = '';
        testInputs.giftReference = '';
        testInputs.noReceipt = 'N';
        testInputs.packageId = '';
        testInputs.parentOpportunity = '';
        testInputs.paymentMethod = 'Google Checkout';
        testInputs.recurringDonation = 'N';
        testInputs.TMScity = 'Edmonton';
        // testInputs.type = 'Credit Card';
        testInputs.tributeType = 'Honour';
        testInputs.tributeDescription = '';
        testInputs.honoreeName = '';
        testInputs.honoreeContactId = '';
        testInputs.benefitValue = '';
        testInputs.inKindType = '';
        testInputs.inKindSubtype = '';
        // testInputs.inKindDeclaredValue = 'N';
        testInputs.inKindVerifiedValue = '';
        testInputs.inKindDescription = '';
        testInputs.inKindValuationNote = '';
        testInputs.scannedImage = '';   
        testInputs.packageTMSid ='UZARP0';
        testInputs.appealTMSid = cam.Campaign_Appeal_ID__c;
        // testInputs.tmsTransactInfo = 'bPmSgVkYp4s6v9t$';
        // testInputs.appealTMSid = '1806M3H';

        //instantiate the REST context
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/DonationProcessing/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(testInputs));
        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            ScanStationInputService.Result myResult = ScanStationInputService.receiveInput(testInputs);
            system.debug('KJW response:  ' + restContext.response);
            system.debug('Result Body:  ' + myResult.TransactionResult);
        Test.stopTest();

        System.assert(myResult.TransactionResult ==  'Error', 'Not an Error. Result is:  ' + myResult.TransactionResult + '  Message is:  ' + myResult.Errormsg + '  Id is:  ' + myResult.donationId);
        // Test.startTest();
        //     String actual = null; //HttpClass.updateCustomObject();
        // Test.stopTest();

        // System.assertEquals('expected value', actual, 'Value is incorrect');
    }

    @isTest
    static void testBankAccount() {

        Contact con = TestDataFactory.createContact();
        Campaign cam = TestDataFactory.createCampaign('test4');
        ChargentBase__Gateway__c g = TestDataFactory.createGateway('g4');

        // setup test call
        ScanStationInputService.Inputs testInputs = new ScanStationInputService.Inputs();

        testInputs.accountId = con.Account.Id;
        testInputs.anonymous = 'N';
        testInputs.bankAccountNumber = '';
        testInputs.bankRoutingNumber = '';
        testInputs.batchId = '';
        testInputs.billingName = '';
        // testInputs.cardExpirationMonth = 'vFmZZKUuf99UA+0bUJ2GxA==';
        // testInputs.cardExpirationYear = 'DYRYSmoxRCPqdp8aPL+39Q=='; 
        // testInputs.cardNumber = 'Ljz9iMNGIPU3Xwg4uGHG0HQ1sEZk9Uuao3pI6gKb3ms'; 
        testInputs.campaignId = '';
        // testInputs.chargeAmount = '14.50';
        // testInputs.chargeDate = '2022-09-29';
        testInputs.contactId = con.Contact_ID__c;
        // testInputs.cvc = 'LYkZOqxLEmd43MCeZxbKyw=='; // '123';
        testInputs.exceptionBatchFlags = '';
        testInputs.fundId = '';
        testInputs.furtherAttentionNotes = '';
        testInputs.giftChannel = '';
        testInputs.giftReference = '';
        testInputs.noReceipt = 'N';
        testInputs.packageId = '';
        testInputs.parentOpportunity = '';
        testInputs.paymentMethod = 'Bank Account';
        testInputs.recurringDonation = 'N';
        testInputs.TMScity = 'Edmonton';
        // testInputs.type = 'Credit Card';
        testInputs.tributeType = 'Honour';
        testInputs.tributeDescription = '';
        testInputs.honoreeName = '';
        testInputs.honoreeContactId = '';
        testInputs.benefitValue = '';
        testInputs.inKindType = '';
        testInputs.inKindSubtype = '';
        // testInputs.inKindDeclaredValue = 'N';
        testInputs.inKindVerifiedValue = '';
        testInputs.inKindDescription = '';
        testInputs.inKindValuationNote = '';
        testInputs.scannedImage = '';   
        testInputs.packageTMSid ='UZARP0';
        testInputs.appealTMSid = cam.Campaign_Appeal_ID__c;
        // testInputs.tmsTransactInfo = 'bPmSgVkYp4s6v9t$';
        // testInputs.appealTMSid = '1806M3H';

        //instantiate the REST context
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/DonationProcessing/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(testInputs));
        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            ScanStationInputService.Result myResult = ScanStationInputService.receiveInput(testInputs);
            system.debug('KJW response:  ' + restContext.response);
            system.debug('Result Body:  ' + myResult.TransactionResult);
        Test.stopTest();

        System.assert(myResult.TransactionResult ==  'Error', 'Not an Error. Result is:  ' + myResult.TransactionResult + '  Message is:  ' + myResult.Errormsg + '  Id is:  ' + myResult.donationId);
        // Test.startTest();
        //     String actual = null; //HttpClass.updateCustomObject();
        // Test.stopTest();

        // System.assertEquals('expected value', actual, 'Value is incorrect');
    }

    @isTest
    static void testUnknownPaymentMethod() {

        Contact con = TestDataFactory.createContact();
        Campaign cam = TestDataFactory.createCampaign('test4');
        ChargentBase__Gateway__c g = TestDataFactory.createGateway('g4');

        // setup test call
        ScanStationInputService.Inputs testInputs = new ScanStationInputService.Inputs();

        testInputs.accountId = con.Account.Id;
        testInputs.anonymous = 'N';
        testInputs.bankAccountNumber = '';
        testInputs.bankRoutingNumber = '';
        testInputs.batchId = '';
        testInputs.billingName = '';
        // testInputs.cardExpirationMonth = 'vFmZZKUuf99UA+0bUJ2GxA==';
        // testInputs.cardExpirationYear = 'DYRYSmoxRCPqdp8aPL+39Q=='; 
        // testInputs.cardNumber = 'Ljz9iMNGIPU3Xwg4uGHG0HQ1sEZk9Uuao3pI6gKb3ms'; 
        testInputs.campaignId = '';
        // testInputs.chargeAmount = '14.50';
        // testInputs.chargeDate = '2022-09-29';
        testInputs.contactId = con.Contact_ID__c;
        // testInputs.cvc = 'LYkZOqxLEmd43MCeZxbKyw=='; // '123';
        testInputs.exceptionBatchFlags = '';
        testInputs.fundId = '';
        testInputs.furtherAttentionNotes = '';
        testInputs.giftChannel = '';
        testInputs.giftReference = '';
        testInputs.noReceipt = 'N';
        testInputs.packageId = '';
        testInputs.parentOpportunity = '';
        testInputs.paymentMethod = 'Something';
        testInputs.recurringDonation = 'N';
        testInputs.TMScity = 'Edmonton';
        // testInputs.type = 'Credit Card';
        testInputs.tributeType = 'Honour';
        testInputs.tributeDescription = '';
        testInputs.honoreeName = '';
        testInputs.honoreeContactId = '';
        testInputs.benefitValue = '';
        testInputs.inKindType = '';
        testInputs.inKindSubtype = '';
        // testInputs.inKindDeclaredValue = 'N';
        testInputs.inKindVerifiedValue = '';
        testInputs.inKindDescription = '';
        testInputs.inKindValuationNote = '';
        testInputs.scannedImage = '';   
        testInputs.packageTMSid ='UZARP0';
        testInputs.appealTMSid = cam.Campaign_Appeal_ID__c;
        // testInputs.tmsTransactInfo = 'bPmSgVkYp4s6v9t$';
        // testInputs.appealTMSid = '1806M3H';

        //instantiate the REST context
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/DonationProcessing/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(testInputs));
        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            ScanStationInputService.Result myResult = ScanStationInputService.receiveInput(testInputs);
            system.debug('KJW response:  ' + restContext.response);
            system.debug('Result Body:  ' + myResult.TransactionResult);
        Test.stopTest();

        System.assert(myResult.TransactionResult ==  'Error', 'Not an Error. Result is:  ' + myResult.TransactionResult + '  Message is:  ' + myResult.Errormsg + '  Id is:  ' + myResult.donationId);
        // Test.startTest();
        //     String actual = null; //HttpClass.updateCustomObject();
        // Test.stopTest();

        // System.assertEquals('expected value', actual, 'Value is incorrect');
    }


}