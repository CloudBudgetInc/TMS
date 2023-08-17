global with sharing class CBSubMasterUpdateYear implements Schedulable  {
    global void execute(SchedulableContext SC) {
        subYear();
        CB_JOB_START start = new CB_JOB_START();
    }
    public static void subYear(){
        // Get current Financial Year and convert it to Integer
        Integer currFY = Integer.valueOf(CBVariable.currentFY);
        // Set previous Financial Year as current
        CBVariable.saveCurrentFY(String.valueOf(currFY - 1));
    }
}