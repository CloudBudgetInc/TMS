public with sharing class TMSVolunteerPortalController {
    
    @AuraEnabled(cacheable=true)
    public static List<GW_Volunteers__Volunteer_Job__c> getJobsList() {
        return [SELECT Id, Name, GW_Volunteers__Location_City__c FROM GW_Volunteers__Volunteer_Job__c WHERE GW_Volunteers__Display_on_Website__c=True AND GW_Volunteers__Inactive__c=False LIMIT 10];
    }

    @AuraEnabled(cacheable=true)
    public static GW_Volunteers__Volunteer_Job__c getJobDetails(ID jobId) {
        return [SELECT Id, Name, GW_Volunteers__Description__c, GW_Volunteers__Display_on_Website__c, GW_Volunteers__Inactive__c, GW_Volunteers__Location__c, GW_Volunteers__Location_City__c, GW_Volunteers__Location_Information__c, GW_Volunteers__Location_Street__c, GW_Volunteers__Location_Zip_Postal_Code__c, GW_Volunteers__Ongoing__c, GW_Volunteers__Skills_Needed__c, Require_Liability_Waiver_Medical_Release__c FROM GW_Volunteers__Volunteer_Job__c WHERE Id=:jobId LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static List<GW_Volunteers__Volunteer_Shift__c> getFilteredShifts(String jobType, String city, Integer limitSize, Integer offset){
        if(jobType == '' && city == ''){    
            return [SELECT Id, GW_Volunteers__Description__c, GW_Volunteers__Desired_Number_of_Volunteers__c, GW_Volunteers__Duration__c, GW_Volunteers__Job_Location_City__c, GW_Volunteers__Job_Location_Street__c, GW_Volunteers__Number_of_Volunteers_Still_Needed__c, GW_Volunteers__Start_Date_Time__c, GW_Volunteers__System_Note__c, GW_Volunteers__Total_Volunteers__c, Name, GW_Volunteers__Volunteer_Job__r.Name FROM GW_Volunteers__Volunteer_Shift__c WHERE  GW_Volunteers__Start_Date_Time__c > Today ORDER BY GW_Volunteers__Start_Date_Time__c LIMIT :limitSize OFFSET :offset];
        } else if(jobType == ''){
            return [SELECT Id, GW_Volunteers__Description__c, GW_Volunteers__Desired_Number_of_Volunteers__c, GW_Volunteers__Duration__c, GW_Volunteers__Job_Location_City__c, GW_Volunteers__Job_Location_Street__c, GW_Volunteers__Number_of_Volunteers_Still_Needed__c, GW_Volunteers__Start_Date_Time__c, GW_Volunteers__System_Note__c, GW_Volunteers__Total_Volunteers__c, Name, GW_Volunteers__Volunteer_Job__r.Name FROM GW_Volunteers__Volunteer_Shift__c WHERE GW_Volunteers__Job_Location_City__c=:city AND GW_Volunteers__Start_Date_Time__c > Today ORDER BY GW_Volunteers__Start_Date_Time__c LIMIT :limitSize OFFSET :offset];
        } else if(city == ''){
            return [SELECT Id, GW_Volunteers__Description__c, GW_Volunteers__Desired_Number_of_Volunteers__c, GW_Volunteers__Duration__c, GW_Volunteers__Job_Location_City__c, GW_Volunteers__Job_Location_Street__c, GW_Volunteers__Number_of_Volunteers_Still_Needed__c, GW_Volunteers__Start_Date_Time__c, GW_Volunteers__System_Note__c, GW_Volunteers__Total_Volunteers__c, Name, GW_Volunteers__Volunteer_Job__r.Name FROM GW_Volunteers__Volunteer_Shift__c WHERE GW_Volunteers__Volunteer_Job__r.Type__c=:jobType AND GW_Volunteers__Start_Date_Time__c > Today ORDER BY GW_Volunteers__Start_Date_Time__c LIMIT :limitSize OFFSET :offset];
        } else {
            return [SELECT Id, GW_Volunteers__Description__c, GW_Volunteers__Desired_Number_of_Volunteers__c, GW_Volunteers__Duration__c, GW_Volunteers__Job_Location_City__c, GW_Volunteers__Job_Location_Street__c, GW_Volunteers__Number_of_Volunteers_Still_Needed__c, GW_Volunteers__Start_Date_Time__c, GW_Volunteers__System_Note__c, GW_Volunteers__Total_Volunteers__c, Name, GW_Volunteers__Volunteer_Job__r.Name FROM GW_Volunteers__Volunteer_Shift__c WHERE GW_Volunteers__Volunteer_Job__r.Type__c=:jobType AND GW_Volunteers__Job_Location_City__c=:city AND GW_Volunteers__Start_Date_Time__c > Today ORDER BY GW_Volunteers__Start_Date_Time__c LIMIT :limitSize OFFSET :offset];
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<GW_Volunteers__Volunteer_Shift__c> getJobShifts2(ID jobId, Integer limitSize, Integer offset) {
        return [SELECT Id, GW_Volunteers__Description__c, GW_Volunteers__Desired_Number_of_Volunteers__c, GW_Volunteers__Duration__c, GW_Volunteers__Job_Location_City__c, GW_Volunteers__Number_of_Volunteers_Still_Needed__c, GW_Volunteers__Start_Date_Time__c, GW_Volunteers__System_Note__c, GW_Volunteers__Total_Volunteers__c, Name FROM GW_Volunteers__Volunteer_Shift__c WHERE GW_Volunteers__Volunteer_Job__c=:jobId ORDER BY GW_Volunteers__Start_Date_Time__c LIMIT :limitSize OFFSET :offset];
    }

    @AuraEnabled(cacheable=true)
    public static List<GW_Volunteers__Volunteer_Hours__c> getContactHoursList(String contactId) {
        return [SELECT Id, GW_Volunteers__Comments__c, GW_Volunteers__Contact__c, GW_Volunteers__End_Date__c, GW_Volunteers__Full_Name__c, GW_Volunteers__Hours_Worked__c, GW_Volunteers__Number_of_Volunteers__c, GW_Volunteers__Planned_Start_Date_Time__c, GW_Volunteers__Shift_Start_Date_Time__c, GW_Volunteers__Start_Date__c, GW_Volunteers__Status__c, GW_Volunteers__Volunteer_Job__c, GW_Volunteers__Volunteer_Job__r.Name, GW_Volunteers__Volunteer_Job__r.GW_Volunteers__Location_Street__c, GW_Volunteers__Volunteer_Job__r.GW_Volunteers__Location_City__c, GW_Volunteers__Volunteer_Job__r.GW_Volunteers__Location__c, GW_Volunteers__Volunteer_Job__r.GW_Volunteers__Location_Zip_Postal_Code__c  FROM GW_Volunteers__Volunteer_Hours__c WHERE GW_Volunteers__Contact__c=:contactId ORDER BY GW_Volunteers__Start_Date__c DESC  LIMIT 25];
    }

    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getCityList() {
        return [SELECT GW_Volunteers__Location_City__c, COUNT(Id) FROM GW_Volunteers__Volunteer_Job__c GROUP BY GW_Volunteers__Location_City__c ORDER BY GW_Volunteers__Location_City__c ASC ];
         
    }

    @AuraEnabled(cacheable=true)
    public static Contact getUserContact(String userId) {

        List<User> u = [SELECT Id, ContactId FROM User WHERE Id=:userId LIMIT 1];
        if(u.size() == 1){
            List<Contact> c = [SELECT Id, FirstName, LastName, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, HomePhone, MobilePhone, Email, GW_Volunteers__Volunteer_Notes__c, GW_Volunteers__Volunteer_Organization__c, GW_Volunteers__Volunteer_Skills__c, GW_Volunteers__Volunteer_Status__c, Volunteers_Medical_Conditions__c FROM Contact Where Id=:u[0].ContactId LIMIT 1];
            if(c.size() == 1){
                return c[0];
            } else{
                return [SELECT Id, FirstName, LastName, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, HomePhone, MobilePhone, Email, GW_Volunteers__Volunteer_Notes__c, GW_Volunteers__Volunteer_Organization__c, GW_Volunteers__Volunteer_Skills__c, GW_Volunteers__Volunteer_Status__c, Volunteers_Medical_Conditions__c FROM Contact Where Id='003S000001j8BjyIAE' LIMIT 1];
            }
        } else {
            throw new AuraHandledException('Couldnt find a User for this user: ' + userId);

        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, ConnectApi.ManagedContentNodeValue> getCMSContent(
        String contentId,
        Integer page,
        Integer pageSize,
        String language,
        String filterby
    ) {
        try {
            String networkId = Network.getNetworkId();
            ConnectApi.ManagedContentVersionCollection contentCollection = ConnectApi.ManagedContent.getManagedContentByContentKeys(
                networkId,
                new List<String>{ contentId },
                0,
                1,
                language,
                filterby,
                false
            );
            return contentCollection.items[0].contentNodes;
        } catch (ConnectApi.ConnectApiException e) {
            System.debug('Error Message : ' + e);
            Map<String, ConnectApi.ManagedContentNodeValue> mcnvMap = new Map<String, ConnectApi.ManagedContentNodeValue>();
            return mcnvMap;
        }
    }
}