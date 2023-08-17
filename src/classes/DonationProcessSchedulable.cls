/**
* @description This class is used to start the donation processing to batches schedule 
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
public class DonationProcessSchedulable implements Schedulable 
{
    /* Constants */

    /* Enums & Structs */

    /* Public Members */

    public string ScheduleID 
    {
        get;
        set;
    }

    /* Private Members */

    private Nubik_ScheduleSettings m_ScheduleSettings = null;

    /* Properties */

    /* Apex API */

    /* Public API */

    public DonationProcessSchedulable()
    {
        if (m_ScheduleSettings == null)
        {
            SetSchedule();
        }   
    }

    

    /* Protected API */

    /* Private API */
    
    /**
    * @description Start the scheduled job
    */ 
    private void Start()
    {
        //this.execute(null);
        ScheduleID = System.schedule(m_ScheduleSettings.SCHEDULE_NAME, m_ScheduleSettings.CronHandler.GetCronExpression(), this);
    }

    /**
    * @description Set the schedule settings to allow the schedule to start
    */ 
    private void SetSchedule()
    {
        try
        {           
            m_ScheduleSettings = new Nubik_ScheduleSettings(Schedule_Settings__c.getValues('DonationProcessSchedule')); 
        }
        catch (Exception e)
        {
            throw e;
        }
        
        Start(); // If we have a schedule
    }

    /* Interface Implementation */

    /**
     * @description Executes the scheduled Apex job. 
     * @param sc contains the job ID
     */ 
    public void execute(SchedulableContext sc) 
    {
        /*Database.executeBatch(new DonationProcessBatchable(new DonationProcessOnlineBatch()));
        Database.executeBatch(new DonationProcessBatchable(new DonationProcessRecurringGiftBatch()));*/
        DonationBatchingC_P batchP= new DonationBatchingC_P();
        Database.executeBatch(batchP);
    }
}