/**
* @description Unit test class for Nubik_CronHandler
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
@isTest private class Nubik_CronHandler_Test 
{
	@isTest private static void Main() 
	{
		Nubik_CronHandler cronHandler = new Nubik_CronHandler();
		cronHandler.Seconds = '-1';
		cronHandler.Minutes = '60';
		cronHandler.Hours   = '24';
		
		System.assertEquals('0', cronHandler.Seconds);
		System.assertEquals('0', cronHandler.Minutes);
		System.assertEquals('0', cronHandler.Hours);

		cronHandler.Seconds    = '50';
		cronHandler.Minutes    = '1';
		cronHandler.Hours      = '0';
		cronHandler.DayOfMonth = '0';
		cronHandler.Month      = '0';
		cronHandler.DayOfWeek  = '0';
		cronHandler.Year       = '0';

		System.assertEquals('50', cronHandler.Seconds);
		System.assertEquals('1', cronHandler.Minutes);
		System.assertEquals('0', cronHandler.Hours);
		System.assertEquals('0', cronHandler.DayOfMonth);
		System.assertEquals('0', cronHandler.Month);
		System.assertEquals('0', cronHandler.DayOfWeek);
		System.assertEquals('0', cronHandler.Year);

		System.assertEquals('50 1 0 0 0 0 0', cronHandler.GetCronExpression());
	}
}