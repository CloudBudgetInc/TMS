/* Requirements / mapping for correct Account/Contact creation
 *  
*/

@RestResource(urlMapping='/CreateAccountContact/*')
global class CreateAccountContactService {
    @HttpPost
    global static Result CreateAccountContact(String RecordType, String Type, String Title, String FirstName, String MiddleName, String LastName, String Suffix, String MailingStreet, String MailingCity, String MailingState, String MailingPostalCode, String HomePhone, String MobilePhone, String Email, String TMS_City) {
        
        Account ac = new Account();
        Contact co = new Contact();
        Id devRecordTypeId;
        
        
//        Contact resultContact = new Contact();
//        Account resultAccount = new Account();
        
        if (String.IsBlank(LastName)) {
           return new Result(null,null,'No Name/LastName has been received!');
        }
        If (String.IsBlank(RecordType)) {
            return new Result(null,null,'No Account RecordType has been received!');
        }
         
        try {
        	devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(RecordType).getRecordTypeId();
        } catch(Exception e) {
            return new Result(null,null,'Received Account RecordType does not exist!');
        }    
        
        If (RecordType=='Organization') {
            
            /* Create Account & Contact for new Organization */
            ac.Name=LastName;
            ac.BillingStreet=MailingStreet;
            ac.BillingCity=MailingCity;
            ac.BillingState=MailingState;
            ac.BillingPostalCode=MailingPostalCode;
            ac.TMS_City__c=TMS_City;
            ac.Type=Type;
            ac.Phone=HomePhone;
            ac.Email__c=Email;
            ac.RecordTypeId=devRecordTypeId;
            
 			try {
            	insert ac;
			} catch(DmlException e) {
				return new Result(null,null,'DML, Error creating Account!');
			}
            
            co.AccountId=ac.Id;
            co.LastName=ac.Name;
            co.MailingStreet=MailingStreet;
            co.MailingCity=MailingCity;
            co.MailingState=MailingState;
            co.MailingPostalCode=MailingPostalCode;
            co.HomePhone=HomePhone;
            co.MobilePhone=MobilePhone;
            co.Email=Email;
            co.TMS_City__c=TMS_City;
            co.Type__c='Organization Contact';
            
 			try {
				insert co;
			} catch(DmlException e) {
				return new Result(null,null,'DML, Error creating Contact!');
			}
            
        } else {
            
            /* Create Account & Contact for new Household */
            ac.Name = FirstName + ' ' +LastName + ' Household';
            ac.BillingStreet=MailingStreet;
            ac.BillingCity=MailingCity;
            ac.BillingState=MailingState;
            ac.BillingPostalCode=MailingPostalCode;
            ac.TMS_City__c=TMS_City;
            ac.Type=Type;
            ac.RecordTypeId=devRecordTypeId;
            
 			try {
            	insert ac;
			} catch(DmlException e) {
				return new Result(null,null,'DML, Error creating Account!');
			}
            
            co.AccountId=ac.Id;
            co.FirstName=FirstName;
            co.MiddleName=MiddleName;
            co.LastName=LastName;
            co.Title=Title;
            co.Suffix=Suffix;
            co.MailingStreet=MailingStreet;
            co.MailingCity=MailingCity;
            co.MailingState=MailingState;
            co.MailingPostalCode=MailingPostalCode;
            co.HomePhone=HomePhone;
            co.MobilePhone=MobilePhone;
            co.Email=Email;
            co.TMS_City__c=TMS_City;
            co.Type__c='Individual';
            
 			try {
				insert co;
			} catch(DmlException e) {
				return new Result(null,null,'DML, Error creating Contact!');
			}
        }
        
//        resultContact = [SELECT Id FROM Contact WHERE id = :co.Id];
//        resultAccount = [SELECT Id FROM Account WHERE id = :ac.Id];
        
        return new Result(co.Id,ac.Id,'');
    }
    
    global class Result {
        public Id contactId;
        public Id accountId;
        public String Error;
        
        public Result (Id cId, Id aId, String ErrM) {
            contactId = cId;
            accountId = aId;
            Error = ErrM;
        }
    }
}