@RestResource(urlMapping='/CreateBatch/*')
global with sharing class ScanStationBatchService {
    
    @HttpPost
    global static Result batchService(String newType, String newDate, String newName) {
        
        // Initialize variables for the return Result messages
        String myMessage = '';
        String batchId;

        // if(batchRequest != null) {

            TypedInputs typedbatchRequest = validateInputs(newName, newDate, newType);

            npsp__Batch__c b = new npsp__Batch__c();
            b.npsp__Object_Name__c = 'Opportunity';

            b.Name = typedbatchRequest.typedName;
            b.Date__c = typedbatchRequest.typedDate;
            b.Type__c = typedbatchRequest.typedType;
            try {
                insert b;
            } catch (Exception e){
                myMessage = e.getMessage();

            }
            batchId = String.valueOf(b.Id);           

        // } else { // no input information -> set the return message
        //     myMessage = 'There was an error receiving information. No inputs found.';
        // }

        // if complete message is blank we can assume success. Set Return messages accordingly
        if(string.isBlank(myMessage)){
            myMessage = 'Success';
        }
  
        // return batch info
        return new Result(batchId, myMessage);

        // System.debug('KJW batchRequest:  ' + batchRequest.batch);
        // if(String.isBlank(batchRequest.batch)){
        //     return createNewBatch();
        // } else {
        //     if(batchRequest.batch.substring(0,3) == 'a0M'){
        //         return batchRequest.batch;
        //     } else {
        //         npsp__Batch__c b = new npsp__Batch__c();
        //         b = [SELECT Id, Name, CreatedDate FROM npsp__Batch__c WHERE Name = :batchRequest.batch order by CreatedDate LIMIT 1];

        //         if(b.Id != null){
        //             return b.Id;
        //         } else {
        //             return createNewBatch();
        //         }
        //     }
        // }
    }

    /**
     * Validate Inputs
     * Receives the REST inputs as a series of Strings and converts them to the appropriate data type
     * @param       myInputs        Class variable (see below)
     * @return                      TypedInputs class variable (see below) 
     */
    private static TypedInputs validateInputs(String newName, String newDate, String newType){
        TypedInputs ti = new TypedInputs();

        Schema.sObjectField ty = npsp__Batch__c.Type__c;  // for type picklist

        ti.typedName = validateStringInput(newName);
        ti.typedDate = validateDateInput(newDate);
        ti.typedType = validatePicklistValue(newType, ty) ? newType : '';

        return ti;
    }

    private static String createNewBatch(){
        npsp__Batch__c b = new npsp__Batch__c();
        b.npsp__Object_Name__c = 'Opportunity';
        insert b;
        return b.Id;
    }

    /**
     * Validate String Input
     * Test a String to make sure it's not null 
     * @param inputVariable   String to be validated
     * @return                String or ''
     */
    private static String validateStringInput(String inputVariable){
        if(String.isNotBlank(inputVariable)){
        return inputVariable;
        } else{
        return '';
        }
    }

    /**
    * Validate Date Input
    * Test a String to make sure it's not null and convert to a date
    * @param inputVariable   String to be converted 
    * @return                String or ''
    */
    private static Date validateDateInput(String inputVariable){
        if(String.isNotBlank(inputVariable)){
        return date.valueOf(inputVariable);
        } else{
        return null;
        }
    }

    /**
     * Validate that a string is a valid picklist value
     * @param value   value to validate 
     * @param field   the field to find the picklist value in
     * @return        Return a list of the active values
     * 
     * source/credit: https://www.jamessimone.net/blog/joys-of-apex/picklist-validation/
     */
    private static Boolean validatePicklistValue(String value, SOBjectField field) {
        if(String.isNotBlank(value)) { 
        if(getPicklistValues(field).contains(value)) {
            return true;
        } else {
            return false;  
        }
        } else {
        return false;
        }
    }

    /**
     * Get Picklist Values
     * Get the active values from a picklist
     * @param activefield   the picklist to retreive values from
     * @return              Return a list of the active values
     * 
     * source/credit: https://www.phoneiq.co/blog/how-to-check-picklist-values-with-apex-in-salesforce
     */
    private static List<String> getPicklistValues(sObjectField field){

        Schema.DescribeFieldResult fieldMetadata = field.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldMetadata.getPicklistValues();

        List<String> returnValues = new List<String>();
        for(Schema.PicklistEntry picklistEntry : picklistEntries) {
        returnValues.add(picklistEntry.getValue());
        }
        return returnValues;
    }


    global class Inputs {
        // public string batch;
        public String newName;
        public String newDate;
        public String newType;
    }

    private class TypedInputs {
        public String typedName;
        public Date typedDate;
        public String typedType;
    }

    global class Result {
        public String batchId;
        public String errormsg;

        public Result(String myId, String myMessage) {
            batchId = myId;
            errormsg = myMessage;
        }
    }
}