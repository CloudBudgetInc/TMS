/* **************************************************************************
 * Class: DonationsToJournalValidationBatchHelper
 * Created by Jordan Ojeda, 07/23/2018
 *
 * Purpose/Methods: Helper class for DonationsToJournalValidationBatch
 *
 * Unit Test: DonationsToJournalValidationBatchTest
 *
 * Modifications:
 * - {DevName}, {MM/DD/YYYY} : {Description of changes made post deployment to client}
 ************************************************************************** */
public class DonationsToJournalValidationBatchHelper
{

	/**
	 * @description this method builds and returns a string that contains all the 
	 *    filters that will be used in the query to retrieve the DonationsToJournalValidations.
	 * @author Jordan Ojeda, 07/23/2018
	 */
	private static string getDonationsToJournalValidationFilterToQuery(string batchIdsVarName)
	{
		string filter;

		////////// CUSTOM CODE HERE ////////////
		//Example:
		//by Name
		//DonationsToJournalValidation__c.Name.getDescribe().Name + '=' + '\'FilterValue\' AND '+...;
		filter = Opportunity.npsp__Batch__c.getDescribe().Name + ' IN : ' + batchIdsVarName + ' AND '+
		Opportunity.StageName.getDescribe().Name + ' != \'Declined\'';

		return filter;
	}



	/**
	 * @description this method builds and returns a list of strings with all the fields 
	 *    that need to be retrieved by the query to get the DonationsToJournalValidations.
	 * @author Jordan Ojeda, 07/23/2018
	 */
	private static List<string> getDonationsToJournalValidationFieldToQuery()
	{
		list<string> fields = new list<string>();

		////////// CUSTOM CODE HERE ////////////
		//Example:
		//Name
		//fields.add(DonationsToJournalValidation__c.Name.getDescribe().Name);

		fields.add(Opportunity.Name.getDescribe().Name);
		fields.add(Opportunity.npsp__Batch__c.getDescribe().Name);
		fields.add(Opportunity.Journal_Lines_To_Create__c.getDescribe().Name);
		fields.add(Opportunity.SObjectType.getDescribe().Name+'.'+Account.SObjectType.getDescribe().Name+'.'+Opportunity.Account.type.getDescribe().Name);
		fields.add(Opportunity.Create_Journal_Status__c.getDescribe().Name);

		return fields;
	}


	/**
	 * @description this method builds and returns a string to be used to 
	 *    retrieved Contacs based on a specified criteria.
	 * @author Jordan Ojeda, 07/23/2018
	 */
	public static string getDonationsToJournalValidationBatchQuery (string batchIdsVarName)
	{
		////////// CUSTOM CODE HERE ////////////
		string query;

		query = 
		'SELECT ' + 
		String.join(getDonationsToJournalValidationFieldToQuery(),',') +' '+
		'FROM ' + 
		Opportunity.SObjectType.getDescribe().Name +' '+
		'WHERE ' +
		getDonationsToJournalValidationFilterToQuery(batchIdsVarName);




		return query;
	}
}