@isTest
private class LeadConversionService_Test {

	@isTest
	private static void individualLead_convertion() 
    {
        Lead myLead = new Lead(FirstName='D', LastName = 'T', Company='Fry And Sons', Key_Indicator__c='Individual');
        insert myLead;

        Test.startTest();

        LeadConversionService.convertLead(myLead.id);

        Test.stopTest();

        myLead = [SELECT Id,ConvertedAccountId,ConvertedContactId,ConvertedOpportunityId,IsConverted FROM Lead WHERE Id = :myLead.Id];

        List<Account> acts = [SELECT ID FROM Account WHERE Id = :myLead.ConvertedAccountId];

        System.assertEquals(true,myLead.IsConverted);
        System.assertEquals(1,acts.size());
        System.assertNotEquals(null,myLead.ConvertedContactId);
        System.assertEquals(null,myLead.ConvertedOpportunityId);
	}

	@isTest
	private static void individualLead_convertion_repeat() 
    {
        Lead myLead = new Lead(FirstName='D', LastName = 'T', Company='Fry And Sons', Key_Indicator__c='Individual');
        insert myLead;

        LeadConversionService.Result r1 = LeadConversionService.convertLead(myLead.id);

        Test.startTest();

        LeadConversionService.Result r2 = LeadConversionService.convertLead(myLead.id);

        Test.stopTest();

        System.assertEquals(r1.contactId,r2.contactId);
        System.assertEquals(r1.accountId,r2.accountId);
	}

	@isTest
	private static void organizationLead_convertion() 
    {
        Lead myLead = new Lead(FirstName='D', LastName = 'T', Company='Fry And Sons', Key_Indicator__c='Organization');
        insert myLead;

        Test.startTest();

        LeadConversionService.convertLead(myLead.id);

        Test.stopTest();

        myLead = [SELECT Id,ConvertedAccountId,ConvertedContactId,ConvertedOpportunityId,IsConverted FROM Lead WHERE Id = :myLead.Id];

        List<Account> acts = [SELECT ID FROM Account WHERE Id = :myLead.ConvertedAccountId];

        System.assertEquals(true,myLead.IsConverted);
        System.assertEquals(1,acts.size());
        System.assertNotEquals(null,myLead.ConvertedContactId);
        System.assertEquals(null,myLead.ConvertedOpportunityId);
	}

	@isTest
	private static void organizationLead_convertion_repeat() 
    {
        Lead myLead = new Lead(FirstName='D', LastName = 'T', Company='Fry And Sons', Key_Indicator__c='Organization');
        insert myLead;

        LeadConversionService.Result r1 = LeadConversionService.convertLead(myLead.id);

        Test.startTest();

        LeadConversionService.Result r2 = LeadConversionService.convertLead(myLead.id);

        Test.stopTest();

        System.assertEquals(r1.contactId,r2.contactId);
        System.assertEquals(r1.accountId,r2.accountId);
	}
}