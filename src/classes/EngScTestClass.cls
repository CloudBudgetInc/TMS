@isTest
public class EngScTestClass {	
    
    @testSetup
    static void setup(){
        // Create a dummy account for testing
        Account acc = new Account(Name = 'johntestaccount', Officer_Rating__c = '10',npo02__Informal_Greeting__c = 'Jamoy',	npo02__LastCloseDate__c = System.today());
        insert acc;        
    }
    
	@isTest
    static void testRFMValues(){
        
        // Can't just assign it to an account. Have to assign to list of account and access each
        List<Account> testAcc = [SELECT ID FROM Account WHERE ID='0013g00000Aw06xAAB'];
        
        System.assertEquals(1,testAcc.size());
    }

}