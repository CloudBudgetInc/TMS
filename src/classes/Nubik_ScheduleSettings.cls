/**
* @description Get custom schedule settings from the Schedule_Settings__c object.
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
public class Nubik_ScheduleSettings  
{
	/* Constants */
	public final string SCHEDULE_NAME;

	/* Enums & Structs */

	/* Public Members */
	public Nubik_CronHandler CronHandler = new Nubik_CronHandler();

	/* Private Members */

	/* Properties */

	/* Apex API */

	/* Public API */

	public Nubik_ScheduleSettings(Schedule_Settings__c scheduleSettings)
	{
		this.SCHEDULE_NAME = scheduleSettings.Schedule_Name__c;
		
		this.CronHandler.Seconds    = scheduleSettings.Seconds__c;
		this.CronHandler.Minutes    = scheduleSettings.Minutes__c;
		this.CronHandler.Hours      = scheduleSettings.Hours__c;
		this.CronHandler.DayOfMonth = scheduleSettings.Day_of_Month__c;
		this.CronHandler.Month      = scheduleSettings.Month__c;
		this.CronHandler.DayOfWeek  = scheduleSettings.Day_of_Week__c;
		this.CronHandler.Year       = scheduleSettings.Year__c;
	}

	/* Protected API */

	/* Private API */

	/* Interface Implementation */
}