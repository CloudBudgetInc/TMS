public with sharing class AnnotationFieldController {
    private final Account acct;
    private final Contact cont;
    private string type;
    public AnnotationFieldController(ApexPages.StandardController stdController) {
        if(((Id)stdController.getId()).getSobjectType() == Schema.Account.SObjectType){            
            this.acct = (Account)stdController.getRecord();
            type = 'Account';
        }else{
            this.cont = (Contact)stdController.getRecord();
            type = 'Contact';
        }
    }
    public PageReference saveAnnotation(){
        if(type == 'Account'){
            update acct;
        }else{
            update cont;
        }
        return null;
    }
}