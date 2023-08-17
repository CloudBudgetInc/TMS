@isTest
private class CreateAccountContactService_Test {
    
    private class Result {
        private Id contactId;
        private Id accountId;
        private String Error;
        private Result (Id cId, Id aId, String ErrM) {
            contactId = cId;
            accountId = aId;
            Error = ErrM;
        }
    }
    
    
  	@isTest
	private static void CreateOrgAccount() 
    {

        Test.startTest();

        CreateAccountContactService.CreateAccountContact('Organization','','','','','Test Org','','','','','','','','','');

        Test.stopTest();


//        System.assertEquals(true,myLead.IsConverted);
//        System.assertEquals(1,acts.size());
//        System.assertNotEquals(null,myLead.ConvertedContactId);
//        System.assertEquals(null,myLead.ConvertedOpportunityId);
	}

      	@isTest
	private static void CreateHouseholdAccount() 
    {

        Test.startTest();

        CreateAccountContactService.CreateAccountContact('Household Account','','','','','Test Household','','','','','','','','','');
        CreateAccountContactService.CreateAccountContact('Household Account','','','','','','','','','','','','','','');
        CreateAccountContactService.CreateAccountContact('','','','','','Test Household','','','','','','','','','');
        CreateAccountContactService.CreateAccountContact('HouseAccount','','','','','Test Household','','','','','','','','','');


        Test.stopTest();

	}

}