@isTest
public class IsIDUniqueUndertheAppealTest {
    
    @isTest static void TestTest() {
        String err;
        
        List<Campaign> Camps = new List<Campaign> {new Campaign(Name='Campaign 1'), new Campaign(Name='Campaign 2')};
        upsert Camps;
        
        Test.startTest();
        
        Package__c NewPack = new Package__c();
        NewPack.name='werw';
        NewPack.Package_ID__c='Q123';
        NewPack.Package_Type__c='Direct Response';
        NewPack.Campaign_Appeal__c=Camps[0].Id;
        
        try {
            err='';
        	upsert(NewPack);
        } catch(System.DMLException e) {
            err=e.getDmlMessage(0);
        }
        // No errors with creating the Package
        System.assertEquals(err,'');
        
        Package__c NewPack2 = new Package__c();
        NewPack2.name='wrew';
        NewPack2.Package_ID__c='Q123';
        NewPack2.Package_Type__c='Direct Response';
        NewPack2.Campaign_Appeal__c=Camps[1].Id;
        
        try {
            err='';
        	upsert(NewPack2);
        } catch(System.DMLException e) {
            err=e.getDmlMessage(0);
        }       
        // No error with creating same package for another Appeal
        System.assertEquals(err,'');
        
        Package__c NewPack1 = new Package__c();
        NewPack1.name='weww';
        NewPack1.Package_ID__c='Q123';
        NewPack1.Package_Type__c='Direct Response';
        NewPack1.Campaign_Appeal__c=Camps[0].Id;
        
        try {
            err='';
            upsert(NewPack1);
        } catch(System.DMLException e) {
            err=e.getDMLMessage(0);
        }       
        // At last get the error when create package with same Package_ID...
        System.assertEquals(err,'Package with same Package ID already exists under current Appeal!');
        Test.stopTest();        
    }
    
}