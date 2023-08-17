/**
* @description Assign Opportunities to Batches depending on their donation process type. Send status email once batch is complete.
*
* @author mlibman
* @editors  
*
* @copyright Nubik, 2018
*/
global class DonationProcessBatchable implements Database.Batchable<SObject>, Database.Stateful
{
	/* Constants */

	/* Enums & Structs */

	/* Public Members */

	/* Private Members */
	private DonationProcessBatchBase m_DonationProcessBatch; // Holds the type of the donation process

	private List<npsp__Batch__c> m_Batches = new List<npsp__Batch__c>(); // Holds all batches

	private List<Opportunity> m_Opportunities = new List<Opportunity>(); // Holds all opportunities

	private Database.SaveResult[] m_SaveBatchResults;
	private Database.SaveResult[] m_SaveOpportunityResults;

	private integer batchSequence;

	/* Properties */

	// Used to get the System Administrator Id
	private Profile SystemAdministrator
	{
		get
		{
			if (SystemAdministrator == null)
			{
				SystemAdministrator = 
				[
                    SELECT 
						Id
					FROM Profile
                    WHERE Name = 'System Administrator'
                    LIMIT 1
                ];
			}

			return SystemAdministrator;
		}

		set;
	}

	// Used to get the Donation Process Settings by the System Administrator
	private Donation_Process_Settings__c SystemAdministratorDonationProcessSettings
	{
		get
		{
			if (SystemAdministratorDonationProcessSettings == null)
			{
				String SystemAdministratorId = SystemAdministrator.Id; // Made Id a string to split from 18 digits, to 15

				SystemAdministratorDonationProcessSettings = 
				[
					SELECT
						Batch_Interval__c
					FROM Donation_Process_Settings__c
					WHERE IsDeleted = false AND SetupOwnerId = :SystemAdministratorId.substring(0, 15)
					LIMIT 1
				];
			}
			
			return SystemAdministratorDonationProcessSettings;
		}

		set;
	}

	/* Apex API */

	/* Public API */

	public DonationProcessBatchable(DonationProcessBatchBase typeOfProcessDonationBatch) 
	{
		batchSequence=0;
		this.m_DonationProcessBatch = typeOfProcessDonationBatch;
		
	}

	/* Protected API */

	/* Private API */

	/**
	* @description Create a list of Batches
	* @param batchesNeeded The number of batche that will be created
	* @return Return the list of Batches
	*/ 
	private List<npsp__Batch__c> CreateBatches(Integer batchesNeeded)
	{
		List<npsp__Batch__c> batches = new List<npsp__Batch__c>();

		for (Integer i = 0; i < batchesNeeded; i++)
		{
			batchSequence++;
			batches.add(CreateBatch(batchSequence));
		}

		return batches;
	}

	/**
	* @description Create a single Batch
	* @param batchNumber The current batch number for the day
	* @return Returns the Batch
	*/ 
	private npsp__Batch__c CreateBatch(Integer batchNumber)
	{
		System.debug('Batch Number: ' + batchNumber);

		String currentDate = String.valueOf(Datetime.now().format('YYMMdd')); // Build date
		String numberValue = String.valueOf(batchNumber);                     // Set the batch number

		// Create batch

		npsp__Batch__c batch = new npsp__Batch__c();
		batch.Name = m_DonationProcessBatch.BATCH_NAME_PREFIX + '-' + currentDate + '-' + numberValue.leftPad(4, '0'); // Example O-YYMMDD-0001
		batch.npsp__Object_Name__c = 'Opportunity';
		batch.Type__c = m_DonationProcessBatch.BATCH_TYPE;

		return batch;
	}

	/**
	* @description Build and format the email status report as an HTML email
	* @return Return the formated HTML status report
	*/ 
	private String StatusReport()
	{
		String statusReport = '<h1>' + m_DonationProcessBatch.PROCESS_NAME + ' Status Report (' + Date.today().month() + '-' + Date.today().day() + '-' + Date.today().year() + ')</h1>';

		// Rip through the batches
		for (Integer i = 0; i < m_SaveBatchResults.size(); i++)
		{
			// If we have a successful batch
			if (m_SaveBatchResults[i].isSuccess())
			{
				statusReport += '<h2>Batch <a href="' + Url.getSalesforceBaseUrl().toExternalForm() + '/' + m_SaveBatchResults[i].getId() + '">' + m_Batches[i].Name + '</a> <span style="color: green">(Success)</span></h2>';
			}
			else
			{
				statusReport += '<h2>Batch ' + m_Batches[i].Name + '</a> <span style="color: red">(Fail)</span></h2> - ' + m_SaveBatchResults[i].getErrors() + '<br/>';
			}

			statusReport += '<h3>Opportunities</h3>';

			// Rip through the opportunities 
			for (Integer j = 0; j < m_SaveOpportunityResults.size(); j++)
			{
				// If we have a successful opportunity
				if (m_SaveOpportunityResults[i].isSuccess())
				{
					// If our batch id doesn't match, skip
					if (m_Opportunities[j].npsp__Batch__c != m_Batches[i].Id)
					{
						continue;
					}

					statusReport += '<a href="' + Url.getSalesforceBaseUrl().toExternalForm() + '/' + m_SaveOpportunityResults[j].getId() + '">' + m_Opportunities[j].Name + '</a> was <span style="color: green">successfully</span> assigned<br/>';
				}
				else
				{
					// If our batch id doesn't match, skip
					if (m_Opportunities[j].npsp__Batch__c != m_Batches[i].Id)
					{
						continue;
					}

					statusReport += '<a href="' + Url.getSalesforceBaseUrl().toExternalForm() + '/' + m_Opportunities[j].Id + '">' + m_Opportunities[j].Name + '</a> has <span style="color: red">failed</span> to be assigned - ' + m_SaveOpportunityResults[j].getErrors() + '<br/>';
				}
			
				statusReport += '<br/>';
			}

			statusReport += '<br/>';
		}
		
		return statusReport;
	}

	/* Interface Implementation */

	/**
	 * @description gets invoked when the batch job starts
	 * @param context contains the job ID
	 * @returns the record set as a QueryLocator object that will be batched for execution
	 */ 
	global Database.QueryLocator start(Database.BatchableContext context) 
	{
		String whereClause = ' WHERE ' + m_DonationProcessBatch.GetAndFilteredCriteria();
		System.debug('whereClause: ' + whereClause);
		return Database.getQueryLocator('SELECT npsp__Batch__c, Id, Name FROM Opportunity' + whereClause);
	}

	/**
	 * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
	 * @param context contains the job ID
	 * @param scope contains the batch of records to process.
	 */ 
   	global void execute(Database.BatchableContext context, List<Opportunity> scope) 
	{
		System.debug('Opportunity Size: ' + scope.size());

		// If we don't have any Opportunities, quit
		if (scope.size() <= 0)
		{
			return;
		}
		
		System.debug('Opportunity Scope: ' + scope);

		Integer newBatchInterval = (Integer) SystemAdministratorDonationProcessSettings.Batch_Interval__c; // Get the batch interval from the custom setting
		Integer numberOfBatchesNeeded = (Integer) Math.ceil((Double) scope.size() / newBatchInterval);     // Decide how many batches are needed

		System.debug('Batch Interval: ' + newBatchInterval);

		m_Batches = CreateBatches(numberOfBatchesNeeded); // Create batches

		// If we don't have any Batches, quit
		if (m_Batches.size() <= 0)
		{
			return;
		}

		m_SaveBatchResults = Database.insert(m_Batches, false); // Insert Batches

		Integer currentBatchIndex = -1;
		for (Integer i = 0; i < scope.size(); i++)
		{
			// If we're at the interval limit, make a new batch
			if (Math.mod(i, newBatchInterval) == 0)
			{
				currentBatchIndex++; // Previous batch is full, next batch
			}

			scope.get(i).npsp__Batch__c = m_Batches.get(currentBatchIndex).Id; // Assign Opportunity to Batch

			System.debug('#' + i + ': ' + scope.get(i));
		}

		m_Opportunities = scope; // Save the scope

		m_SaveOpportunityResults = Database.update(m_Opportunities, false); // Insert Opportunities
	}
	
	/**
	 * @description gets invoked when the batch job finishes. Place any clean up code in this method.
	 * @param context contains the job ID
	 */ 
	global void finish(Database.BatchableContext context) 
	{
		// If there are no batches or opportunities, quit
		if (m_SaveBatchResults == null || m_SaveOpportunityResults == null)
		{
			return;
		}

		Email_Settings__c emailSettings = Email_Settings__c.getValues('Donation Process Batch');

		// Prepare email for send
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(new String[] { emailSettings.To_Address__c });
		mail.setReplyTo(emailSettings.Reply_To_Address__c);
		mail.setSenderDisplayName(emailSettings.Sender_Display_Name__c);
		mail.setSubject(emailSettings.Subject__c + ' ' + m_DonationProcessBatch.PROCESS_NAME);
		mail.setHtmlBody(StatusReport());

		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); // Send email
	}
}