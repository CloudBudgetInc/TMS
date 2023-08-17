/**
* @description Test class for AnnotationFieldController
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
@isTest private class AnnotationFieldController_Test 
{
	@isTest private static void AccountTest() 
	{
		Account anAccount = (Account) TestFactory.createSObject(new Account());
		insert anAccount;

		ApexPages.StandardController accountStandardController = new ApexPages.StandardController(anAccount);

		Test.startTest();

		PageReference accountAnnotationPageRef = Page.AccountAnnotation;
		Test.setCurrentPage(accountAnnotationPageRef);
		
		AnnotationFieldController accountAnnotationFieldController = new AnnotationFieldController(accountStandardController);
		System.assertEquals(null, accountAnnotationFieldController.saveAnnotation());

		Test.stopTest();
	}

	@isTest private static void ContactTest() 
	{
		Contact aContact = (Contact) TestFactory.createSObject(new Contact());
		insert aContact;

		ApexPages.StandardController contactStandardController = new ApexPages.StandardController(aContact);

		Test.startTest();

		PageReference contactAnnotationPageRef = Page.ContactAnnotation;
		Test.setCurrentPage(contactAnnotationPageRef);
		
		AnnotationFieldController contactAnnotationFieldController = new AnnotationFieldController(contactStandardController);
		system.assertEquals(null, contactAnnotationFieldController.saveAnnotation());

		Test.stopTest();
	}
}