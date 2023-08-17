@isTest
public class ForecastUpdate_TEST {

    @isTest(SeeAllData=true) static void TestForecastUpdate() {
        
        List<npsp__Batch__c> BRL = new List<npsp__Batch__c>();
        
        Test.startTest();
       
        Test.setCurrentPage(Page.ForecastUpdate);
		ApexPages.currentPage().getParameters().put('retURL','/a0M/o');
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(BRL);
       
        
		ForecastUpdate FU= new ForecastUpdate(con);
        FU.CSYear='u2020';
        FU.CSPeriod='001';
        FU.updateParameterChanges();
        FU.CSYear='2020';
        FU.CSPeriod='u001';
        FU.updateParameterChanges();
        FU.CSYear='200';
        FU.CSPeriod='001';
        FU.updateParameterChanges();
        FU.CSYear='2020';
        FU.CSPeriod='100';
        FU.updateParameterChanges();
        FU.CSYear='2017';
        FU.CSPeriod='012';
        FU.updateParameterChanges();
        
        FU.updateBalances();

 		Test.stopTest();        
     }
}