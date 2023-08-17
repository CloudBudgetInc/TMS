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


public class TMS_EmailServiceConfig {
  public static Map<String, String> buildMapOfEmailServiceConfig() {
    Map<String, String> emailService = new Map<String, String>();
    List<Email_Service_Config__mdt> emailConf = [SELECT Value__c, DeveloperName FROM Email_Service_Config__mdt];
    for(Email_Service_Config__mdt ec :emailConf)	{
      emailService.put(ec.DeveloperName, ec.Value__c);
    }
    return emailService;
  }
}