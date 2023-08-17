/**
* @description A helper class used to create SOQL filters
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
public class Nubik_FilterCriteria
{
	/* Constants */

	/* Enums & Structs */

	/* Public Members */
	public String FieldName;
	public String FieldValue;
	public String Operator;

	/* Private Members */

	/* Properties */

	/* Apex API */

	/* Public API */

	public Nubik_FilterCriteria(string fieldName, string fieldValue, string operator)
	{
		this.FieldName  = fieldName;
		this.FieldValue = fieldValue;
		this.Operator   = operator;
	}

	/**
	* @description Concatenates the field name with the operator and the field value
	* @return Returns the criteria
	*/ 
	public String GetFilter()
	{
		return FieldName + ' ' + Operator + ' ' + FieldValue;
	}

	/**
	* @description Checks if the field value is empty or null
	* @return Returns true if there is a field value
	*/ 
	public Boolean IsFieldValueNullOrEmpty()
	{
		return FieldValue != null && FieldValue != '';
	}

	/**
	* @description Creates the conditions of a WHERE clause joined by ANDs
	* @param criterias List of criteria to be added to the return string
	* @return Returns a filter string used for a WHERE clause
	*/ 
	public static String GetAndFilteredCriteria(List<Nubik_FilterCriteria> criterias) 
	{
		List<String> andConditions = new List<String>();

		for(Nubik_FilterCriteria criteria : criterias) 
		{
			if (criteria.IsFieldValueNullOrEmpty()) 
			{
				andConditions.add(criteria.GetFilter());
			}
		}

		return String.join(andConditions, ' AND ');
	}

	/* Protected API */

	/* Private API */

	/* Interface Implementation */

}