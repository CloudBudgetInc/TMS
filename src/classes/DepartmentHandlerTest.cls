/* **************************************************************************
* Test Class: DepartmentHandlerTest
* Created by lv@nubik.ca, 01/19/2017
*
* Purpose/Methods:
* - Implement the Unit test for the trigger DepartmentTrigger and class 
* DepartmentHandler
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
@isTest(SeeAllData=true)
private class DepartmentHandlerTest 
{
	static testmethod void calculateItemsToApprove_Insert_Test()
	{
		List<User> users = TestDataFactory.createUsers(3);
		List<Department__c> departments = TestDataFactory.createDepartment(1,users[0].Id,
				users[1].Id,users[2].Id);
		List<Account> accounts = TestDataFactory.createAccounts(1);
		List<c2g__codaPurchaseInvoice__c> pInv = 
				TestDataFactory.createPayableInvoices(1,accounts[0].Id,departments[0].Id);
		List<Department__c> deps = [Select Id,Items_To_Approve_Manual__c from 
				Department__c where id =:departments[0].Id];
        System.debug('::::' + deps);
		System.assert(deps[0].Items_To_Approve_Manual__c == null);
		List<c2g__codaPurchaseInvoiceLineItem__c> lineItems = 
				TestDataFactory.createPayableInvoiceLineItems(1,pInv[0].Id);
		Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitrequest();
		app.setObjectId(pInv[0].Id);
		Approval.ProcessResult result = Approval.process(app);
		List<Department__c> dList = [Select Items_To_Approve_Manual__c,
				Calculate_Items_To_Approve_Manual__c from Department__c 
				where Id =: deps[0].Id];
		System.assert(dList[0].Items_To_Approve_Manual__c == 1);
		System.assert(dList[0].Calculate_Items_To_Approve_Manual__c == false);
	}
}