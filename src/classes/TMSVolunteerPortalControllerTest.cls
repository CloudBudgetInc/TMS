@isTest
public class TMSVolunteerPortalControllerTest {

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
        List<GW_Volunteers__Volunteer_Job__c> jobsList = TMSVolunteerPortalController.getJobsList();

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
        GW_Volunteers__Volunteer_Job__c jobDetails = TMSVolunteerPortalController.getJobDetails(newJob.Id);

        // Assert that the returned data matches the inserted job
        //System.assertEquals(1, jobDetails.size());
        System.assertEquals('Test Job', jobDetails.Name, 'jobDetails.Name didnt equal Test Job: ' + jobDetails.Name);

    }

    // getFilteredShifts
    @isTest
    private static void testGetFilteredShiftsTypeANDCity() {
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
        List<GW_Volunteers__Volunteer_Shift__c> shiftDetails = TMSVolunteerPortalController.getFilteredShifts('Kitchen', 'Calgary', 1, 0);
        List<GW_Volunteers__Volunteer_Shift__c> shiftDetails2 = TMSVolunteerPortalController.getFilteredShifts('', '', 1, 0);        
        List<GW_Volunteers__Volunteer_Shift__c> shiftDetails3 = TMSVolunteerPortalController.getFilteredShifts('Kitchen', '', 1, 0);
        List<GW_Volunteers__Volunteer_Shift__c> shiftDetails4 = TMSVolunteerPortalController.getFilteredShifts('', 'Calgary', 1, 0);        

        System.assertEquals(shiftDetails.size(), 1);
        System.assertEquals(String.valueOf(newshift.Id), String.valueOf(shiftDetails[0].Id));

        System.assertEquals(shiftDetails2.size(), 1);
        System.assertEquals(String.valueOf(newshift.Id), String.valueOf(shiftDetails2[0].Id));

        System.assertEquals(shiftDetails3.size(), 1);
        System.assertEquals(String.valueOf(newshift.Id), String.valueOf(shiftDetails3[0].Id));

        System.assertEquals(shiftDetails4.size(), 1);
        System.assertEquals(String.valueOf(newshift.Id), String.valueOf(shiftDetails4[0].Id));

    }
    
    @isTest
    private static void testGetJobShifts2(){
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
        List<GW_Volunteers__Volunteer_Shift__c> shiftDetails = TMSVolunteerPortalController.getJobShifts2(newJob.Id, 1, 0);

        System.assertEquals(shiftDetails.size(), 1);
        System.assertEquals(String.valueOf(newshift.Id), String.valueOf(shiftDetails[0].Id));

    }

    @isTest
    private static void testGetContactHoursList(){
        Date tomorrow = Date.today().addDays(5);
        
        Contact cont = new Contact();
        cont.FirstName = 'TestContact';
        cont.LastName = 'TestContact';
        insert cont;

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

        GW_Volunteers__Volunteer_Shift__c newShift = new GW_Volunteers__Volunteer_Shift__c();
        newShift.GW_Volunteers__Volunteer_Job__c = newJob.Id;
        newShift.GW_Volunteers__Duration__c = 1;
        newShift.GW_Volunteers__Start_Date_Time__c = tomorrow;
        insert newShift;

        GW_Volunteers__Volunteer_Hours__c newHours = new GW_Volunteers__Volunteer_Hours__c();
        newHours.GW_Volunteers__Volunteer_Job__c = newJob.Id;
        newHours.GW_Volunteers__Volunteer_Shift__c = newShift.Id;
        newHours.GW_Volunteers__Status__c = 'Confirmed';
        newHours.GW_Volunteers__Start_Date__c = tomorrow;
        newHours.GW_Volunteers__Contact__c = cont.Id;
        insert newHours;

        // Call the method to test
        List<GW_Volunteers__Volunteer_Hours__c> contactHours = TMSVolunteerPortalController.getContactHoursList(cont.Id);
        
        System.assertEquals(contactHours.size(), 1);
        System.assertEquals(String.valueOf(newHours.Id), String.valueOf(contactHours[0].Id));

    }

    @isTest
    private static void testGetCityList(){

        Date tomorrow = Date.today().addDays(5);
        
        Contact cont = new Contact();
        cont.FirstName = 'TestContact';
        cont.LastName = 'TestContact';
        insert cont;

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

        List<AggregateResult> cities = TMSVolunteerPortalController.getCityList();

        System.Assert(cities.size() == 1, 'cities size is: ' + cities.size());
    }

    @isTest
    private static void testGetUserContact(){
       
        Id p = [select id from profile where name='Volunteer Portal User'].id;

        Account ac = new Account(name ='Grazitti') ;
        insert ac; 

        Contact con = new Contact(LastName ='testCon',AccountId = ac.Id);
        insert con;  
                
        User user = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true,
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username='tmstester1@noemail.com');

        insert user;
        
        Contact c = TMSVolunteerPortalController.getUserContact(user.Id);

        System.Assert(c.Id == con.Id);
    }

    @isTest
    private static void testFailGetUserContact(){
       
        Id p = [select id from profile where name='Volunteer Portal User'].id;

        Account ac = new Account(name ='Grazitti') ;
        insert ac; 

        Contact con = new Contact(LastName ='testCon',AccountId = ac.Id);
        insert con;  
                
        User user = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true,
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username='tmstester2@noemail.com');

        insert user;
        
        AuraHandledException thisException;
        
        try {
            Contact fake = TMSVolunteerPortalController.getUserContact('003abc');
        } catch (AuraHandledException exp) {
            thisException = exp;
        }

        System.assertEquals('Script-thrown exception', thisException.getMessage(), 'Exceptions should be handled by the method');
    }

    @isTest(seeAllData=true)
    private static void testGetCMSContent() {
        // Arrange
        TMSVolunteerPortalController portalController = new TMSVolunteerPortalController();
        Contact volunteer = new Contact(
            FirstName = 'Test',
            LastName = 'Volunteer',
            Email = 'test@example.com'
        );
        insert volunteer;

        Map<String, ConnectApi.ManagedContentNodeValue> content = TMSVolunteerPortalController.getCMSContent('', 1 , 1, 'US/Eng', '');
        
        System.assert(content != null, 'Found content: ' + content);
    }
}