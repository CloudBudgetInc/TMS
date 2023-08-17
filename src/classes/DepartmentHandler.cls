/* **************************************************************************
* TriggerHandler Class: DepartmentHandler
* Created by lv@nubik.ca, 01/19/2017
*
* Purpose/Methods:
* - Implement the bussiness logic related to the object "Department"
*
* Unit Test: DepartmentHandlerTest
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
public class DepartmentHandler extends TriggerHandler
{
	List<AggregateResult> pInvoices;

	public DepartmentHandler()
	{
	}

	/**
	* @author lv@nubik.ca 
	* @date 01/23/2017
	* @description Prepare data for the bussiness logic execution
	*/
	public override void bulkBefore()
	{
		if (Trigger.isUpdate)
		{
			Set<Id> departments = new Set<Id>();
			for (Department__c dp : (List<Department__c>)Trigger.new)
			{
				if (dp.Calculate_Items_To_Approve_Manual__c != 
						((Department__c)Trigger.oldMap.get(dp.Id)).Calculate_Items_To_Approve_Manual__c && 
						dp.Calculate_Items_To_Approve_Manual__c == true)
				{
					departments.add(dp.Id);
				}
			}
			if (!departments.isEmpty())
			{
				pInvoices = [Select count(Id) nr, Department__c from 
						c2g__codaPurchaseInvoice__c where 
						Department__c in :departments and 
						Approval_Status__c = 'In Progress' group by Department__c];
			}
		}
	}

	/**
	* @author lv@nubik.ca 
	* @date 01/23/2017
	* @description Logic to execute before update
	*/
	public override void beforeUpdate()
	{
		if (pInvoices != null && pInvoices.size()>0)
			calculateItemsToApprove();
	}

	/**
	* @author lv@nubik.ca 
	* @date 01/23/2017
	* @description Calculate the items to approve, reset the field 
	* Calculate_Items_To_Approve_Manual__c to false
	*/
	private void calculateItemsToApprove()
	{
		
		for (AggregateResult invoice : pInvoices)
		{
			Id recordId = (Id)invoice.get('Department__c');
			Integer numberOfRecords = (Integer)invoice.get('nr');
			(Trigger.newMap.get(recordId)).put('Items_To_Approve_Manual__c',numberOfRecords);
			(Trigger.newMap.get(recordId)).put('Calculate_Items_To_Approve_Manual__c',false);
		}
	}
}