/* **************************************************************************
* Helper Class: SalesInvoiceLineItemHandler
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
public class SalesInvoiceLineItemHandler extends TriggerHandler{

	/**
	* @author jm@nubik.ca 
	* @date 02/01/2017
	* @description Logic for the Before Update event
	*/
	public override void beforeUpdate()
	{
		SalesInvoiceLineItemHelper.clearOriginalUnitPrice((list<c2g__codaInvoiceLineItem__c>) trigger.new,  (map<Id, c2g__codaInvoiceLineItem__c>) trigger.oldMap);
	}


}