/* **************************************************************************
* Helper Class: PayableInvoiceExpenseLineItemHelper
* Created by jm@nubik.ca, 02/01/2017
*
* Purpose/Methods:
* - Support with busniess logic for Sales Invoices Line Items
*
* Unit Test:
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
public class PayableInvoiceExpenseLineItemHelper {

	/**
	* @author jm@nubik.ca 
	* @date 02/01/2017
	* @description If the field Unit Price changes from a place that is not the Tax Calculation page, we will clear
	*	the original unit price field, so when taxes are calculated we can use the new value for the calculation
	*/
	public static void clearOriginalBaseNetValue(list<c2g__codaPurchaseInvoiceExpenseLineItem__c> newValues, map<Id, c2g__codaPurchaseInvoiceExpenseLineItem__c> oldValues)
	{
		//if this variable is false, it means we are updating from the Tax Calculation Page,
		//If it's true then we are updating somewhere else and we must clear the value.
		if(PayableInvoiceHelper.clearPayableInvoiceOriginalNetValue)
		{
			for(c2g__codaPurchaseInvoiceExpenseLineItem__c newValue: newValues)
			{
				c2g__codaPurchaseInvoiceExpenseLineItem__c oldValue = oldValues.get(newValue.id);
				if(newValue.c2g__NetValue__c != oldValue.c2g__NetValue__c)
				{
					newValue.Original_Net_Value__c = null;
				}
			}
		
		}
	}
}