/**
 * All Rights Reserved
 * Customers of Aria Solutions are permitted to use and modify this
 * code in all of their Salesforce Orgs (Production, Sandboxes), but
 * any form of distribution to other Salesforce Orgs not belonging to
 * the customer require a written permission from Aria Solutions
 * ***************************************************
 * Created Date: Monday May 11th 2020
 * Author: Vacheslav Aronov
 * File type: '.cls'
 */

@isTest
public class TMS_SendReminderTest {

  private static Map<String, String> EMAIL_CONFIG = TMS_EmailServiceConfig.buildMapOfEmailServiceConfig();

  private static TMS_SendReminder sendReminderClass {
    get {
      return new TMS_SendReminder();
    }
    set;
  }

  private static Account testAccount {get; set;}
  private static Contact testContact {get; set;}
  private static Lead testLead {get; set;}
  private static EmailTemplate template {get; set;}

  @isTest
  static void MetadataTest() {

    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    System.runAs(currentUser) {
      String templateName = 'test_template';
      EmailTemplate template = createEmailTemplate(templateName);
      testAccount = createAccount();
      testContact = createContact(testAccount.Id);
      testLead = createLead();
    }

    Datetime emailSentDate = Datetime.now().addDays(Integer.valueOf(EMAIL_CONFIG.get(TMS_SendReminder.UNOPENED_DAYS_KEY)) * -4);
    String emailTemplateName = EMAIL_CONFIG.get(TMS_SendReminder.UNOPENED_TEMPLATE_KEY);
    String unopenedEmailDays = EMAIL_CONFIG.get(TMS_SendReminder.UNOPENED_DAYS_KEY);
    String templateName = String.valueOf([SELECT Value__c FROM Email_Service_Config__mdt WHERE DeveloperName = :TMS_SendReminder.UNOPENED_TEMPLATE_KEY].Value__c);
    String days = String.valueOf([SELECT Value__c FROM Email_Service_Config__mdt WHERE DeveloperName = :TMS_SendReminder.UNOPENED_DAYS_KEY].Value__c);

    Test.startTest();
    sendReminderClass.execute(null);
    Test.stopTest();

    System.assertEquals(templateName, emailTemplateName);
    System.assertEquals(days, unopenedEmailDays);
  }

  @isTest
  static void testSendEmailInvocations() {

    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    System.runAs(currentUser) {
      String templateName = 'test_template';
      template = createEmailTemplate(templateName);
      testAccount = createAccount();
      testContact = createContact(testAccount.Id);
      testLead = createLead();
    }

    Set<Id> testSendIds = new Set<Id>();
    testSendIds.add(testContact.Id);
    testSendIds.add(testLead.Id);

    System.assertEquals(0, Limits.getEmailInvocations());

    Test.startTest();
    System.debug('testSendIds: ' + testSendIds);
    sendReminderClass.sendEmail(template, testSendIds);
    System.assertEquals(1, Limits.getEmailInvocations());
    Test.stopTest();
  }

  // Helper methods

  private static EmailTemplate createEmailTemplate(String name) {
    EmailTemplate newTemplate = new EmailTemplate(
        Name = name,
        DeveloperName = name,
        TemplateType = 'text',
        FolderId = UserInfo.getUserId(),
        IsActive = true
    );
    insert newTemplate;
    return [SELECT Id FROM EmailTemplate WHERE DeveloperName = :name];
  }

  private static Account createAccount()  {
    Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
    System.debug('accRecordTypeId: ' + accRecordTypeId);
    Account newAccount = new Account(Name = 'TestAccount', RecordTypeId = accRecordTypeId, Type = 'Business');
    insert newAccount;
    return newAccount;
  }

  private static Contact createContact(Id accountId) {
    Contact newContact = new Contact(
        FirstName = 'John',
        LastName = 'Doe',
        Email = 'john.doe@test.com'
    );
    insert newContact;
    return newContact;
  }

  private static Lead createLead() {
    Lead newLead = new Lead(
        FirstName = 'James',
        LastName = 'Bond',
        Email = 'james.bond@test.com',
        Company = 'TestCompany'
    );
    insert newLead;
    return newLead;
  }
}