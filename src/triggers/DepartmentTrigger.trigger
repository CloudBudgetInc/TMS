/* **************************************************************************
* Trigger: DepartmentTrigger
* Created by lv@nubik.ca, 01/19/2017
*
* Purpose:
* - Department object implementations
*
* Unit Test: DepartmentHandlerTest
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
trigger DepartmentTrigger on Department__c (before insert, 
		before update, before delete, after insert, after update, after delete,
		after undelete)  
{
	new DepartmentHandler().run();
}