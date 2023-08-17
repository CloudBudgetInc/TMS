/**
* @description This class is to only be used in the schedule UI in Salesforce. It's purpose is to be the schedules entry point.
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
public class DonationProcessSchedulableUI implements Schedulable 
{
	/* Constants */

	/* Enums & Structs */

	/* Public Members */

	/* Private Members */

	/* Properties */

	/* Apex API */

	/* Public API */

	public DonationProcessSchedulableUI()
	{
		DonationProcessSchedulable donationProcessSchedule = new DonationProcessSchedulable();
	}

	/* Protected API */

	/* Private API */

	/* Interface Implementation */

	/**
	 * @description Executes the scheduled Apex job. 
	 * @param sc contains the job ID
	 */ 
	public void execute(SchedulableContext sc) 
	{
	}
}