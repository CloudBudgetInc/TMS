/* **************************************************************************
* Trigger: PayableInvoiceTrigger
* Created by lv@nubik.ca, 01/19/2017
*
* Purpose:
* - Payable Invoice implementations
*
* Unit Test: PayableInvoiceHandlerTest
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} � {Description of changes made post deployment to client}
*
************************************************************************** */
trigger PayableInvoiceTrigger on c2g__codaPurchaseInvoice__c (before insert, 
		before update, before delete, after insert, after update, after delete,
		after undelete)
{
	new PayableInvoiceHandler().run();	
}