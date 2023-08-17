/** Copyright 2020, Aria Solutions Inc.
 *
 * All Rights Reserved
 * Customers of Aria Solutions are permitted to use and modify this 
 * code in all of their Salesforce Orgs (Production, Sandboxes), but 
 * any form of distribution to other Salesforce Orgs not belonging to 
 * the customer require a written permission from Aria Solutions.
 * Created on 22-Oct-20. 
 */

public class DuplicateRecordsListController {
  public List <Contact> contacts {get;set;}
  public Boolean showResults {get; set;}
  public Date startDate {get; set;}
  public Date endDate {get; set;}
  public limitWrapper[] thousandBlocks {get; set;}
  private final integer listLimit;

  public DuplicateRecordsListController(){
    showResults = false;
    listLimit = 999;
    contacts = new List<Contact>();
    thousandBlocks = new limitWrapper[]{};
  }

  public Pagereference searchContacts()  {
    showResults = true;
    List<Account> generatedAnonymouseAccounts = [select Id, Name, npe01__One2OneContact__c  from Account where Name = 'Anonymous Household' and CreatedDate >= :startDate and CreatedDate <= :endDate];
    System.debug('Found anonymous accounts: ' + generatedAnonymouseAccounts.size());

    List<Id> primaryContactIds = new List<Id>();

    for (Account acct : generatedAnonymouseAccounts) {
      primaryContactIds.add(acct.npe01__One2OneContact__c);
    }

    System.debug('Primary contacts: ' + primaryContactIds);
    System.debug('---------------------------------');

    List<Contact> primaryContacts = [select Id, Name, Type__c, AccountId, Account.Name from Contact where Id in :primaryContactIds];
    List<Id> accountsIds = new List<Id>();

    for (Contact con : primaryContacts) {
      accountsIds.add(con.AccountId);
    }
    List<Contact> allContacts = [select Id, Name, Type__c, CreatedDate, Account.Name from Contact where AccountId in :accountsIds limit 1000];

    System.debug('All contacts: ' + allContacts.size());
    contacts = allContacts;
    getBlocks();
    System.debug('thousandBlocks: ' + thousandBlocks);
    System.debug('thousandBlocks size: ' + thousandBlocks.size());
    return null;
  }

  public PageReference getNextBlock() {
    return null;
  }

  private void getBlocks() {
    thousandBlocks = new limitWrapper[]{};

    integer counter = 0;
    integer loopCount = 0;
    List<Contact> tmpContacts = new List<Contact>();

    System.debug('contacts: ' + contacts);
    if (contacts.size() > 0)  {
      for(Contact c: contacts) {
        if(counter < listLimit)
        {
          tmpContacts.add(c);
          counter++;
        }
        else
        {
          loopCount++;
          thousandBlocks.add(new limitWrapper(tmpContacts,loopCount));
          tmpContacts = new List<Contact>();
          tmpContacts.add(c);
          counter = 0;
        }
      }
    }
    System.debug('tmpContacts: ' + tmpContacts);

    if(thousandBlocks.size() == 0) {
      loopCount++;
      thousandBlocks.add(new limitWrapper(tmpContacts,loopCount));
    }
  }

  public class limitWrapper {
    public List<Contact> contacts {get;set;}
    public integer blockNumber {get;set;}
    public limitWrapper(List<Contact> accs, integer i) {
      contacts = accs;
      blockNumber = i;
    }

  }
}