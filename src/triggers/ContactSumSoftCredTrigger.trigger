trigger ContactSumSoftCredTrigger on Contact (after delete, after insert, after undelete, after update) {

// List of contacts
Contact[] cons;

if (Trigger.isDelete) 
    cons = Trigger.old; // returns old sObjects
else
    cons = Trigger.new; // returns new sObjects

Set<ID> acctIds = new Set<ID>(); // create a set of ACC IDs

for (Contact con : cons) {
   acctIds.add(con.AccountId);
}

Map<ID, Contact> contactsForAccounts = new Map<ID, Contact>([SELECT Id ,AccountId, npo02__Soft_Credit_Total__c FROM Contact WHERE AccountId IN :acctIds]);

Map<ID, Account> acctsToUpdate = new Map<ID, Account>([SELECT Id, Account_Soft_Credit_Total__c FROM Account WHERE Id IN :acctIds]);

for (Account acct : acctsToUpdate.values()) {
    Set<Id> conIds = new Set<Id>();
    Decimal totalValue = 0;
    for (Contact con : contactsForAccounts.values()) {
        if (con.AccountId == acct.Id && con.npo02__Soft_Credit_Total__c != NULL) {
            totalValue += con.npo02__Soft_Credit_Total__c; 
        }
    }
    acct.Account_Soft_Credit_Total__c = totalValue;
}
if(acctsToUpdate.values().size() > 0) {
    update acctsToUpdate.values();
}
}