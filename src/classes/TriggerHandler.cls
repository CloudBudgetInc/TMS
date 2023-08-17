public virtual class TriggerHandler {
    // static map of handlername, times run() was invoked
    private static Set<String> bypassedHandlers;
    private static Set<String> bypassedHandlersCO;
    private static boolean ignoreAll = false;
    static {
        TriggerHandler.loadSettings();
    }

    public TriggerHandler() {

    }
    public static void loadSettings(){
        bypassedHandlers = new Set<String>();
        bypassedHandlersCO = new Set<String>();
        try{
            Trigger_Framework_Settings__c tf = [Select Name, Disable_All_Triggers__c, Disabled_Triggers__c from Trigger_Framework_Settings__c limit 1];
            string[] handlers = (!string.isEmpty(tf.Disabled_Triggers__c))? tf.Disabled_Triggers__c.split(','): new String[]{};
            for(string dt : handlers){
                bypassedHandlersCO.add(dt);
            }
            ignoreAll = tf.Disable_All_Triggers__c; 
        }catch(Exception ex){
            system.debug('Handler Exception '+ex.getMessage());
            system.debug('Handler Exception '+ex.getStackTraceString());
        }        
    }
    /***************************************
        * public methods
    ***************************************/

    // main method that will be called during execution
    public void run() {     
        if(!validateRun()) return;     
        if(Trigger.isBefore) { 
            this.bulkBefore();
        }
        if(Trigger.isAfter) { 
            this.bulkAfter();
        }
        // dispatch to the correct handler method
        if(Trigger.isBefore && Trigger.isInsert) {
            this.beforeInsert();
        } else if(Trigger.isBefore && Trigger.isUpdate) {
            this.beforeUpdate();
        } else if(Trigger.isBefore && Trigger.isDelete) {
            this.beforeDelete();
        } else if(Trigger.isAfter && Trigger.isInsert) {
            this.afterInsert();
        } else if(Trigger.isAfter && Trigger.isUpdate) {
            this.afterUpdate();
        } else if(Trigger.isAfter && Trigger.isDelete) {
            this.afterDelete();
        } else if(Trigger.isAfter && Trigger.isUndelete) {
            this.afterUndelete();
        }
        this.finalActions();        
    }

    public static void bypass(String handlerName) {
        TriggerHandler.bypassedHandlers.add(handlerName);
    }

    public static void clearBypass(String handlerName) {
        TriggerHandler.bypassedHandlers.remove(handlerName);
    }

    public static Boolean isBypassed(String handlerName) {
        return TriggerHandler.bypassedHandlers.contains(handlerName);
    }

    public static void clearAllBypasses() {
        TriggerHandler.bypassedHandlers.clear();
    }

    /***************************************
        * private methods
    ***************************************/

    // make sure this trigger should continue to run
    private Boolean validateRun() {
        if(!Trigger.isExecuting) {
            throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
        }        
        if(TriggerHandler.bypassedHandlers.contains(getHandlerName()) || ignoreAll 
            || bypassedHandlersCO.contains(getHandlerName())) {
            return false;
        }
        return true;
    }

    private String getHandlerName() {
        return String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
    }

    /***************************************
        * context methods
    ***************************************/

    // context-specific methods for override
    //this method is used to get all records befor apply the business logic
    protected virtual void bulkBefore(){}
    protected virtual void bulkAfter(){}
    protected virtual void beforeInsert(){}
    protected virtual void beforeUpdate(){}
    protected virtual void beforeDelete(){}
    protected virtual void afterInsert(){}
    protected virtual void afterUpdate(){}
    protected virtual void afterDelete(){}
    protected virtual void afterUndelete(){}
    //this method is used to execute all DML actions
    protected virtual void finalActions(){}
    /***************************************
    * Recursion handler
    ***************************************/
    private static Map<Id,set<string>> m_ProcessPerName = new Map<Id,set<string>>();
    public static boolean DidProcessRan(string processName, Id parentObject)
    {
        boolean retVal = false;
        if(m_ProcessPerName.containsKey(parentObject))
        {
            if(m_ProcessPerName.get(parentObject).contains(processName))
            {
                retVal= true;
            }
        }
        return retVal;
    }
    public static void AddProcessRun(string processName, Id parentObject)
    {
        if(!m_ProcessPerName.containsKey(parentObject))
        {
            m_ProcessPerName.put(parentObject,new set<string>());
        }
        m_ProcessPerName.get(parentObject).add(processName);
    }

    // exception class
    public class TriggerHandlerException extends Exception {}
        

}