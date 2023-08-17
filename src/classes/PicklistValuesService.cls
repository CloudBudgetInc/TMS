@RestResource(urlMapping='/PickListValues/*')
global class PicklistValuesService {

    @HttpGet
    global static Map<String,List<String>> getPicklistValues() {
        String fieldNames = RestContext.request.params.get('fieldNames');
        List<String> fieldList = fieldNames.split(',');

        return getPicklistValues(fieldList);
    }

    global static Map<String,List<String>> getPicklistValues(List<String> fieldList) {
        Map<String,List<String>> result = new Map<String,List<String>>();

        //From the Object Api name retrieving the SObject
        Map<String, Schema.SObjectType> definition = Schema.getGlobalDescribe();

        for (String name : fieldList) {
            List<String> splittedName = name.split('\\.');

            if (splittedName.size() < 2) {
                continue;
            }

            List<String> lstPickvals=new List<String>();

            String Field_name = splittedName[1];
            String ObjectApi_name = splittedName[0];
            
            If (ObjectApi_name=='Account' && Field_name=='RecordType') {
                lstPickvals.add('Household Account');
                lstPickvals.add('Organization');
                
            } else {
                
                Schema.SObjectType targetType = definition.get(ObjectApi_name);
                Sobject Object_name = targetType.newSObject();
                //grab the sobject that was passed
                Schema.sObjectType sobject_type = Object_name.getSObjectType(); 
                //describe the sobject
                Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); 
                //get a map of fields for the passed sobject
                Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); 
                //grab the list of picklist values for the passed field on the sobject
                List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues(); 
                //for all values in the picklist list
                for (Schema.PicklistEntry a : pick_list_values) {
                    lstPickvals.add(a.getValue());//add the value  to our final list
                }
            }
            result.put(name,lstPickvals);
        }

        return result;
    }
}