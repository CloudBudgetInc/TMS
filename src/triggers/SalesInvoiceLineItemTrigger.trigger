/* **************************************************************************
* Trigger: SalesInvoiceLineItemTrigger
* Created by jm@nubik.ca, 02/01/2017
*
* Purpose:
* - c2g__codaInvoiceLineItem__c object implementations
*
* Unit Test: DepartmentHandlerTest
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
trigger SalesInvoiceLineItemTrigger on c2g__codaInvoiceLineItem__c (before insert, 
		before update, before delete, after insert, after update, after delete,
		after undelete)  {
	new SalesInvoiceLineItemHandler().run();

 }