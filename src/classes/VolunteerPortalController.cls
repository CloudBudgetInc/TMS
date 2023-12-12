public with sharing class VolunteerPortalController {
    
    @AuraEnabled(cacheable=true)
    public static List<GW_Volunteers__Volunteer_Job__c> getJobsList() {
        return [SELECT Id, Name, GW_Volunteers__Location_City__c FROM GW_Volunteers__Volunteer_Job__c WHERE GW_Volunteers__Display_on_Website__c=True AND GW_Volunteers__Inactive__c=False LIMIT 10];
    }

    @AuraEnabled(cacheable=true)
    public static GW_Volunteers__Volunteer_Job__c getJobDetails(ID jobId) {
        return [SELECT Id, Name, GW_Volunteers__Description__c, GW_Volunteers__Display_on_Website__c, GW_Volunteers__Inactive__c, GW_Volunteers__Location__c, GW_Volunteers__Location_City__c, GW_Volunteers__Location_Information__c, GW_Volunteers__Location_Street__c, GW_Volunteers__Location_Zip_Postal_Code__c, GW_Volunteers__Ongoing__c, GW_Volunteers__Skills_Needed__c, Require_Liability_Waiver_Medical_Release__c FROM GW_Volunteers__Volunteer_Job__c WHERE Id=:jobId LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static List<GW_Volunteers__Volunteer_Shift__c> getShiftsList() {
        return [SELECT Id, Name, GW_Volunteers__Description__c, GW_Volunteers__Start_Date_Time__c, 
                       GW_Volunteers__Total_Volunteers__c, GW_Volunteers__Desired_Number_of_Volunteers__c, 
                       GW_Volunteers__Job_Location_City__c, GW_Volunteers__Duration__c,
                       GW_Volunteers__Volunteer_Job__c,
                       GW_Volunteers__Volunteer_Job__r.Name,
                       GW_Volunteers__Volunteer_Job__r.GW_Volunteers__Display_on_Website__c,
                       GW_Volunteers__Volunteer_Job__r.GW_Volunteers__Inactive__c,
                       GW_Volunteers__Volunteer_Job__r.GW_Volunteers__Skills_Needed__c,
                        GW_Volunteers__Volunteer_Job__r.Type__c
                FROM GW_Volunteers__Volunteer_Shift__c 
                WHERE GW_Volunteers__Volunteer_Job__r.GW_Volunteers__Display_on_Website__c = true 
                AND GW_Volunteers__Volunteer_Job__r.GW_Volunteers__Inactive__c = false];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getSkillsPicklistValues() {
        List<String> picklistValuesList = new List<String>();
        Schema.DescribeFieldResult fieldResult = GW_Volunteers__Volunteer_Job__c.GW_Volunteers__Skills_Needed__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            picklistValuesList.add(entry.getLabel());
        }
        return picklistValuesList;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getTypesPicklistValues() {
        List<String> picklistValuesList = new List<String>();
        Schema.DescribeFieldResult fieldResult = GW_Volunteers__Volunteer_Job__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            picklistValuesList.add(entry.getLabel());
        }
        return picklistValuesList;
    }

}