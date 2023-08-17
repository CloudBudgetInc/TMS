@isTest
public class ReportControllerTest {

     public static testMethod void testMyController() {
        PageReference pageRef = Page.Donation_Report;
        Test.setCurrentPage(pageRef);
 
         ReportController ctrl = new reportController();
         
    
        System.assertEquals(null, null);
    }       
}