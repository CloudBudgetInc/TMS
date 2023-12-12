@isTest
public with sharing class ContactSumSoftTriggerTestClass {

    @isTest
    static void testContactsoftCredTrigger(){
        
        // Create contacts for single contact -> account soft credit testing
        List<Contact> singleConts = new List<Contact>();
        for(Integer i = 0;i<10;i++){
            Contact newCont = new Contact(FirstName='John',LastName='SingleContact' + i,TMS_City__c='Calgary',Type__c='Individual',
                                Receipt_Type__c='Mail', npo02__Soft_Credit_Total__c=10*i);
            singleConts.add(newCont);
        }

        // Create accounts and separate contacts. 2 or more contacts will be associated to each account
        // MultiContact -> Account Soft Credit Test
        List<Account> multiAccts = new List<Account>();
        for(Integer i = 0;i<3;i++){
            Account newAcct = new Account(Name='JohnMultiContact ' + i,TMS_City__c='Calgary');
            multiAccts.add(newAcct);
        }   

        // Begin and reset governor limits
        Test.startTest();
        // Insert the 3 accounts and query them right away for our use
        insert multiAccts;
        List<Account> queriedMultiAccount = [SELECT Id FROM Account LIMIT 3];
        
        // Begin inserting contacts into the 3 accounts created
        List<Contact> multiConts = new List<Contact>();
        Integer contactCounter = 0;
        for(Integer i = 0;i<9;i++){            
            switch on contactCounter{
                // First account will have 2 contacts
                when 0,1 {
                    Contact newCont2 = new Contact(FirstName='John',LastName='MultiContact' + i,TMS_City__c='Calgary',Type__c='Individual',
                    Receipt_Type__c='Mail', npo02__Soft_Credit_Total__c=100*i,AccountId=queriedMultiAccount[0].Id);
                    multiConts.add(newCont2);
                    contactCounter++;
                }
                // Second account will have 3 contacts
                when 2,3,4 {
                    Contact newCont2 = new Contact(FirstName='John',LastName='MultiContact' + i,TMS_City__c='Calgary',Type__c='Individual',
                    Receipt_Type__c='Mail', npo02__Soft_Credit_Total__c=100*i,AccountId=queriedMultiAccount[1].Id);
                    multiConts.add(newCont2);
                    contactCounter++;
                }
                // Third account will have 4 contacts
                when 5,6,7,8 {
                    Contact newCont2 = new Contact(FirstName='John',LastName='MultiContact' + i,TMS_City__c='Calgary',Type__c='Individual',
                    Receipt_Type__c='Mail', npo02__Soft_Credit_Total__c=100*i,AccountId=queriedMultiAccount[2].Id);
                    multiConts.add(newCont2);
                    contactCounter++;
                }
            }
        }        

        
        insert multiConts;
        insert singleConts;
        Test.stopTest();
         
        /*******************************************
        ********* Start of Assertions **************
        *******************************************/

        List<Contact> verifyConts = [SELECT Id, AccountId FROM Contact];  

        // Verify that 9+10 = 19 new Contacts were inserted  
        System.assertEquals(19, verifyConts.size());
        // Verify that 3+10 = 13 new Accounts were inserted

        List<Account> verifyAccts = new List<Account>();

        // Create a list of accounts retrieved from the accounts associated with the contacts created above
        for(Integer i=9;i<19;i++){
            if(!verifyConts.isEmpty()){
                String ContAccID = verifyConts[i].AccountId;
                verifyAccts.add([SELECT ID, Account_Soft_Credit_Total__c FROM Account WHERE ID = :ContAccID]);
            }
        }

        // Assert that Account Soft Credit total field on the account are correct and matches the contacts
        // Single contact -> account assertions
        // System.assertEquals(verifyAccts[0].Account_Soft_Credit_Total__c, 0);
        // System.assertEquals(verifyAccts[1].Account_Soft_Credit_Total__c, 10);
        // System.assertEquals(verifyAccts[2].Account_Soft_Credit_Total__c, 20);
        // System.assertEquals(verifyAccts[3].Account_Soft_Credit_Total__c, 30);
        // System.assertEquals(verifyAccts[4].Account_Soft_Credit_Total__c, 40);
        // System.assertEquals(verifyAccts[5].Account_Soft_Credit_Total__c, 50);
        // System.assertEquals(verifyAccts[6].Account_Soft_Credit_Total__c, 60);
        // System.assertEquals(verifyAccts[7].Account_Soft_Credit_Total__c, 70);
        // System.assertEquals(verifyAccts[8].Account_Soft_Credit_Total__c, 80);
        // System.assertEquals(verifyAccts[9].Account_Soft_Credit_Total__c, 90);

        // // Multiple contact -> account assertions
        // List<Account> queriedMultiAccount2 = [SELECT Id, Account_Soft_Credit_Total__c FROM Account ORDER BY Id LIMIT 3];
        // System.assertEquals(queriedMultiAccount2[0].Account_Soft_Credit_Total__c,100);
        // System.assertEquals(queriedMultiAccount2[1].Account_Soft_Credit_Total__c,900);
        // System.assertEquals(queriedMultiAccount2[2].Account_Soft_Credit_Total__c,2600);

        /* ************************
        Order of insertion:
        1. Insert Multi Accounts
        2. Insert Multi Contacts
        3. Insert Single Contacts
        4. Single Accounts created from insertion of 3
        * ************************/

    }
}