/* **************************************************************************
* Controller Class: CreateJournalVerifyProjectController
* Created by lv@nubik.ca, 06/13/2017
* Purpose/Methods:
* - Unit test implemented for the class CreateJournalVerifyProjectController
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} � {Description of changes made post deployment to client}
*
************************************************************************** */
@isTest
private class CreateJournalVerifyProjectControllerTest 
{
	@testSetup static void setup()
	{
		kell6_core__Receipt_Settings__c rSetting = new kell6_core__Receipt_Settings__c();
		rSetting.kell6_core__Mapping_Class__c = 'kell6_cp.ReceiptingMapping_CnP';
		rSetting.kell6_core__Receiptable_Object_Recurring__c = 'CnP_PaaS__CnPRecurring__c';
		insert rSetting;

		npsp__Opportunity_Naming_Settings__c oppSetting = 
				new npsp__Opportunity_Naming_Settings__c();
		oppSetting.Name = '29/11/2016 10:50 AM';
		oppSetting.npsp__Attribution__c = 'Both';
		oppSetting.npsp__Date_Format__c = 'yyyy-MM-dd';
		insert oppSetting;

		Account a = new Account();
		a.Name = 'AccountTest';
		insert a;

		Opportunity opp = new Opportunity();
		opp.Name = 'Test';
		opp.CloseDate = Date.today().addDays(10);
		opp.StageName = 'Received';
		opp.Gift_Needs_Further_Attention__c = false;
		opp.Journal_Header__c = null;
		opp.Amount = 10;
		opp.AccountId = a.Id;
		opp.kell6_core__Benefit_Value__c = 5;
		insert opp;

		System.debug(':::::::::::::::::::::' + [Select id,Name from Opportunity where id =: opp.Id]);

		c2g__codaDimension3__c project = new c2g__codaDimension3__c();
		project.Name = 'Project Name';
		project.c2g__ExternalId__c = '111111';
		project.c2g__ReportingCode__c = '222222';
		project.c2g__UnitOfWork__c = 1;
		insert project;

	}

	@isTest static void requiresProjectTest()
	{
		c2g__codaDimension3__c dimension3 = [Select Id from c2g__codaDimension3__c 
				where Name = 'Project Name' limit 1];
		Opportunity opp = [Select Id from Opportunity where Name = 'Test' limit 1];
		donation_split__Designation__c designation = new donation_split__Designation__c();
		designation.Name = 'Designation';
		insert designation;

		donation_split__Designation_Budget__c desigBudget = new donation_split__Designation_Budget__c();
		desigBudget.donation_split__Opportunity__c = opp.Id;
		desigBudget.donation_split__Amount__c = 10;
		desigBudget.donation_split__Designation__c = designation.Id;
		insert desigBudget;

		CreateJournalVerifyProjectController controller = new CreateJournalVerifyProjectController(
				new ApexPages.StandardController(opp));
		controller.getRequiresProject();
	}

	@isTest static void requiresNoProjectTest()
	{
		c2g__codaDimension3__c dimension3 = [Select Id from c2g__codaDimension3__c 
				where Name = 'Project Name' limit 1];
		Opportunity opp = [Select Id from Opportunity where Name = 'Test' limit 1];
		System.debug('::::::Opportunity:::::::' + opp);
		donation_split__Designation__c designation = new donation_split__Designation__c();
		designation.Name = 'Designation';
		designation.Dimension3_Project__c = dimension3.Id;
		insert designation;

		donation_split__Designation_Budget__c desigBudget = new donation_split__Designation_Budget__c();
		desigBudget.donation_split__Opportunity__c = opp.Id;
		desigBudget.donation_split__Amount__c = 10;
		desigBudget.donation_split__Designation__c = designation.Id;
		insert desigBudget;

		CreateJournalVerifyProjectController controller = new CreateJournalVerifyProjectController(
				new ApexPages.StandardController(opp));
		System.assertEquals('',controller.getRequiresProject());
	}
}