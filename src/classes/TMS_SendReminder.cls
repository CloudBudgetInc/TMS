/**
 * All Rights Reserved
 * Customers of Aria Solutions are permitted to use and modify this
 * code in all of their Salesforce Orgs (Production, Sandboxes), but
 * any form of distribution to other Salesforce Orgs not belonging to
 * the customer require a written permission from Aria Solutions
 * ***************************************************
 * Created Date: Tuesday May 5th 2020
 * Author: Vacheslav Aronov
 * File type: '.cls'
 */


global class TMS_SendReminder implements Schedulable {

  private static final String CLASS_NAME = 'TMS_SendReminder';

    @TestVisible
    private static final String UNOPENED_DAYS_KEY = 'Unopened_Email_In_Days';

    @TestVisible
    private static final String UNOPENED_TEMPLATE_KEY = 'Campaign_Email_Reminder';

  global void execute(SchedulableContext context) {

      Map<String, String> emailServiceMap = TMS_EmailServiceConfig.buildMapOfEmailServiceConfig();
      final Integer unopenedDays = Integer.valueOf(emailServiceMap.get(UNOPENED_DAYS_KEY));
      final String reminderTemplateName = emailServiceMap.get(UNOPENED_TEMPLATE_KEY);

      Map<String, Set<Id>> sendEmailMap = getRecipientsMap(unopenedDays);
      EmailTemplate reminderTemplate = getEmailTemplateByName(reminderTemplateName);

      System.debug('sendEmailMap:' + sendEmailMap);
      Set<Id> campaignMemberIds = new Set<Id>();
      Set<Id> leadsAndContacts = new Set<Id>();
      Set<Id> contactIds = new Set<Id>();
      Set<Id> leadIds = new Set<Id>();
      Set<Id> emailToSendIds = new Set<Id>();
      for (String key : sendEmailMap.keySet())  {
        switch on key {
          when 'member' {
            campaignMemberIds.addAll(sendEmailMap.get(key));
          }
          when 'contact'  {
            contactIds.addAll(sendEmailMap.get(key));
          }
          when 'lead' {
            leadIds.addAll(sendEmailMap.get(key));
          }
        }
      }
      List<CampaignMember> members = [SELECT ContactId, LeadId FROM CampaignMember WHERE Id IN :campaignMemberIds];
      System.debug('members:' + members);
      for (CampaignMember member : members) { if (member.LeadId != null)  { leadIds.add(member.LeadId);} if (member.ContactId != null) { contactIds.add(member.ContactId);}}

      System.debug('leadIds: ' + leadIds);
      System.debug('contactIds: ' + contactIds);

      emailToSendIds.addAll(getRecipientIds(leadIds, unopenedDays));
      emailToSendIds.addAll(getRecipientIds(contactIds, unopenedDays));

      System.debug('emailToSendIds: ' + emailToSendIds);

      sendEmail(reminderTemplate, emailToSendIds);

  }

  private static EmailTemplate getEmailTemplateByName(String name) {
    return [SELECT Id FROM EmailTemplate WHERE Name = :name];
  }

  private static Map<String, Set<Id>> getRecipientsMap(Integer days) {
    Map<String, Set<Id>> recipients = new Map<String, Set<Id>>();
    Set<Id> campaignMemberIds = new Set<Id>();
    Set<Id> contactIds = new Set<Id>();
    Set<Id> leadIds = new Set<Id>();
    Date createdDateStart = System.today().addDays(-days);
    Date createdDateEnd = createdDateStart.addDays(1);
    List<ListEmailIndividualRecipient> listRecipients = [
        SELECT RecipientId
        FROM ListEmailIndividualRecipient
        WHERE ListEmailId
        IN (SELECT Id FROM ListEmail WHERE CreatedDate >= :createdDateStart AND CreatedDate < :createdDateEnd)
    ];

    System.debug('listRecipients: ' + listRecipients);

    for (ListEmailIndividualRecipient l : listRecipients) { switch on String.valueOf(l.RecipientId).left(3) {when '003'  {contactIds.add(l.RecipientId);} when '00Q'  {leadIds.add(l.RecipientId);} when '00v'  {campaignMemberIds.add(l.RecipientId); }}}
    recipients.put('contact', contactIds);
    recipients.put('lead', leadIds);
    recipients.put('member', campaignMemberIds);
    return recipients;
  }

  private static Set<Id> getRecipientIds(Set<Id> setIds, Integer days) {
    Set<Id> recipientIds = new Set<Id>();
    Date createdDate = System.today().addDays(-days);
    List<Contact> contacts = [
      SELECT Id, (SELECT Id, CreatedDate FROM EmailStatuses WHERE TimesOpened = 0 AND Task.Subject LIKE 'List Email:%')
      FROM Contact 
      WHERE Id IN :setIds
    ];
    List<Lead> leads = [
      SELECT Id, (SELECT Id, CreatedDate FROM EmailStatuses WHERE TimesOpened = 0 AND Task.Subject LIKE 'List Email:%')
      FROM Lead
      WHERE Id IN :setIds
    ];
    if (contacts.size() > 0)  { for (Contact con : contacts)  { if (con.EmailStatuses.size() > 0) { for (EmailStatus status : con.EmailStatuses)  { if (status.CreatedDate.date() == createdDate) { recipientIds.add(con.Id);}}}}}
    if (leads.size() > 0) { for (Lead l : leads)  { if (l.EmailStatuses.size() > 0) { for (EmailStatus status : l.EmailStatuses)  { if (status.CreatedDate.date() == createdDate) { recipientIds.add(l.Id);}}}}}

    System.debug('recipientIds: ' + recipientIds);
    return recipientIds;
  }

  @TestVisible
  private void sendEmail(EmailTemplate template, Set<Id> ids)  {
    List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
    for(Id i : ids)   {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSenderDisplayName('The Mustard Seed');
        mail.setTargetObjectId(i);
        mail.setTemplateId(template.id);
        mail.setReplyTo('donorrelations@theseed.ca');
        messages.add(mail);
    }

    List<Messaging.SendEmailResult> emailResults = new List<Messaging.SendEmailResult>();
    List<List<Messaging.SingleEmailMessage>> splitMessages = splitListByBatchSize(messages, 100);
    for(List<Messaging.SingleEmailMessage> split:splitMessages)  {
        emailResults =+ Messaging.sendEmail(split, false);
    }

    Set<String> failedId = new Set<String>();
    for (Messaging.SendEmailResult ser : emailResults) {
        if (!ser.isSuccess()) {
            // Log error with target object ID
//          List<Messaging.SendEmailError> errors = ser.getErrors();
//          failedId.add(errors[0].getTargetObjectId());
//          System.debug(CLASS_NAME + ' errors: ' + errors[0].message);
//          System.debug(CLASS_NAME + ' Ids failed: ' + failedId);
        }
    }
  }

  public static List<List<Messaging.SingleEmailMessage>> splitListByBatchSize(List<Messaging.SingleEmailMessage> source, Integer batchSize) {
    List<Messaging.SingleEmailMessage> batch = new List<Messaging.SingleEmailMessage>();
    List<List<Messaging.SingleEmailMessage>> listoflist = new List<List<Messaging.SingleEmailMessage>>();

    for (Messaging.SingleEmailMessage j : source){
        batch.add(j);
        if (batch.size() == batchSize){ listoflist.add(batch); batch = new List<Messaging.SingleEmailMessage>{};}
    }
    if (!batch.isEmpty()) listoflist.add(batch);
    return listoflist;
  }
}