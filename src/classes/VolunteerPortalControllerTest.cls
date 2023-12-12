@isTest
public class VolunteerPortalControllerTest {
    
    @isTest
    private static void testGetJobsList() {
        Campaign c = new Campaign();
        c.Name = 'Test Campaign';
        insert c;
        GW_Volunteers__Volunteer_Job__c newJob = new GW_Volunteers__Volunteer_Job__c();
        newJob.Name = 'Test Job';
        newJob.GW_Volunteers__Display_on_Website__c = true;
        newJob.GW_Volunteers__Inactive__c = false;
        newJob.GW_Volunteers__Campaign__c = c.Id;
        insert newJob;

        // Call the method to test
        List<GW_Volunteers__Volunteer_Job__c> jobsList = VolunteerPortalController.getJobsList();

        // Assert that the returned data matches the inserted job
        System.assertEquals(1, jobsList.size());
        System.assertEquals('Test Job', jobsList[0].Name);
    }

    @isTest 
    private static void testGetjobDetails(){
        Campaign c = new Campaign();
        c.Name = 'Test Campaign';
        insert c;
        GW_Volunteers__Volunteer_Job__c newJob = new GW_Volunteers__Volunteer_Job__c();
        newJob.Name = 'Test Job';
        newJob.GW_Volunteers__Display_on_Website__c = true;
        newJob.GW_Volunteers__Inactive__c = false;
        newJob.GW_Volunteers__Campaign__c = c.Id;
        insert newJob;

        // Call the method to test
        GW_Volunteers__Volunteer_Job__c jobDetails = VolunteerPortalController.getJobDetails(newJob.Id);

        // Assert that the returned data matches the inserted job
        //System.assertEquals(1, jobDetails.size());
        System.assertEquals('Test Job', jobDetails.Name, 'jobDetails.Name didnt equal Test Job: ' + jobDetails.Name);

    }

    @isTest
    private static void testGetShiftsList(){
        Date tomorrow = Date.today().addDays(5);
        
        Campaign c = new Campaign();
        c.Name = 'Test Campaign';
        insert c;
        
        GW_Volunteers__Volunteer_Job__c newJob = new GW_Volunteers__Volunteer_Job__c();
        newJob.Name = 'Test Job';
        newJob.GW_Volunteers__Display_on_Website__c = true;
        newJob.GW_Volunteers__Inactive__c = false;
        newJob.GW_Volunteers__Campaign__c = c.Id;
        newJob.GW_Volunteers__Location_City__c = 'Calgary';
        newJob.Type__c = 'Kitchen';

        insert newJob;

        GW_Volunteers__Volunteer_Shift__c newShift = new 	GW_Volunteers__Volunteer_Shift__c();
        newShift.GW_Volunteers__Volunteer_Job__c = newJob.Id;
        newShift.GW_Volunteers__Duration__c = 1;
        newShift.GW_Volunteers__Start_Date_Time__c = tomorrow;
        insert newShift;

        // Call the method to test
        List<GW_Volunteers__Volunteer_Shift__c> shiftDetails = VolunteerPortalController.getShiftsList();

        System.assertEquals(shiftDetails.size(), 1);
        System.assertEquals(String.valueOf(newshift.Id), String.valueOf(shiftDetails[0].Id));

    }

    @isTest
    private static void testGetSkillsPicklistValues(){

        List<String> skills = VolunteerPortalController.getSkillsPicklistValues();

        System.Assert(skills.size() > 1, 'skills size is: ' + skills.size());
    }
    
    @isTest
    private static void testGetTypesPicklistValues(){

        List<String> types = VolunteerPortalController.getTypesPicklistValues();

        System.Assert(types.size() > 1, 'types size is: ' + types.size());
    }
}