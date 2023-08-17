/* **************************************************************************
* TriggerHandler Class: PayableInvoiceHandler
* Created by lv@nubik.ca, 01/19/2017
*
* Purpose/Methods:
* - Implement the bussiness logic related to the object "Payable Invoice"
*
* Unit Test: PayableInvoiceHandlerTest
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
public class PayableInvoiceHandler extends TriggerHandler
{
	//Payable invoices approval status
	static String IN_PROGRESS_STATUS = 'In Progress';
	List<Department__c> departments;
	public PayableInvoiceHandler(){}

	/**
	* @author lv@nubik.ca 
	* @date 01/23/2017
	* @description Prepare data for the bussiness logic execution
	*/
	public override void bulkAfter()
	{
		Set<Id> departments2Update = new Set<Id>();
		List<c2g__codaPurchaseInvoice__c> payableInvoices = null;
		if (Trigger.isDelete)
			payableInvoices = Trigger.old;
		else
			payableInvoices = Trigger.new;
		for (c2g__codaPurchaseInvoice__c pInvoice : payableInvoices)
		{
			//If the record is being inserted, deleted, undeleted or updated and the 
			//Approval status = 'In progress' the department is updated to calculate the items to approve
			if (pInvoice.Department__c != null && 
					pInvoice.Approval_Status__c == IN_PROGRESS_STATUS && 
					(Trigger.isInsert || Trigger.isDelete || Trigger.isUndelete || 
					(Trigger.isUpdate && pInvoice.Approval_Status__c != 
					((c2g__codaPurchaseInvoice__c)Trigger.oldMap.get(pInvoice.Id)).Approval_Status__c)))
			{
				departments2Update.add(pInvoice.Department__c);	
			}
			//If the record is updated, changing the value to the approval status from 'In progress' to 
			//something different, the previous department is updated to calculate the items to approve
			else if (Trigger.isUpdate && 
					((c2g__codaPurchaseInvoice__c)Trigger.oldMap.get(pInvoice.Id)).Department__c != null && 
					pInvoice.Approval_Status__c != 
					((c2g__codaPurchaseInvoice__c)Trigger.oldMap.get(pInvoice.Id)).Approval_Status__c && 
					((c2g__codaPurchaseInvoice__c)Trigger.oldMap.get(pInvoice.Id)).Approval_Status__c == 
					IN_PROGRESS_STATUS)
			{
				departments2Update.add(((c2g__codaPurchaseInvoice__c)Trigger.oldMap.get(pInvoice.Id)).Department__c);
			}
			//If the record is updated, changing the department and the precious or new value of the 
			//field Approval status is 'In progress'
			else if (Trigger.isUpdate && pInvoice.Department__c != 
					((c2g__codaPurchaseInvoice__c)Trigger.oldMap.get(pInvoice.Id)).Department__c && 
					(pInvoice.Approval_Status__c == IN_PROGRESS_STATUS ||  
					((c2g__codaPurchaseInvoice__c)Trigger.oldMap.get(pInvoice.Id)).Approval_Status__c == 
					IN_PROGRESS_STATUS))
			{
				//Validate if the department is not null
				if (((c2g__codaPurchaseInvoice__c)Trigger.oldMap.get(pInvoice.Id)).Department__c!= null)
					departments2Update.add(((c2g__codaPurchaseInvoice__c)Trigger.oldMap.get(pInvoice.Id)).Department__c);
				if (pInvoice.Department__c != null)
					departments2Update.add(pInvoice.Department__c);
			}
		}
		if (!departments2Update.isEmpty())
		{
			//Get the departments to update
			departments = [Select Id,Calculate_Items_To_Approve_Manual__c from 
					Department__c where Id in: departments2Update];
		}
	}

	/**
	* @author lv@nubik.ca
	* @date 01/23/2017
	* @description Logic related to execute after the records are inserted
	*/
	public override void afterInsert()
	{
		calculateItemsToApprove();
	}

	/**
	* @author lv@nubik.ca
	* @date 01/23/2017
	* @description Logic related to execute after the records are updated
	*/
	public override void afterUpdate()
	{
		calculateItemsToApprove();
	}

	/**
	* @author lv@nubik.ca
	* @date 01/23/2017
	* @description Logic related to execute after the records are deleted
	*/
	public override void afterDelete()
	{
		calculateItemsToApprove();
	}

	/**
	* @author lv@nubik.ca
	* @date 01/23/2017
	* @description Logic related to execute after the records are undeleted
	*/
	public override void afterUndelete()
	{
		calculateItemsToApprove();
	}

	/**
	* @author lv@nubik.ca
	* @date 01/23/2017
	* @description Execute all the DML operations
	*/
	public override void finalActions()
	{
		//Update the departments related to the payable invoices
		if (departments != null && departments.size() > 0)
			update departments;
	}

	/**
	* @author lv@nubik.ca
	* @date 01/23/2017
	* @description Update the Department field "Calculate_Items_To_Approve_Manual__c" 
	* to calculate on the trigger in department the number of records with 
	* Approval Status = 'In Progress'
	*/
	private void calculateItemsToApprove()
	{
		if (departments != null && departments.size() > 0)
		{
			for (Department__c dp : departments)
			{
				//the true value for "Calculate_Items_To_Approve_Manual__c" trigger 
				//the deparment calculation
				dp.Calculate_Items_To_Approve_Manual__c = true;
			}
		}
	}
}