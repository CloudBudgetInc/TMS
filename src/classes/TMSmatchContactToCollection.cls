/****************************************************************************
* Apex Class Name : TMSmatchContactToCollection
* Version         : 1.0 
* Created Date    : 17 JAN 2022
* Function        : Invocable Method - to be called from Flow. Compares  
*                   the details of a Contact to a collection of Contacts 
*                   (first name, last name, email, phone, street, and postal) 
*                   to determine how similar they are and declare a match
*
* Modification Log:
* Developer                   Date                   Description
* ----------------------------------------------------------------------------                 
* Kevin Waites              5/09/2022              Original Version
******************************************************************************/


public class TMSmatchContactToCollection {
   
    @InvocableMethod(label='Compare Contact to Collection' description='Compares the First Name, Last Name, Email, Phone, Street Address, and Postal code of a contact to a collection of Contacts and returns the closest match')
    public static List<Contact> compareContactCollection(List<MatchContactsCollectionRequests> inputDetails){

        // initialize placeholders for the best match
        Integer topScore = 0;
        Contact topContact = new Contact();

        // clean the reference inputs
        if(!String.isBlank(inputDetails[0].inputReferenceFirstName)){
            inputDetails[0].inputReferenceFirstName = cleanNames(inputDetails[0].inputReferenceFirstName);
        }
        if(!String.isBlank(inputDetails[0].inputReferenceLastName)){   
            inputDetails[0].inputReferenceLastName = cleanNames(inputDetails[0].inputReferenceLastName);
        }
        if(!String.isBlank(inputDetails[0].inputReferenceEmail)){   
            inputDetails[0].inputReferenceEmail = cleanEmails(inputDetails[0].inputReferenceEmail);
        }
        if(!String.isBlank(inputDetails[0].inputReferencePhone)){   
            inputDetails[0].inputReferencePhone = cleanPhones(inputDetails[0].inputReferencePhone);
        }
        if(!String.isBlank(inputDetails[0].inputReferenceStreet)){   
            inputDetails[0].inputReferenceStreet = cleanStreets(inputDetails[0].inputReferenceStreet);
        }
        if(!String.isBlank(inputDetails[0].inputReferencePostal)){   
            inputDetails[0].inputReferencePostal = cleanPostals(inputDetails[0].inputReferencePostal);
        }

        // loop through each Contact in the collection
        for(Contact thisContact: inputDetails[0].inputComparisonContacts){
            //System.Debug('TopScore:  ' + topScore + '  TopContact First:  ' + topContact.FirstName + '  breakCount:  ' + breakCount);
            
            // Reset the score every loop cycle
            Integer thisScore = 0;
            
            // ***** FIRST NAME *****
            if(!String.isBlank(thisContact.FirstName) && !String.isBlank(inputDetails[0].inputReferenceFirstName)){
                // if this is an immediate match
                if(thisContact.firstName == inputDetails[0].inputReferenceFirstName) {
                    // add one to the score of this Contact
                    thisScore ++;
                } else { // if there is not immediate match proceed to cleaning etc.

                    // clean this First Name
                    String cleanedFirstName = cleanNames(thisContact.firstName);

                    // compare this First Name to the Reference First Name
                    MatchResults firstNameScore = match(inputDetails[0].inputReferenceFirstName, cleanedFirstName);

                    // if the comparison score is above the threshold, add to the score for this contact
                    if(firstNameScore.percentage >= decimal.valueOf(inputDetails[0].inputFirstNameThreshold)) {
                        thisScore ++;
                    }
                }
            }

            // if it is no longer possible for this Contact to match the current best match
            // skip out of this loop cycle and on to the next Contact in the collection
            if(thisScore < topScore - 5){
                continue;
            }


            // ***** LAST NAME *****
            if(!String.isBlank(thisContact.LastName)){
                // if this is an immediate match
                if(thisContact.LastName == inputDetails[0].inputReferenceLastName){
                    // add one to the score of this Contact
                    thisScore ++;
                } else{ // if there is not immediate match proceed to cleaning etc.

                    // clean this last Name
                    thisContact.lastName = cleanNames(thisContact.lastName);

                    // compare this last Name to the Reference last Name
                    MatchResults lastNameScore = match(inputDetails[0].inputReferencelastName, thisContact.lastName);

                    // if the comparison score is above the threshold, add to the score for this contact
                    if(lastNameScore.percentage >= decimal.valueOf(inputDetails[0].inputlastNameThreshold)) {
                        thisScore ++;
                    }
                }
            }

            // if it is no longer possible for this Contact to match the current best match
            // skip out of this loop cycle and on to the next Contact in the collection
            if(thisScore < topScore - 4){
                continue;
            }

            // ***** EMAIL *****
            
            // Add all of the email fields to a collection
            List<String> emailTypes = new List<String>();
            emailTypes.add(thisContact.Email);
            emailTypes.add(thisContact.Email_1__c);
            emailTypes.add(thisContact.Email_2__c);
            emailTypes.add(thisContact.Email_3__c);
            emailTypes.add(thisContact.Marketing_Email__c);
            emailTypes.add(thisContact.npe01__AlternateEmail__c);
            emailTypes.add(thisContact.npe01__HomeEmail__c);
            emailTypes.add(thisContact.npe01__WorkEmail__c);

            // loop through each email to try and find a match
            for(String thisEmail: emailTypes){

                if(!String.isBlank(thisEmail) && !String.isBlank(inputDetails[0].inputReferenceEmail)){

                    // clean this email
                    thisEmail = cleanEmails(thisEmail);

                    // compare this email to the Reference email
                    MatchResults emailScore = match(inputDetails[0].inputReferenceEmail, thisEmail);

                    // if the comparison score is above the threshold, add to the score for this contact and end the email loop
                    if(emailScore.percentage >= decimal.valueOf(inputDetails[0].inputemailThreshold)) {
                        thisScore ++;
                        break;
                    }         
                }       
            }

            // if it is no longer possible for this Contact to match the current best match
            // skip out of this loop cycle and on to the next Contact in the collection
            if(thisScore < topScore - 3){
                continue;
            }

            // ***** PHONE *****

            // Add all of the phone fields to a collection
            List<String> phoneTypes = new List<String>();
            phoneTypes.add(thisContact.Phone);
            phoneTypes.add(thisContact.HomePhone);
            phoneTypes.add(thisContact.npe01__WorkPhone__c);
            phoneTypes.add(thisContact.MobilePhone);
            phoneTypes.add(thisContact.AssistantPhone);
            phoneTypes.add(thisContact.Alternate_Home_Phone__c);
            phoneTypes.add(thisContact.OtherPhone);
            phoneTypes.add(thisContact.telussfl__SMS_Number__c);
            phoneTypes.add(thisContact.npo02__Formula_HouseholdPhone__c);

            // loop through each phone to try and find a match
            for(String thisPhone: phoneTypes){

                if(!String.isBlank(thisPhone) && !String.isBlank(inputDetails[0].inputReferencePhone)){

                    // clean this phone
                    thisPhone = cleanPhones(thisPhone);

                    // compare this phone to the Reference phone
                    MatchResults phoneScore = match(inputDetails[0].inputReferencephone, thisPhone);

                    // if the comparison score is above the threshold, add to the score for this contact
                    if(phoneScore.percentage >= decimal.valueOf(inputDetails[0].inputPhoneThreshold)) {
                        thisScore ++;
                        break;
                    }
                }
            }

            // if it is no longer possible for this Contact to match the current best match
            // skip out of this loop cycle and on to the next Contact in the collection
            if(thisScore < topScore - 2){
                continue;
            }

            // ***** STREET *****
            if(!String.isBlank(thisContact.MailingStreet) && !String.isBlank(inputDetails[0].inputReferenceStreet)){

                // if this is an immediate match
                if(thisContact.MailingStreet == inputDetails[0].inputReferenceStreet) {
                    // add one to the score of this Contact
                    thisScore ++;
                } else { // if there is not immediate match proceed to cleaning etc.
                    
                    // clean this street
                    thisContact.MailingStreet = cleanStreets(thisContact.MailingStreet);

                    // compare this street to the Reference street
                    MatchResults streetScore = match(inputDetails[0].inputReferenceStreet, thisContact.MailingStreet);

                    // if the comparison score is above the threshold, add to the score for this contact
                    if(streetScore.percentage >= decimal.valueOf(inputDetails[0].inputphoneThreshold)) {
                        thisScore ++;
                    }
                }
            }

            // if it is no longer possible for this Contact to match the current best match
            // skip out of this loop cycle and on to the next Contact in the collection            
            if(thisScore < topScore - 1){
                continue;
            }

            // ***** POSTAL *****
            if(!String.isBlank(thisContact.MailingPostalCode) && !String.isBlank(inputDetails[0].inputReferencePostal)){
                // if this is an immediate match
                if(thisContact.MailingPostalCode == inputDetails[0].inputReferencePostal) {
                    // add one to the score of this Contact
                    thisScore ++;
                } else { // if there is not immediate match proceed to cleaning etc.

                    // clean this postal
                    thisContact.MailingPostalCode = cleanPostals(thisContact.MailingPostalCode);

                    // compare this phone to the Reference phone
                    MatchResults postalScore = match(inputDetails[0].inputReferencePostal, thisContact.MailingPostalCode);

                    // if the comparison score is above the threshold, add to the score for this contact
                    if(PostalScore.percentage >= decimal.valueOf(inputDetails[0].inputPostalThreshold)) {
                        thisScore ++;
                    }
                }
            }

            // is this a perfect score
            if(thisScore == 6){
                topContact = thisContact;
                break;
            } else if((thisScore > topScore) && (thisScore > 2)){ // is this the new top score
                topContact = thisContact;
                topScore = thisScore;
            } else if(thisScore == topScore){ // does this match the currnet top score

                // the newer record is the top score
                if(thisContact.CreatedDate < topContact.CreatedDate){
                    topContact = thisContact;
                    topScore = thisScore;
                }
            }
        }
        List<Contact> returnList = new List<Contact>();
        returnList.add(topContact);
        return returnList;
    }

    private static String cleanNames(String thisName){
        // Convert to Lowercase
        thisName = thisName.toLowerCase();

        // send to patternMatcher to perform a regex operation
        thisName = patternMatcher('\\s(?=\\s+)|(\\.)', thisName);
        
        //return the cleaned name
        return thisName;
    }

    private static String cleanEmails(String thisEmail){
        // Convert to Lowercase
        thisEmail = thisEmail.toLowerCase();

        // send to patternMatcher to perform a regex operation
        thisEmail = patternMatcher('\\s(?=\\s+)|(\\.)', thisEmail);
        
        //return the cleaned Email
        return thisEmail;
    }

    private static String cleanPhones(String thisPhone){

        // send to patternMatcher to perform a regex operation
        thisPhone = patternMatcher('[-,.()+\\s]', thisPhone);
        
        //return the cleaned Phone
        return thisPhone;
    }

    private static String cleanStreets(String thisStreet){
        // Convert to Lowercase
        thisStreet = thisStreet.toLowerCase();

        thisStreet.replaceAll('st', 'street');
        thisStreet.replaceAll('ave', 'avenue');
        thisStreet.replaceAll('pl', 'place');
        thisStreet.replaceAll('cres', 'crescent');
        thisStreet.replaceAll('cr', 'crescent');
        thisStreet.replaceAll('blvd', 'boulevard');
        thisStreet.replaceAll('dr', 'drive');
        thisStreet.replaceAll('rd', 'road');
        thisStreet.replaceAll('crt', 'court');
        thisStreet.replaceAll('ne', 'northeast');
        thisStreet.replaceAll('nw', 'northwest');
        thisStreet.replaceAll('se', 'southeast');
        thisStreet.replaceAll('sw', 'southwest');
        thisStreet.replaceAll('Unit', '');
        thisStreet.replaceAll('#', '');


        // send to patternMatcher to perform a regex operation
        thisStreet = patternMatcher('(?<=[0-9])(?:st|nd|rd|th)|\\s(?=\\s+)|(\\.)', thisStreet);
        
        //return the cleaned Street
        return thisStreet;
    }

    private static String cleanPostals(String thisPostal){
        // Convert to Lowercase
        thisPostal = thisPostal.toLowerCase();

        // send to patternMatcher to perform a regex operation
        thisPostal = patternMatcher('[-\\s]', thisPostal);
        
        //return the cleaned Postal
        return thisPostal;
    }


    private static String patternMatcher(String myPattern, String myString){
        // create a Pattern instance using the input
        Pattern thisPattern = Pattern.compile(myPattern);

        // create a Matcher instance for the reference and comparison
        Matcher thisMatcher = thisPattern.matcher(myString);

        return thisMatcher.replaceAll('');
    }

    private static matchResults match(String myReference, String myComparison){
        
        // get new instance of the wrapper class
        MatchResults matchResult = new MatchResults();

        // calculate the levenshtein distance as an integer and then as a percentage of the string lengths
        matchResult.distance = myReference.getLevenshteinDistance(myComparison);
        matchResult.percentage = (1 - (Double.valueOf(matchResult.distance) / Double.valueOf(Math.max(myReference.length(), myComparison.length())))) * 100;

        return matchResult;
    }

    public class MatchContactsCollectionRequests{
        @InvocableVariable(label='Reference First Name' description='The First Name of the Contact you are comparing against' required=false)
        public String inputReferenceFirstName;

        @InvocableVariable(label='Reference Last Name' description='The Last Name of the Contact you are comparing against' required=false)
        public String inputReferenceLastName;

        @InvocableVariable(label='Reference Email' description='The Email of the Contact you are comparing against' required=false)
        public String inputReferenceEmail;

        @InvocableVariable(label='Reference Phone' description='The Phone of the Contact you are comparing against' required=false)
        public String inputReferencePhone;

        @InvocableVariable(label='Reference Street' description='The Street of the Contact you are comparing against' required=false)
        public String inputReferenceStreet;

        @InvocableVariable(label='Reference Postal' description='The Postal of the Contact you are comparing against' required=false)
        public String inputReferencePostal;

        @InvocableVariable(label='Comparison Collection' description='Collection of Contacts to compare' required=true)
        public List<Contact> inputComparisonContacts;

        @InvocableVariable(label='First Name Threshold' description='Threshold required to determin a First Name Match' required=true)
        public String inputFirstNameThreshold;

        @InvocableVariable(label='Last Name Threshold' description='Threshold required to determin a Last Name Match' required=true)
        public String inputLastNameThreshold;

        @InvocableVariable(label='Email Threshold' description='Threshold required to determin a Email Match' required=true)
        public String inputEmailThreshold;

        @InvocableVariable(label='Phone Threshold' description='Threshold required to determin a Phone Match' required=true)
        public String inputPhoneThreshold;

        @InvocableVariable(label='Street Threshold' description='Threshold required to determin a Street Match' required=true)
        public String inputStreetThreshold;

        @InvocableVariable(label='Postal Threshold' description='Threshold required to determin a Postal Match' required=true)
        public String inputPostalThreshold;
    }

    public class MatchResults{
        Integer distance;
        Double percentage;
    }

}