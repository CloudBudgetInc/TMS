/**
* @description Create and validate a Cron expression
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
public class Nubik_CronHandler
{
	/* Constants */

	/* Enums & Structs */

	/* Public Members */

	/* Private Members */
	private string m_Seconds;
	private string m_Minutes;
	private string m_Hours;
	private string m_DayOfMonth;
	private string m_Month;
	private string m_DayOfWeek;
	private string m_Year;

	/* Properties */

	public string Seconds 
	{ 
		get
		{
			return m_Seconds;
		}

		set
		{
			if (StringInIntegerRange(0, 59, value))
			{
				m_Seconds = value;
			}
			else
			{
				m_Seconds = '0';

				InvalidCronError('Seconds', value, m_Seconds);
			}
		}
	}

	public string Minutes 
	{ 
		get
		{
			return m_Minutes;
		}

		set
		{
			if (StringInIntegerRange(0, 59, value))
			{
				m_Minutes = value;
			}
			else
			{
				m_Minutes = '0';

				InvalidCronError('Minutes', value, m_Minutes);
			}
		}
	}

	public string Hours 
	{ 
		get
		{
			return m_Hours;
		}

		set
		{
			if (StringInIntegerRange(0, 23, value))
			{
				m_Hours = value;
			}
			else
			{
				m_Hours = '0';

				InvalidCronError('Hours', value, m_Hours);
			}
		}
	}

	public string DayOfMonth 
	{ 
		get
		{
			return m_DayOfMonth;
		}

		set
		{
			m_DayOfMonth = value;
			
			// TODO: Validation
		}
	}

	public string Month 
	{ 
		get
		{
			return m_Month;
		}

		set
		{
			m_Month = value;
			
			// TODO: Validation
		}
	}

	public string DayOfWeek 
	{ 
		get
		{
			return m_DayOfWeek;
		}

		set
		{
			m_DayOfWeek = value;
			
			// TODO: Validation
		}
	}

	public string Year 
	{ 
		get
		{
			return m_Year;
		}

		set
		{
			m_Year = value;
			
			// TODO: Validation
		}
	}

	/* Apex API */

	/* Public API */

	public Nubik_CronHandler()
	{
	}

	/**
	* @description Creates a Cron expression based on the values given to the handler
	* @return Returns the Cron expression
	*/ 
	public string GetCronExpression()
	{
		return Seconds + ' ' + Minutes + ' ' + Hours + ' ' + DayOfMonth + ' ' + Month + ' ' + DayOfWeek + ' ' + Year;
	}

	/* Protected API */

	/* Private API */

	/**
	 * @description Checks to see if a string is in the range of integers
	 * @param min Minimum integer value (inclusive)
	 * @param max Maximum integer value (inclusive)
	 * @param elementValue String to check
	 * @return Returns true if the string is in the range
	 */ 
	private boolean StringInIntegerRange(Integer min, Integer max, string elementValue)
	{
		Integer result = null;

		try
		{	        
			result = Integer.valueOf(elementValue);
			
			// If the string value is within the range
			if (result >= min && result <= max)
			{
				return true;
			}
		}
		catch (Exception e)
		{
			throw e;
		}

		return false;
	}

	/**
	* @description 
	* @param elementName Name of the cron element that is invalid
	* @param invalidValue The invalid value
	* @param newValue  The new value being set in it's place
	*/ 
	private void InvalidCronError(String elementName, string invalidValue, string newValue)
	{
		Nubik_CronException.ErrorMessage(elementName + ' value of \'' + invalidValue + '\' is invalid. ' + elementName + ' value set to \'' + newValue + '\'.');
	}

	/* Interface Implementation */
}