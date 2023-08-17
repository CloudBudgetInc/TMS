/* **************************************************************************
* Test Util: TestFactory
* Created by Jesus Varela, 10-23-2017
*
* Purpose:
* Create Test data
*
* Unit Test: {name of the Class with UnitTest(s) that cover this trigge} 
* 
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
@isTest
public class TestFactory {
	
	public static SObject createSObject(SObject sObj) {
        // Check what type of object we are creating and add any defaults that are needed.
        String objectName = String.valueOf(sObj.getSObjectType());
        // Construct the default values class. Salesforce doesn't allow '__' in class names
        String defaultClassName = 'TestFactory.' + objectName.replace('__c', '').replace('__', '') + 'Defaults';
        // If there is a class that exists for the default values, then use them
        if (Type.forName(defaultClassName) != null) {
            sObj = createSObject(sObj, defaultClassName);
        }
        return sObj;
    }

    public static SObject createSObject(SObject sObj, Boolean doInsert) {
        SObject retObject = createSObject(sObj);
        if (doInsert) {
            insert retObject;
        }
        return retObject;
    }

    public static SObject createSObject(SObject sObj, String defaultClassName) {
        // Create an instance of the defaults class so we can get the Map of field defaults
        Type t = Type.forName(defaultClassName);
        if (t == null) {
            Throw new TestFactoryException('Invalid defaults class.');
        }
        FieldDefaults defaults = (FieldDefaults)t.newInstance();
        addFieldDefaults(sObj, defaults.getFieldDefaults());
        return sObj;
    }

    public static SObject createSObject(SObject sObj, String defaultClassName, Boolean doInsert) {
        SObject retObject = createSObject(sObj, defaultClassName);
        if (doInsert) {
            insert retObject;
        }
        return retObject;
    }

    public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects) {
        return createSObjectList(sObj, numberOfObjects, (String)null);
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, Boolean doInsert) {
        SObject[] retList = createSObjectList(sObj, numberOfObjects, (String)null);
        if (doInsert) {
            insert retList;
        }
        return retList;
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, String defaultClassName, Boolean doInsert) {
        SObject[] retList = createSObjectList(sObj, numberOfObjects, defaultClassName);
        if (doInsert) {
            insert retList;
        }
        return retList;
    }

    public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects, String defaultClassName) {
        SObject[] sObjs = new SObject[] {};
        SObject newObj;

        // Get one copy of the object
        if (defaultClassName == null) {
            newObj = createSObject(sObj);
        } else {
            newObj = createSObject(sObj, defaultClassName);
        }

        // Get the name field for the object
        /*String nameField = nameFieldMap.get(String.valueOf(sObj.getSObjectType()));
        if (nameField == null) {
            nameField = 'Name';
        }*/

        // Clone the object the number of times requested. Increment the name field so each record is unique
        for (Integer i = 0; i < numberOfObjects; i++) {
            SObject clonedSObj = newObj.clone(false, true);
            /*if(nameField != 'skeepitplease'){
                clonedSObj.put(nameField, (String)clonedSObj.get(nameField) + ' ' + i);
            }*/
            sObjs.add(clonedSObj);
        }
        return sObjs;
    }

    private static void addFieldDefaults(SObject sObj, Map<String, Object> defaults) {
        // Loop through the map of fields and if they are null on the object, fill them.
        for (String field : defaults.keySet()) {
            if (sObj.get(field) == null) {
                sObj.put(field, defaults.get(field));
            }
        }
    }

    // When we create a list of SObjects, we need to
    private static Map<String, String> nameFieldMap = new Map<String, String> {
        'Contact' => 'LastName',
        'Case' => 'Subject',
        'User' => 'username',
        'pse__Timecard_Header__c' => 'skeepitplease'
    };

    public class TestFactoryException extends Exception {}

    // Use the FieldDefaults interface to set up values you want to default in for all objects.
    public interface FieldDefaults {
        Map<String, Object> getFieldDefaults();
    }

	// To specify defaults for objects, use the naming convention [ObjectName]Defaults.
	// For custom objects, omit the __c from the Object Name

	public class AccountDefaults implements FieldDefaults{
		public Map<String, Object> getFieldDefaults() {
			return new Map<String, Object> {
				'Name' => RandomDataGenerator.getCompanyName()
			};
		}
	}

	public class ContactDefaults implements FieldDefaults{
		public Map<String, Object> getFieldDefaults() {
			return new Map<String, Object> {
				'FirstName' => RandomDataGenerator.getFirstName(),
				'LastName' => RandomDataGenerator.getLastName()
			};
		}
	}
    public class OpportunityDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                'Name' => RandomDataGenerator.getCompanyName(),
                'CloseDate' => Date.today(),
                'LeadSource' => 'Other',
                'StageName' => 'Closed Won'
            };
        }
    }
	public class DonationOpportunityDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                'Name' => RandomDataGenerator.getCompanyName(),
                'CloseDate' => Date.today(),
                'LeadSource' => 'Other',
                'StageName' => 'Received',
				'ForecastCategoryName' => 'Closed',
				'Probability' => 100,
				'Type' => '01236000000fv3r',
				'CnP_PaaS__CnP_OrderNumber__c' => 'a6f36000000CkXR'
            };
        }
    }
	public class OnlineDonationOpportunityDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                'Name' => RandomDataGenerator.getCompanyName(),
                'CloseDate' => Date.today(),
                'LeadSource' => 'Other',
                'StageName' => 'Received',
				'ForecastCategoryName' => 'Closed',
				'Probability' => 100,
				'Type' => '01236000000fv3r',
				'CnP_PaaS__CnP_OrderNumber__c' => 'a6f36000000CkXR'//'a6f0q000000CaczAAC' 
            };
        }
    }
	public class RecurringDonationOpportunityDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                'Name' => RandomDataGenerator.getCompanyName(),
                'CloseDate' => Date.today(),
                'LeadSource' => 'Other',
                'StageName' => 'Received',
				'ForecastCategoryName' => 'Closed',
				'Probability' => 100,
				'Type' => '01236000000fv3r',
				'CnP_PaaS__CnP_OrderNumber__c' => 'a6f36000000CkXR',
				'CnP_PaaS__C_P_Recurring__c' => '', //'a6f36000000CkXR',
				'Amount' => Double.valueOf(RandomDataGenerator.getRandomNumber(5))
            };
        }
    }
	public class TaskDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                'Status' => 'Not Started',
                'Priority' => 'Normal',
                'Subject' => RandomDataGenerator.getAlphaNumericString(15),
                'Type' => 'Meeting'
            };
        }
    }
	public class UserDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                'Alias' => RandomDataGenerator.getAlphaNumericString(6),
                'Username' => RandomDataGenerator.getEmailAddress(),
                'CommunityNickname' => RandomDataGenerator.getAlphaNumericString(6),
                'Email' => RandomDataGenerator.getEmailAddress(),
                'LastName' => RandomDataGenerator.getLastName(),
                'EmailEncodingKey' => 'UTF-8',
                'LocaleSidKey' => 'en_US',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'LanguageLocaleKey' => 'en_US'
            };
        }
    }

	/*public class CPTransactionDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
				'CnP_PaaS__TotalCharged__c' => Double.valueOf(RandomDataGenerator.getRandomNumber(5)),
				'CnP_PaaS__TotalDue__c' => Double.valueOf(RandomDataGenerator.getRandomNumber(5)),
				'CnP_PaaS__TransactionDate__c' => Date.today(),
				'CnP_PaaS__TransactionTimeZone__c' => Date.today()
            };
        }
    }*/
	
	public class npsp_BatchDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                'Name' => 'test',
                'npsp__Object_Name__c' => 'Opportunity'
            };
        }
    }

}