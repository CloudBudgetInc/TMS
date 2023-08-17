/**
* @description Throw custom Cron exceptions
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
public class Nubik_CronException extends Exception 
{
	/**
	* @description Shows an error message
	* @param message The string message that will be shown
	*/ 
	public static void ErrorMessage(string message)
	{
		ExceptionMessage(message, System.LoggingLevel.ERROR);
	}

	/**
	* @description Shows a message based on the log level selected
	* @param message The string message that will be shown
	* @param logLevel The log level that is selected
	*/ 
	public static void ExceptionMessage(string message, System.LoggingLevel logLevel)
	{
		System.debug(logLevel, message);
	}
}