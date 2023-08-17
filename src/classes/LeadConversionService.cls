/* Requirements / mapping for correct Lead Conversion
 * Absent information field Name for individuals or field Company for Organization should be populated with '☺' chr(1)
 * Address for Induviduals populates into Address field for Organizations into Company Address fields.
 *  
*/

@RestResource(urlMapping='/ConvertLead/*')
global class LeadConversionService {
 
/*    -------------- Original code ---------------
    @HttpPost
    global static Result convertLead(Id leadId)
    {
        Lead l = [SELECT Id,Key_Indicator__c,
                            ConvertedAccountId,ConvertedContactId,
                            IsConverted,ConvertedContact.AccountId
                        FROM Lead WHERE Id = :leadId];

        if (l.IsConverted == true)
        {
            return new Result(l.ConvertedContactId,l.ConvertedContact.AccountId);
        }

        Boolean deleteAccount = l.Key_Indicator__c == 'Individual';

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);

        lc.setDoNotCreateOpportunity(true);

        Database.LeadConvertResult result = Database.convertLead(lc);

        if (deleteAccount)
        {
            Contact c = [SELECT Id, AccountId FROM Contact WHERE id = :result.getContactId()];
            c.AccountId = null;
            update c;

            Account a = new Account(Id=result.getAccountId());
            delete a;
        }

        Contact resultContact = [SELECT Id, AccountId FROM Contact WHERE id = :result.getContactId()];

        return new Result(resultContact.Id,resultContact.AccountId);
    }
*/
    @HttpPost
    global static Result convertLead(Id leadId) {
		/* Fields IsIndividual & IsOrganization determin by Name & Company fields on the Lead object 
		* If Name is populated - we have a person, if Company is populated - we have an Organization.*/
        
        Boolean IsIndividual;
        Boolean IsOrganization;
        Contact co = new Contact();
        
        Contact resultContact = new Contact();
        Account resultAccount = new Account();
        
        Lead l = [SELECT Id,Name,Company,Key_Indicator__c,npsp__CompanyCity__c,npsp__CompanyCountry__c,npsp__CompanyPostalCode__c,npsp__CompanyState__c,npsp__CompanyStreet__c,
                  ConvertedAccountId,ConvertedContactId,IsConverted,ConvertedContact.AccountId FROM Lead WHERE Id = :leadId];

        /* Check if we have fields Name (for individual) and Company (for Organizations) populated. Character ☺ (Ascii code 1) means we don't have info for required field */
        if(l.Name.contains('☺')) {IsIndividual=false;} else {IsIndividual=true;}
        if(l.Company.contains('☺')) {IsOrganization=false;} else {IsOrganization=true;}
        
/* If Lead has been converted */        
        if (l.IsConverted == true) {
            
/* Mapping result parameters for converted Lead
*  if Individual      & Organization:      Account = Org.Account; Contact = Ind.Contact
*  if NOT(Individual) & Organization:      Account = Org.Account; Contact = Org.Contact
*  if Individual      & NOT(Organization): Account = Household; Contact = Ind.Contact
*/        
            if(IsIndividual && IsOrganization) {
                /* return Individual Contact & Organization IDs */
                resultContact = [SELECT Id FROM Contact WHERE id = :l.ConvertedContactId];
                resultAccount = [SELECT Id FROM Account WHERE id = :l.ConvertedAccountId];
            } else {
                if (IsOrganization) {
                    /* return Organization Contact & Organization IDs */
                    resultAccount = [SELECT Id FROM Account WHERE id = :l.ConvertedAccountId];
                    resultContact = [SELECT Id FROM Contact WHERE AccountId = :l.ConvertedAccountId LIMIT 1];
                } else {
                    /* return Individual Contact & Household IDs */
                    resultContact = [SELECT Id, AccountId FROM Contact WHERE id = :l.ConvertedContactId];
                    resultAccount = [SELECT Id FROM Account WHERE id = :resultContact.AccountId];
                }
            }
            return new Result(resultContact.Id,resultAccount.Id);
        }
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        lc.setDoNotCreateOpportunity(true);
        
        Database.LeadConvertResult result = Database.convertLead(lc);
        
        /* Get new created Contact & Account */
        Contact c = [SELECT Id, AccountId FROM Contact WHERE id = :result.getContactId()];
        Account a = [SELECT Id, Name, TMS_City__c FROM Account WHERE id = :result.getAccountId()];
        
        /* Clear Contact's account (NPSP automatically create new Household with correct parameters) */
        c.AccountId = null;
        update c;
        
        /* If Not Individual - delete the Contact*/        
        if (!IsIndividual) {
            delete c;
        }
        /* If Not Organization - delete the Account*/        
        if (!IsOrganization) {
            delete a;
        } else {
            /* Else if Lead type is Organization - create "Dummy" Contact for Org Account */
            co.AccountId=a.Id;
            co.LastName=a.Name;
            co.MailingCity=l.npsp__CompanyCity__c;
            co.MailingCountry=l.npsp__CompanyCountry__c;
            co.MailingPostalCode=l.npsp__CompanyPostalCode__c;
            co.MailingState=l.npsp__CompanyState__c;
            co.MailingStreet=l.npsp__CompanyStreet__c;
            co.TMS_City__c=a.TMS_City__c;
            co.Type__c='Organization Contact';
            co.LeadSource='Purchased List';
            insert co;
            
            /* delete contact's address assigned by ConvertLead method*/
            List<npsp__Address__c> addr = [SELECT Id FROM npsp__Address__c WHERE npsp__Household_Account__c = :a.Id LIMIT 1];
            if (addr.size()>0) {
            	delete addr[0]; 
            }
            
            a.Type=null;
            a.Sub_Type__c=null;
            a.BillingCity=l.npsp__CompanyCity__c;
            a.BillingCountry=l.npsp__CompanyCountry__c;
            a.BillingPostalCode=l.npsp__CompanyPostalCode__c;
            a.BillingState=l.npsp__CompanyState__c;
            a.BillingStreet=l.npsp__CompanyStreet__c;
            if (IsIndividual) {
                a.npe01__One2OneContact__c=c.Id;
            } else {
                a.npe01__One2OneContact__c=co.Id;
            }    
            update a;
        }
        /* create affiliation between Individual and Organization for Organization Lead */
        if (IsIndividual && IsOrganization) {
            npe5__Affiliation__c Affiliation = new npe5__Affiliation__c();
            Affiliation.npe5__Contact__c=c.Id;
            Affiliation.npe5__Organization__c=a.Id;
            Affiliation.npe5__Status__c='Current';
            
            insert Affiliation;
        }

/* Mapping result parameters
*  if Individual      & Organization:      Account = Org.Account; Contact = Ind.Contact
*  if NOT(Individual) & Organization:      Account = Org.Account; Contact = Org.Contact
*  if Individual      & NOT(Organization): Account = Household; Contact = Ind.Contact
*/        
        if(IsIndividual && IsOrganization) {
            /* return Individual Contact & Organization IDs */
            resultContact = [SELECT Id FROM Contact WHERE id = :c.Id];
            resultAccount = [SELECT Id FROM Account WHERE id = :a.Id];
        } else {
            if (IsOrganization) {
                /* return Organization Contact & Organization IDs */
                resultContact = [SELECT Id FROM Contact WHERE id = :co.Id];
                resultAccount = [SELECT Id FROM Account WHERE id = :a.Id];
            } else {
                /* return Individual Contact & Household IDs */
                resultContact = [SELECT Id, AccountId FROM Contact WHERE id = :c.Id];
                resultAccount = [SELECT Id FROM Account WHERE id = :resultContact.AccountId];
            }
        }
        return new Result(resultContact.Id,resultAccount.Id);
    }
    
    global class Result {
        public Id contactId;
        public Id accountId;
        
        public Result (Id cId, Id aId) {
            contactId = cId;
            accountId = aId;
        }
    }
}