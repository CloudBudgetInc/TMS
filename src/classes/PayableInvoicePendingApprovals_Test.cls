@isTest(SeeAllData=true)
public class PayableInvoicePendingApprovals_Test {
@isTest(SeeAllData=true)
    static void executeTest(){
        
        String CRON_EXP = '0 0 0 15 3 ? *';
        
        Test.startTest();

        	PayableInvoicePendingApprovals pa = new PayableInvoicePendingApprovals();
            String jobId = System.schedule('ScheduleApexClassTest',  CRON_EXP, pa);
        
        
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
        
     }    
}