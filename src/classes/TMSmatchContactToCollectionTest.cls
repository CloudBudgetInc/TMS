@isTest
public with sharing class TMSmatchContactToCollectionTest {
    
    @isTest
    static void compareTwoMatchingContacts(){

        Contact positiveMatchContact = new Contact();
        positiveMatchContact.FirstName = 'John';
        positiveMatchContact.LastName = 'Smith';
        positiveMatchContact.Email = 'smith@smith.com.invalid';
        positiveMatchContact.Phone = '403-111-2222';
        positiveMatchContact.MailingStreet = '123 here st';
        positiveMatchContact.MailingPostalCode = 'T1T 1T1';

        List<Contact> contactCollection = new List<Contact>();

        for(Integer i=0; i<5000; i++){
            Contact negativeMatchContact = new Contact();
            negativeMatchContact.FirstName = 'John0' + i;
            negativeMatchContact.LastName = 'Smith0' + i;
            negativeMatchContact.Email = 'smith@smith.com.invali0' + i;
            negativeMatchContact.Phone = '403-111-2220' + i;
            negativeMatchContact.MailingStreet = '123 here st0' + i;
            negativeMatchContact.MailingPostalCode = 'T1T 1T0' + i;
            contactCollection.add(negativeMatchContact);
        }

        contactCollection.add(positiveMatchContact);

        TMSmatchContactToCollection.MatchContactsCollectionRequests inputDetails = new TMSmatchContactToCollection.MatchContactsCollectionRequests();
        inputDetails.inputFirstNameThreshold = '75';
        inputDetails.inputLastNameThreshold = '75';
        inputDetails.inputEmailThreshold = '75';
        inputDetails.inputPhoneThreshold = '75';
        inputDetails.inputStreetThreshold = '75';
        inputDetails.inputPostalThreshold = '75';
        inputDetails.inputReferenceEmail = '75';
        inputDetails.inputReferenceFirstName = 'John';
        inputDetails.inputReferenceLastName = 'Smith';
        inputDetails.inputReferenceEmail = 'smith@smith.com.invalid';
        inputDetails.inputReferencePhone = '403-111-2222';
        inputDetails.inputReferenceStreet = '123 here st';
        inputDetails.inputReferencePostal = 'T1T 1T1';
        inputDetails.inputComparisonContacts = contactCollection;
        
        List<TMSmatchContactToCollection.MatchContactsCollectionRequests> inputDetailsList = new List<TMSmatchContactToCollection.MatchContactsCollectionRequests>();
        inputDetailsList.add(inputDetails);
        List<Contact> myResultsList = new List<Contact>();
        myResultsList = TMSmatchContactToCollection.compareContactCollection(inputDetailsList);

        System.assert(myResultsList.size() != 0, 'Returned 0 results');
        System.assert(myResultsList.size() == 1, 'Returned too many results');

    }

    @isTest(SeeAllData=true)
    static void compareMatchingContactsFromDatabase(){

        Contact positiveMatchContact = new Contact();
        positiveMatchContact.FirstName = 'Frances';
        positiveMatchContact.LastName = 'Smith';
        positiveMatchContact.Email = 'frances.smith@shaw.ca';
        positiveMatchContact.Phone = '(403) 256-1461';
        positiveMatchContact.MailingStreet = '11 Shannon Dr SW';
        positiveMatchContact.MailingPostalCode = 'T2Y 2A5';

        List<Contact> contactCollection = new List<Contact>();

        contactCollection = [SELECT Id, FirstName, LastName, Email, Email_1__c, Email_2__c, Email_3__c, Marketing_Email__c, npe01__AlternateEmail__c, npe01__HomeEmail__c, npe01__WorkEmail__c, Phone, HomePhone, npe01__WorkPhone__c, MobilePhone, AssistantPhone, Alternate_Home_Phone__c, OtherPhone, telussfl__SMS_Number__c, npo02__Formula_HouseholdPhone__c, MailingStreet, MailingPostalCode, CreatedDate FROM Contact WHERE LastName='Smith'];

        contactCollection.add(positiveMatchContact);

        TMSmatchContactToCollection.MatchContactsCollectionRequests inputDetails = new TMSmatchContactToCollection.MatchContactsCollectionRequests();
        inputDetails.inputFirstNameThreshold = '75';
        inputDetails.inputLastNameThreshold = '75';
        inputDetails.inputEmailThreshold = '75';
        inputDetails.inputPhoneThreshold = '75';
        inputDetails.inputStreetThreshold = '75';
        inputDetails.inputPostalThreshold = '75';
        inputDetails.inputReferenceEmail = '75';
        inputDetails.inputReferenceFirstName = 'John';
        inputDetails.inputReferenceLastName = 'Smith';
        inputDetails.inputReferenceEmail = 'smith@smith.com.invalid';
        inputDetails.inputReferencePhone = '403-111-2222';
        inputDetails.inputReferenceStreet = '123 here st';
        inputDetails.inputReferencePostal = 'T1T 1T1';
        inputDetails.inputComparisonContacts = contactCollection;
        
        List<TMSmatchContactToCollection.MatchContactsCollectionRequests> inputDetailsList = new List<TMSmatchContactToCollection.MatchContactsCollectionRequests>();
        inputDetailsList.add(inputDetails);
        List<Contact> myResultsList = new List<Contact>();
        myResultsList = TMSmatchContactToCollection.compareContactCollection(inputDetailsList);

        System.assert(myResultsList.size() != 0, 'Returned 0 results');
        System.assert(myResultsList.size() == 1, 'Returned too many results');

    }

    // This test will fail with a result of 
    // LimitException: Too many query rows: 50001

    // @isTest(SeeAllData=true)
    // static void compareAllContactsFromDatabase(){

    //     Integer positiveMatchCount = 0;      
    //     List<Contact> myErrors = new List<Contact>();
  
    //     List<Contact> referenceContactsCollection = [SELECT Id, FirstName, LastName, Email, Email_1__c, Email_2__c, Email_3__c, Marketing_Email__c, npe01__AlternateEmail__c, npe01__HomeEmail__c, npe01__WorkEmail__c, Phone, HomePhone, npe01__WorkPhone__c, MobilePhone, AssistantPhone, Alternate_Home_Phone__c, OtherPhone, telussfl__SMS_Number__c, npo02__Formula_HouseholdPhone__c, MailingStreet, MailingPostalCode, CreatedDate FROM Contact LIMIT 50];
    //     List<Contact> allContactsCollection = [SELECT Id, FirstName, LastName, Email, Email_1__c, Email_2__c, Email_3__c, Marketing_Email__c, npe01__AlternateEmail__c, npe01__HomeEmail__c, npe01__WorkEmail__c, Phone, HomePhone, npe01__WorkPhone__c, MobilePhone, AssistantPhone, Alternate_Home_Phone__c, OtherPhone, telussfl__SMS_Number__c, npo02__Formula_HouseholdPhone__c, MailingStreet, MailingPostalCode, CreatedDate FROM Contact];

    //     Matching_Accuracy__c myThresholds = Matching_Accuracy__c.getInstance();
        
    //     String inputFirstNameThreshold = String.valueOf(myThresholds.Contact_First_Name_Threshold__c);
    //     String inputLastNameThreshold = String.valueOf(myThresholds.Contact_Last_Name_Threshold__c);
    //     String inputEmailThreshold = String.valueOf(myThresholds.Contact_Email_Threshold__c);
    //     String inputPhoneThreshold = String.valueOf(myThresholds.Contact_Phone_Threshold__c);
    //     String inputStreetThreshold = String.valueOf(myThresholds.Contact_Street_Threshold__c);
    //     String inputPostalThreshold = String.valueOf(myThresholds.Contact_Postal_Threshold__c);

      
    //     for(Contact currentContact : referenceContactsCollection){
            
    //         If(!String.isBlank(currentContact.LastName)){
    //             If(!String.isBlank(currentContact.FirstName) && (!String.isBlank(currentContact.Email) || !String.isBlank(currentContact.Phone) || !String.isBlank(currentContact.MailingStreet) || !String.isBlank(currentContact.MailingPostalCode)) ){
    //                 TMSmatchContactToCollection.MatchContactsCollectionRequests inputDetails = new TMSmatchContactToCollection.MatchContactsCollectionRequests();
    //                 inputDetails.inputFirstNameThreshold = inputFirstNameThreshold;
    //                 inputDetails.inputLastNameThreshold = inputEmailThreshold;
    //                 inputDetails.inputEmailThreshold = inputEmailThreshold;
    //                 inputDetails.inputPhoneThreshold = inputPhoneThreshold;
    //                 inputDetails.inputStreetThreshold = inputStreetThreshold;
    //                 inputDetails.inputPostalThreshold = inputPostalThreshold;
    //                 inputDetails.inputReferenceEmail = currentContact.Email;
    //                 inputDetails.inputReferenceFirstName = currentContact.FirstName;
    //                 inputDetails.inputReferenceLastName = currentContact.lastname;
    //                 inputDetails.inputReferencePhone = currentContact.Phone;
    //                 inputDetails.inputReferenceStreet = currentContact.MailingStreet;
    //                 inputDetails.inputReferencePostal = currentContact.MailingPostalCode;
    //                 inputDetails.inputComparisonContacts = allContactsCollection;
                    
                    
    //                 List<TMSmatchContactToCollection.MatchContactsCollectionRequests> inputDetailsList = new List<TMSmatchContactToCollection.MatchContactsCollectionRequests>();
    //                 inputDetailsList.add(inputDetails);
    //                 List<Contact> myResultsList = new List<Contact>();
    //                 myResultsList = TMSmatchContactToCollection.compareContactCollection(inputDetailsList);
                    
    //                 if(myResultsList[0].Id == currentContact.Id) {
    //                     positiveMatchCount ++;
    //                 } else {
    //                     myErrors.add(currentContact);
    //                 }
    //             }
    //         }
    //     }

    //     System.debug('# of matches: ' + positiveMatchCount + '  # of records: ' + allContactsCollection.size());
    //     //System.assert(positiveMatchCount == allContactsCollection.size(), 'not enough positive matches!  # of matches: ' + positiveMatchCount + '  # of records: ' + allContactsCollection.size() + '  Errors:  ' + JSON.serializePretty(myErrors));
    //     System.assert(myErrors.size() == 0, 'ErrorsFound    # of matches: ' + positiveMatchCount + '  # of records: ' + allContactsCollection.size() + '  Errors:  ' + JSON.serializePretty(myErrors));
    // }
}