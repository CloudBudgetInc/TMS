trigger ContSumSoftCrVolHrsTrigger on Contact (after delete, after insert, after undelete, after update) {

    // List of contacts
    Contact[] cons;

    if (Trigger.isDelete) 
        cons = Trigger.old; // If operations is delete returns old sObjects
    else
        cons = Trigger.new; // else returns new sObjects

    // create a set of ACC IDs to store the accs of the contacts. We use set data type bc it can only contain unique values
    Set<ID> acctIds = new Set<ID>(); 

    // Add to list of accounts the accounts of each contact
    for (Contact con : cons) {
        acctIds.add(con.AccountId);
    }

    // Get contact records and associate them with Account IDs
    Map<ID, Contact> contactsForAccounts = new Map<ID, Contact>([SELECT Id ,AccountId, npo02__Soft_Credit_Total__c, GW_Volunteers__Volunteer_Hours__c 
                                                FROM Contact WHERE AccountId IN :acctIds]);
    // Get account records and associate them with Account IDs
    Map<ID, Account> acctsToUpdate = new Map<ID, Account>([SELECT Id, Account_Soft_Credit_Total__c, Account_Total_Volunteer_Hours__c 
                                                FROM Account WHERE Id IN :acctIds]);

    // Start adding contacts' soft credit to accounts' soft credits if their accIDs match
    for (Account acct : acctsToUpdate.values()) {

        Set<Id> conIds = new Set<Id>();

        // Declare total value holders
        Decimal totalValue = 0;
        Decimal totalVolunteer = 0;

        for (Contact con : contactsForAccounts.values()) {
            // Add contact's soft credit to Account's total soft credit if the contact's and account's IDs are equal (and soft cred != null)
            if (con.AccountId == acct.Id && con.npo02__Soft_Credit_Total__c != NULL) {
                totalValue += con.npo02__Soft_Credit_Total__c; 
            }
            // Add volunteer hours to total volunteer hours same logic as above
            if (con.AccountId == acct.Id && con.GW_Volunteers__Volunteer_Hours__c != NULL) {
                totalVolunteer += con.GW_Volunteers__Volunteer_Hours__c; 
            }
        }
        acct.Account_Soft_Credit_Total__c = totalValue;
        acct.Account_Total_Volunteer_Hours__c = totalVolunteer;
    }
    // update if there is something to update
    if(acctsToUpdate.values().size() > 0) {
        update acctsToUpdate.values();
    }
}