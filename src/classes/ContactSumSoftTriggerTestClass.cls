@isTest
public with sharing class ContactSumSoftTriggerTestClass {

    @isTest
    static void testContactsoftCredTrigger(){
        
        List<Contact> conts = new List<Contact>();
        for(Integer i = 0;i<100;i++){
            Contact newCont = new Contact(FirstName='John',LastName='TestContact ' + i,TMS_City__c='Calgary',Type__c='Individual',Receipt_Type__c='Mail', npo02__Soft_Credit_Total__c=10000);
            conts.add(newCont);
        }

        Test.startTest();
        insert conts;
        Test.stopTest();

        // Verify that 100 new Accounts were inserted
        List<Contact> verifyConts = [SELECT Id FROM Contact];
        System.assertEquals(200, verifyConts.size());  


    }
}